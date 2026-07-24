---
description: Run benchmark qwen3-coder-next-80b-t025-168k-8k-pc-pc
mode: primary
model: ollama-pc/qwen3-coder-next-80b-t025-168k-8k-pc-pc
steps: 320
temperature: 0.25

permission:
  "*": deny

  read:
    "*": deny
    "AGENTS.md": allow
    "BENCHMARK_TASK.md": allow
    "BENCHMARK_BACKEND_DB.md": allow
    "BENCHMARK_BACKEND_REST.md": allow
    "BENCHMARK_ANGULAR.md": allow
    "notify-success.sh": allow
    ".gitignore": allow
    "pom.xml": allow
    "src/**": allow
    "frontend/**": allow
    "target/**": allow

  edit:
    "*": deny
    ".gitignore": allow
    "pom.xml": allow
    "src/**": allow
    "frontend/**": allow

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

Read `AGENTS.md` and `BENCHMARK_TASK.md` completely, then execute the benchmark autonomously.

Use tools to act; do not merely describe commands or code that you can apply. Follow the phase order in the master task and read each active phase file before implementing it.

Re-read `AGENTS.md` and the active phase file before every phase, after any context compaction, after repeated failures, or whenever requirements are uncertain.

Do not inspect harness, IDE, OpenCode, Cline, README, license, external directories, or unrelated files. Do not ask questions or browse. Do not use `sudo`, system package managers, global npm installation, `curl`, `wget`, or unpinned package executors.

Project-local Maven and npm dependency resolution is allowed exactly as specified by the active task. The Angular phase may use the pinned `@angular/cli@17.3.17` bootstrap command, create `frontend/`, install its declared dependencies, and run its local build scripts.

Follow the engineering, failure-recovery, validation, dependency, and Git checkpoint rules in `AGENTS.md`. Continue until every required build and test succeeds, or report a proven environmental blocker with exact command output.

Run `./notify-success.sh` only after the master task's final validation succeeds.
