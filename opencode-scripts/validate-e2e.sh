#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Deterministic acceptance harness for the Spring Boot + Angular benchmark.
# Usage:
#   ./validate-e2e.sh
#   ./validate-e2e.sh --notify
#
# Optional environment variables:
#   BASE_URL=http://127.0.0.1:8080
#   PORT=8080
#   JAVA21_HOME=/usr/lib/jvm/java-21-openjdk-amd64
#   STARTUP_TIMEOUT=45
#   CURL_TIMEOUT=15
#   REQUIRE_HEADLESS_BROWSER=0

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$ROOT_DIR"

BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"
PORT="${PORT:-8080}"
STARTUP_TIMEOUT="${STARTUP_TIMEOUT:-45}"
CURL_TIMEOUT="${CURL_TIMEOUT:-15}"
REQUIRE_HEADLESS_BROWSER="${REQUIRE_HEADLESS_BROWSER:-0}"
JAVA21_HOME="${JAVA21_HOME:-/usr/lib/jvm/java-21-openjdk-amd64}"
ARTIFACT_DIR="${ARTIFACT_DIR:-target/e2e-validation}"
NOTIFY=0
APP_PID=""
JAR_FILE=""

case "${1:-}" in
  "") ;;
  --notify) NOTIFY=1 ;;
  *) echo "Usage: $0 [--notify]" >&2; exit 64 ;;
esac

