---
description: Complete benchmark with remote Qwen3-Coder-Next 80B
mode: primary
model: ollama-pc/qwen3-coder-next-direct
steps: 120
temperature: 0.2

permission:
  "*": deny

  read:
    "*": deny
    "AGENTS.md": allow
    "BENCHMARK_TASK.md": allow
    "BENCHMARK_ANGULAR.md": allow
    "BENCHMARK_BACKEND_REST.md": allow    
    "notify-success.sh": allow
    "pom.xml": allow
    "src/**": allow
    "target/surefire-reports/**": allow
    "frontend/**": allow
    "package.json": allow
    "angular.json": allow
    "tsconfig*.json": allow
  
  edit:
    "*": deny
    "pom.xml": allow
    "src/**": allow
    "frontend/**": allow
    "package.json": allow
    "angular.json": allow
    "tsconfig*.json": allow

  glob: allow
  grep: allow
  todowrite: allow

  bash: allow

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
Work too on frontend/** files and package.json and tsconfig*.json and angular.json
Do not inspect harness, IDE, Node, OpenCode, Cline, README, license, or external files.
Do not ask questions, browse, install software, or download anything.

Follow the small-batch workflow and Git checkpoints in AGENTS.md.
Continue until `mvn test` prints `BUILD SUCCESS`, or report a proven environmental blocker with exact command output.
Run `./notify-success.sh` only after verified success.
