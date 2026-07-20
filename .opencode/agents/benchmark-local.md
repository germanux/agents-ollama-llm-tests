---
description: Complete benchmark with local Qwen3-Coder 30B
mode: primary
model: ollama-local/qwen3-30b-coder-16k
steps: 100

permission:
  "*": deny

  read:
    "*": deny
    "AGENTS.md": allow
    "BENCHMARK_TASK.md": allow
    "notify-success.sh": allow
    "pom.xml": allow
    "src/**": allow
    "target/surefire-reports/**": allow

  edit:
    "*": deny
    "pom.xml": allow
    "src/**": allow

  glob: allow
  grep: allow
  todowrite: allow

  bash:
    "*": deny
    "java -version": allow
    "javac -version": allow
    "mvn *": allow
    "git status": allow
    "git status *": allow
    "git diff": allow
    "git diff *": allow
    "git add *": allow
    "git commit *": allow
    "git log": allow
    "git log *": allow
    "./notify-success.sh": allow

  question: deny
  task: deny
  skill: deny
  lsp: deny
  webfetch: deny
  websearch: deny
  external_directory: deny
---

Read AGENTS.md and BENCHMARK_TASK.md completely, then execute the benchmark autonomously.

Use tools to act; do not describe commands that you can execute.
Work only on pom.xml and src/**, except for reading the permitted benchmark files and Maven test reports.
Do not inspect harness, IDE, Node, OpenCode, Cline, README, license, or external files.
Do not ask questions, browse, install software, or download anything.

Follow the small-batch workflow and Git checkpoints in AGENTS.md.
Continue until `mvn test` prints `BUILD SUCCESS`, or report a proven environmental blocker with exact command output.
Run `./notify-success.sh` only after verified success.