mkdir -p "$ARTIFACT_DIR"
rm -f "$ARTIFACT_DIR"/*
SERVER_LOG="$ARTIFACT_DIR/server.log"
RESULTS_FILE="$ARTIFACT_DIR/http-results.tsv"
INDEX_FILE="$ARTIFACT_DIR/index.html"
ASSET_LIST="$ARTIFACT_DIR/assets.tsv"
SUMMARY_FILE="$ARTIFACT_DIR/summary.txt"

printf 'name\tmethod\turl\tstatus\tcontent_type\tbody_bytes\n' > "$RESULTS_FILE"

log()  { printf '\n==> %s\n' "$*"; }
pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

show_failure_context() {
  local rc=$?
  local line=${1:-unknown}
  local command=${2:-unknown}
  printf '\nFAIL: command exited with status %s at line %s\n' "$rc" "$line" >&2
  printf 'Command: %s\n' "$command" >&2
  if [[ -s "$SERVER_LOG" ]]; then
    printf '\n--- Last 100 server log lines ---\n' >&2
    tail -n 100 "$SERVER_LOG" >&2 || true
  fi
  exit "$rc"
}

cleanup() {
  local rc=$?
  trap - EXIT INT TERM ERR
  if [[ -n "$APP_PID" ]] && kill -0 "$APP_PID" 2>/dev/null; then
    printf '\nStopping benchmark server PID %s\n' "$APP_PID"
    kill "$APP_PID" 2>/dev/null || true
    for _ in {1..20}; do
      kill -0 "$APP_PID" 2>/dev/null || break
      sleep 0.25
    done
    if kill -0 "$APP_PID" 2>/dev/null; then
      kill -KILL "$APP_PID" 2>/dev/null || true
    fi
    wait "$APP_PID" 2>/dev/null || true
  fi
  exit "$rc"
}

trap 'show_failure_context "$LINENO" "$BASH_COMMAND"' ERR
trap cleanup EXIT INT TERM

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

java_major() {
  "$1" -version 2>&1 | awk -F'[".]' '/version/ { if ($2 == "1") print $3; else print $2; exit }'
}

content_type_from_headers() {
  awk -F': *' 'tolower($1)=="content-type" {value=tolower($2)} END {gsub(/\r/, "", value); print value}' "$1"
}

record_http() {
  local name=$1 method=$2 url=$3 status=$4 content_type=$5 bytes=$6
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$name" "$method" "$url" "$status" "$content_type" "$bytes" >> "$RESULTS_FILE"
}

assert_json_content_type() {
  local content_type=$1 name=$2
  [[ "$content_type" == application/json* || "$content_type" == application/problem+json* ]] \
    || fail "$name returned unexpected Content-Type: ${content_type:-<missing>}"
}

http_success() {
  local name=$1 method=$2 url=$3 body_file=$4
  local data=${5:-}
  local headers_file="$ARTIFACT_DIR/${name}.headers"
  local status content_type bytes
  local -a args=(
    --silent --show-error --fail --max-redirs 0
    --connect-timeout 3 --max-time "$CURL_TIMEOUT"
    --request "$method" --dump-header "$headers_file"
    --output "$body_file" --write-out '%{http_code}'
  )
  if [[ -n "$data" ]]; then
    args+=(--header 'Content-Type: application/json' --data "$data")
  fi
  status="$(curl "${args[@]}" "$url")"
  [[ "$status" =~ ^2[0-9][0-9]$ ]] || fail "$name returned HTTP $status"
  [[ -s "$body_file" ]] || fail "$name returned an empty response body"
  content_type="$(content_type_from_headers "$headers_file")"
  bytes="$(wc -c < "$body_file" | tr -d ' ')"
  record_http "$name" "$method" "$url" "$status" "$content_type" "$bytes"
  printf '%s' "$content_type"
}

http_expect() {
  local name=$1 method=$2 url=$3 expected=$4 body_file=$5
  local data=${6:-}
  local headers_file="$ARTIFACT_DIR/${name}.headers"
  local status content_type bytes
  local -a args=(
    --silent --show-error --max-redirs 0
    --connect-timeout 3 --max-time "$CURL_TIMEOUT"
    --request "$method" --dump-header "$headers_file"
    --output "$body_file" --write-out '%{http_code}'
  )
  if [[ -n "$data" ]]; then
    args+=(--header 'Content-Type: application/json' --data "$data")
  fi
  status="$(curl "${args[@]}" "$url")"
  [[ "$status" == "$expected" ]] || fail "$name expected HTTP $expected but received $status"
  [[ -s "$body_file" ]] || fail "$name returned an empty response body"
  content_type="$(content_type_from_headers "$headers_file")"
  bytes="$(wc -c < "$body_file" | tr -d ' ')"
  record_http "$name" "$method" "$url" "$status" "$content_type" "$bytes"
  printf '%s' "$content_type"
}

json_id() {
  python3 - "$1" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
if not isinstance(data, dict) or not isinstance(data.get("id"), int):
    raise SystemExit("Response does not contain an integer id")
print(data["id"])
PY
}

json_list_length() {
  python3 - "$1" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
if not isinstance(data, list):
    raise SystemExit("Expected a JSON array")
print(len(data))
PY
}

pids_on_port() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -t -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true
  elif command -v fuser >/dev/null 2>&1; then
    fuser -n tcp "$PORT" 2>/dev/null | tr ' ' '\n' | sed '/^$/d' || true
  else
    return 0
  fi
}

is_our_stale_process() {
  local pid=$1
  local cwd cmdline
  [[ -r "/proc/$pid/cmdline" ]] || return 1
  cwd="$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)"
  cmdline="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)"
  [[ "$cwd" == "$ROOT_DIR" && "$cmdline" == *"$(basename "$JAR_FILE")"* ]]
}

log "Preflight and fixed toolchain"
for cmd in curl git npm mvn node python3; do require_command "$cmd"; done

JAVA_BIN="${JAVA_BIN:-java}"
if [[ "$(java_major "$JAVA_BIN")" != "21" && -x "$JAVA21_HOME/bin/java" ]]; then
  export JAVA_HOME="$JAVA21_HOME"
  export PATH="$JAVA_HOME/bin:$PATH"
  JAVA_BIN="$JAVA_HOME/bin/java"
fi
[[ "$(java_major "$JAVA_BIN")" == "21" ]] \
  || fail "Java 21 is required. Current runtime: $($JAVA_BIN -version 2>&1 | head -n 1)"
[[ "$(javac -version 2>&1 | awk '{print $2}' | cut -d. -f1)" == "21" ]] \
  || fail "javac 21 is required. Current compiler: $(javac -version 2>&1)"
mvn -version | grep -q 'Java version: 21' \
  || fail "Maven is not running on Java 21"
[[ "$(node --version | sed 's/^v//' | cut -d. -f1)" == "20" ]] \
  || fail "Node.js 20.x is required. Current version: $(node --version)"
pass "Java 21, Maven on Java 21 and Node.js 20 are active"

log "Static benchmark requirements"
[[ -d frontend ]] || fail "frontend/ is missing"
grep -RqsE '\[formGroup\]|formControlName' frontend/src \
  || fail "Angular frontend does not demonstrate Reactive Forms usage"
grep -Rqs 'HttpClient' frontend/src \
  || fail "Angular frontend does not use HttpClient"
grep -Rqs '/api/' frontend/src \
  || fail "Angular frontend does not use relative /api URLs"
grep -Rqs 'book-titles' frontend/src \
  || fail "Angular frontend does not reference the author book-titles endpoint"
if grep -RqsE 'import[[:space:]]+lombok|<groupId>org\.projectlombok</groupId>' src pom.xml; then
  fail "Lombok is forbidden by the benchmark"
fi
if grep -Rqs 'FetchType.EAGER' src/main/java; then
  fail "FetchType.EAGER violates the benchmark's lazy-association requirement"
fi
python3 - <<'PY'
from pathlib import Path
text = "\n".join(p.read_text(errors="ignore") for p in Path("src/test").rglob("*.java"))
patterns = ('get("/")', "get('/')")
if not any(p in text for p in patterns):
    raise SystemExit("No backend integration test for GET / was found")
PY
pass "Minimum structural requirements are present"

log "Angular production build"
npm --prefix frontend run build
pass "Angular build succeeded"

log "Complete Maven test and package build"
mvn clean package
pass "Maven package succeeded with tests enabled"

mapfile -t jar_candidates < <(find target -maxdepth 1 -type f -name '*.jar' ! -name '*.original' -print | sort)
[[ ${#jar_candidates[@]} -eq 1 ]] \
  || fail "Expected exactly one runnable JAR in target/, found ${#jar_candidates[@]}"
JAR_FILE="$(readlink -f "${jar_candidates[0]}")"
[[ -s "$JAR_FILE" ]] || fail "Packaged JAR is missing or empty"
pass "Runnable JAR selected: $JAR_FILE"

log "Git integrity before runtime acceptance"
git diff --check
[[ -z "$(git status --short)" ]] \
  || fail "Working tree is not clean after build; commit required generated or source changes"
pass "Git diff is valid and working tree is clean"

log "Stale server detection"
mapfile -t occupied_pids < <(pids_on_port)
for pid in "${occupied_pids[@]}"; do
  [[ "$pid" =~ ^[0-9]+$ ]] || continue
  if is_our_stale_process "$pid"; then
    echo "Stopping stale benchmark PID $pid on port $PORT"
    kill "$pid"
    for _ in {1..20}; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.25
    done
    kill -0 "$pid" 2>/dev/null && fail "Stale benchmark PID $pid did not stop"
  else
    cmdline="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || echo unknown)"
    fail "Port $PORT is occupied by a non-benchmark process: PID $pid ($cmdline)"
  fi
done
pass "Port $PORT is available"

log "Start packaged JAR and capture exact PID"
"$JAVA_BIN" -jar "$JAR_FILE" --server.port="$PORT" >"$SERVER_LOG" 2>&1 &
APP_PID=$!
printf '%s\n' "$APP_PID" > "$ARTIFACT_DIR/server.pid"
kill -0 "$APP_PID" 2>/dev/null || fail "Server process exited immediately"
pass "Server started as PID $APP_PID"

log "HTTP readiness"
ready=0
for ((second=1; second<=STARTUP_TIMEOUT; second++)); do
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    fail "Server process died during startup"
  fi
  if curl --silent --show-error --fail --max-redirs 0 \
      --connect-timeout 1 --max-time 2 \
      "$BASE_URL/api/authors" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
[[ "$ready" == "1" ]] || fail "HTTP readiness did not succeed within ${STARTUP_TIMEOUT}s"
pass "Server is ready at $BASE_URL"

log "REST acceptance workflow"
AUTHOR_ONE_JSON='{"firstName":"Ada","lastName":"Lovelace","age":36}'
AUTHOR_TWO_JSON='{"firstName":"Grace","lastName":"Hopper","age":85}'
INVALID_AUTHOR_JSON='{"firstName":"","lastName":"","age":-1}'
BOOK_TITLE='Deterministic Systems'
BOOK_DESCRIPTION='Runtime acceptance fixture'
MISSING_AUTHOR_ID=999999999

ct="$(http_success author-create-1 POST "$BASE_URL/api/authors" "$ARTIFACT_DIR/author-create-1.json" "$AUTHOR_ONE_JSON")"
assert_json_content_type "$ct" "POST /api/authors"
AUTHOR_ONE_ID="$(json_id "$ARTIFACT_DIR/author-create-1.json")"

ct="$(http_success author-create-2 POST "$BASE_URL/api/authors" "$ARTIFACT_DIR/author-create-2.json" "$AUTHOR_TWO_JSON")"
assert_json_content_type "$ct" "POST /api/authors"
AUTHOR_TWO_ID="$(json_id "$ARTIFACT_DIR/author-create-2.json")"

ct="$(http_expect author-invalid POST "$BASE_URL/api/authors" 400 "$ARTIFACT_DIR/author-invalid.json" "$INVALID_AUTHOR_JSON")"
assert_json_content_type "$ct" "Invalid POST /api/authors"

ct="$(http_success authors-list GET "$BASE_URL/api/authors" "$ARTIFACT_DIR/authors-list.json")"
assert_json_content_type "$ct" "GET /api/authors"
python3 - "$ARTIFACT_DIR/authors-list.json" "$AUTHOR_ONE_ID" "$AUTHOR_TWO_ID" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    rows = json.load(f)
ids = {row.get("id") for row in rows if isinstance(row, dict)}
expected = {int(sys.argv[2]), int(sys.argv[3])}
if not expected <= ids:
    raise SystemExit(f"Author listing does not contain created IDs: expected {expected}, got {ids}")
PY

ct="$(http_success books-before GET "$BASE_URL/api/books" "$ARTIFACT_DIR/books-before.json")"
assert_json_content_type "$ct" "GET /api/books"
BOOKS_BEFORE="$(json_list_length "$ARTIFACT_DIR/books-before.json")"

BOOK_JSON="$(printf '{"title":"%s","description":"%s","authorIds":[%s,%s]}' \
  "$BOOK_TITLE" "$BOOK_DESCRIPTION" "$AUTHOR_ONE_ID" "$AUTHOR_TWO_ID")"
ct="$(http_success book-create POST "$BASE_URL/api/books" "$ARTIFACT_DIR/book-create.json" "$BOOK_JSON")"
assert_json_content_type "$ct" "POST /api/books"
BOOK_ID="$(json_id "$ARTIFACT_DIR/book-create.json")"

ct="$(http_success books-list GET "$BASE_URL/api/books" "$ARTIFACT_DIR/books-list.json")"
assert_json_content_type "$ct" "GET /api/books"
python3 - "$ARTIFACT_DIR/books-list.json" "$BOOK_ID" "$BOOK_TITLE" "$AUTHOR_ONE_ID" "$AUTHOR_TWO_ID" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    rows = json.load(f)
book_id, title = int(sys.argv[2]), sys.argv[3]
author_ids = {int(sys.argv[4]), int(sys.argv[5])}
match = next((row for row in rows if isinstance(row, dict) and row.get("id") == book_id), None)
if match is None or match.get("title") != title:
    raise SystemExit("Created book is missing from GET /api/books")
authors = match.get("authors")
if not isinstance(authors, list):
    raise SystemExit("Book response does not contain an authors array")
returned_ids = {a.get("id") for a in authors if isinstance(a, dict)}
if returned_ids != author_ids:
    raise SystemExit(f"Book authors mismatch: expected {author_ids}, got {returned_ids}")
PY

ct="$(http_success author-titles GET "$BASE_URL/api/authors/$AUTHOR_ONE_ID/book-titles" "$ARTIFACT_DIR/author-titles.json")"
assert_json_content_type "$ct" "GET /api/authors/{id}/book-titles"
python3 - "$ARTIFACT_DIR/author-titles.json" "$BOOK_TITLE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    titles = json.load(f)
if titles != [sys.argv[2]]:
    raise SystemExit(f"Expected exact title list {[sys.argv[2]]}, got {titles}")
PY

ct="$(http_expect missing-author-titles GET "$BASE_URL/api/authors/$MISSING_AUTHOR_ID/book-titles" 404 "$ARTIFACT_DIR/missing-author-titles.json")"
assert_json_content_type "$ct" "Missing author title lookup"

MISSING_BOOK_JSON="$(printf '{"title":"Should Not Persist","description":"Missing author fixture","authorIds":[%s]}' "$MISSING_AUTHOR_ID")"
ct="$(http_expect missing-author-book POST "$BASE_URL/api/books" 404 "$ARTIFACT_DIR/missing-author-book.json" "$MISSING_BOOK_JSON")"
assert_json_content_type "$ct" "Book creation with missing author"

ct="$(http_success books-after-missing GET "$BASE_URL/api/books" "$ARTIFACT_DIR/books-after-missing.json")"
assert_json_content_type "$ct" "GET /api/books after rejected creation"
BOOKS_AFTER_MISSING="$(json_list_length "$ARTIFACT_DIR/books-after-missing.json")"
[[ "$BOOKS_AFTER_MISSING" -eq $((BOOKS_BEFORE + 1)) ]] \
  || fail "Rejected book creation persisted partial data: before=$BOOKS_BEFORE after=$BOOKS_AFTER_MISSING"
pass "All required REST success and failure scenarios passed"

log "HTML acceptance at /"
ct="$(http_success frontend-index GET "$BASE_URL/" "$INDEX_FILE")"
[[ "$ct" == text/html* ]] || fail "GET / returned unexpected Content-Type: ${ct:-<missing>}"
python3 - "$INDEX_FILE" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace").lower()
if "<html" not in text or "<script" not in text:
    raise SystemExit("GET / did not return a plausible Angular index document")
PY
pass "Frontend index returned HTTP 2xx with HTML"

log "Extract exact browser asset URLs"
python3 - "$INDEX_FILE" "$BASE_URL/" > "$ASSET_LIST" <<'PY'
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse
import sys

class Parser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.base = None
        self.assets = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "base" and attrs.get("href"):
            self.base = attrs["href"]
        elif tag == "script" and attrs.get("src"):
            self.assets.append((attrs["src"], "js"))
        elif tag == "link" and "stylesheet" in attrs.get("rel", "").lower() and attrs.get("href"):
            self.assets.append((attrs["href"], "css"))

html_path, page_url = sys.argv[1], sys.argv[2]
parser = Parser()
with open(html_path, encoding="utf-8", errors="replace") as f:
    parser.feed(f.read())
base_url = urljoin(page_url, parser.base or "")
page_origin = urlparse(page_url)
seen = set()
for ref, kind in parser.assets:
    if ref.startswith(("data:", "javascript:")):
        continue
    url = urljoin(base_url, ref)
    parsed = urlparse(url)
    if (parsed.scheme, parsed.netloc) != (page_origin.scheme, page_origin.netloc):
        continue
    item = (url, kind)
    if item not in seen:
        seen.add(item)
        print(f"{kind}\t{url}")
PY

[[ -s "$ASSET_LIST" ]] || fail "No local JavaScript or stylesheet assets were found in index.html"
grep -q $'^js\t' "$ASSET_LIST" || fail "No local JavaScript asset was found in index.html"
grep -q $'^css\t' "$ASSET_LIST" || fail "No local stylesheet asset was found in index.html"
cat "$ASSET_LIST"

log "Request every JavaScript and CSS asset using its exact browser URL"
asset_number=0
while IFS=$'\t' read -r kind url; do
  asset_number=$((asset_number + 1))
  body="$ARTIFACT_DIR/asset-${asset_number}.${kind}"
  ct="$(http_success "asset-${asset_number}" GET "$url" "$body")"
  case "$kind" in
    js)
      [[ "$ct" == *javascript* || "$ct" == *ecmascript* ]] \
        || fail "$url returned invalid JavaScript Content-Type: ${ct:-<missing>}"
      python3 - "$body" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="ignore").lstrip().lower()
if text.startswith("<!doctype html") or text.startswith("<html"):
    raise SystemExit("JavaScript URL returned HTML")
PY
      ;;
    css)
      [[ "$ct" == text/css* ]] \
        || fail "$url returned invalid CSS Content-Type: ${ct:-<missing>}"
      ;;
    *) fail "Unknown asset kind: $kind" ;;
  esac
  pass "$kind asset: $url"
done < "$ASSET_LIST"

if [[ "$REQUIRE_HEADLESS_BROWSER" == "1" ]]; then
  log "Headless browser smoke test"
  BROWSER_BIN=""
  for candidate in chromium chromium-browser google-chrome google-chrome-stable; do
    if command -v "$candidate" >/dev/null 2>&1; then BROWSER_BIN="$candidate"; break; fi
  done
  [[ -n "$BROWSER_BIN" ]] || fail "REQUIRE_HEADLESS_BROWSER=1 but no Chromium/Chrome executable is installed"
  "$BROWSER_BIN" --headless --no-sandbox --disable-gpu \
    --virtual-time-budget=5000 --dump-dom "$BASE_URL/" \
    > "$ARTIFACT_DIR/rendered-dom.html" 2> "$ARTIFACT_DIR/browser.log"
  [[ -s "$ARTIFACT_DIR/rendered-dom.html" ]] || fail "Headless browser returned an empty DOM"
  if grep -qiE 'ERR_CONNECTION|404 Not Found|Whitelabel Error Page' "$ARTIFACT_DIR/rendered-dom.html"; then
    fail "Headless browser rendered an error page"
  fi
  pass "Headless browser loaded and rendered the application"
fi

log "Final Git and process checks"
git diff --check
[[ -z "$(git status --short)" ]] || fail "Working tree became dirty during acceptance validation"
kill -0 "$APP_PID" 2>/dev/null || fail "Server died before validation completed"

{
  echo "E2E VALIDATION PASSED"
  echo "git_head=$(git rev-parse HEAD)"
  echo "jar=$JAR_FILE"
  echo "server_pid=$APP_PID"
  echo "base_url=$BASE_URL"
  echo "http_checks=$(( $(wc -l < "$RESULTS_FILE") - 1 ))"
  echo "assets=$(wc -l < "$ASSET_LIST" | tr -d ' ')"
  echo "headless_browser=$REQUIRE_HEADLESS_BROWSER"
} | tee "$SUMMARY_FILE"

if [[ "$NOTIFY" == "1" ]]; then
  [[ -x ./notify-success.sh ]] || fail "notify-success.sh is missing or not executable"
  log "All acceptance gates passed; sending success notification"
  ./notify-success.sh
fi

pass "Deterministic full-stack acceptance completed"
