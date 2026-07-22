# FULL-STACK AGENTIC CODING BENCHMARK

## Objective

Build and validate a complete Spring Boot and Angular application in three ordered phases:

1. persistence and service layer;
2. REST backend;
3. Angular frontend and Spring Boot integration.

The phase specifications are authoritative:

- `BENCHMARK_BACKEND_DB.md`
- `BENCHMARK_BACKEND_REST.md`
- `BENCHMARK_ANGULAR.md`

Complete each phase, validate it, and create its milestone commit before starting the next phase. Preserve all previously working behavior and tests.

## Mandatory preflight

Before creating or modifying project files, run:

```bash
java -version
javac -version
mvn -version
node --version
npm --version
git status --short
test -x node_modules/.bin/ng
```

Proceed only when all of the following are confirmed:

- Java 21;
- `javac` 21;
- Maven running on Java 21;
- Node and npm are available;
- the repository-provisioned Angular CLI exists at `node_modules/.bin/ng`;
- no unrelated working-tree changes would be overwritten.

Do not install or download missing runtimes, binaries, Node packages, or system software. Maven may resolve dependencies declared in `pom.xml`. If a mandatory tool is unavailable, report the exact command and output as an environmental blocker.

## Execution order

### Phase 1 — Persistence

Re-read `AGENTS.md`, then read and execute `BENCHMARK_BACKEND_DB.md` completely.

Gate before Phase 2:

- all persistence requirements implemented;
- complete Maven test suite reports `BUILD SUCCESS`;
- persistence milestone committed.

### Phase 2 — REST backend

Re-read `AGENTS.md`, then read and execute `BENCHMARK_BACKEND_REST.md` completely.

Gate before Phase 3:

- all persistence and REST tests pass together;
- complete Maven test suite reports `BUILD SUCCESS`;
- REST milestone committed.

### Phase 3 — Angular frontend

Re-read `AGENTS.md`, then read and execute `BENCHMARK_ANGULAR.md` completely.

## Final validation

After all phases are implemented, run the real commands without hiding their exit status:

```bash
npm --prefix frontend run build
mvn clean package
git diff --check
git status --short
```

Success requires:

- Angular production build succeeds;
- complete Maven build and all backend tests succeed;
- the packaged Spring Boot application contains and serves the Angular frontend;
- all phase requirements remain satisfied;
- final Angular milestone is committed;
- `git status --short` is clean after final validation.

Only after all of the above succeeds, run:

```bash
./notify-success.sh
```

Do not notify after an intermediate phase.
