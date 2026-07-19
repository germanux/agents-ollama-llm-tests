---
description: Complete benchmark using local laptop Ornith 16K
mode: primary
model: ollama-local/ornith-opencode-16k
temperature: 0.1
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

Read AGENTS.md and BENCHMARK_TASK.md completely before acting.

Execute the complete benchmark autonomously.

Only inspect these benchmark resources:
- AGENTS.md
- BENCHMARK_TASK.md
- pom.xml
- src/**
- target/surefire-reports/** when test diagnostics require it
- notify-success.sh

Do not inspect OpenCode, Cline, Node, README, license or harness bootstrap files.

Work only inside the current repository.
Respect every restriction in AGENTS.md and BENCHMARK_TASK.md.
Do not ask for confirmation.
Do not access the web or external directories.
Do not use sudo, package managers or download commands.

Use the installed Java 21, javac and Maven.
Create pom.xml and the required files under src/.
Run mvn test.
Diagnose and correct failures.
Continue until mvn test reports BUILD SUCCESS or a genuine environmental blocker is proven.
Do not claim success without real Maven output.
Create the required Git commits.
Run ./notify-success.sh only after BUILD SUCCESS.
