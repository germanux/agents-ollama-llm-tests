---
description: Complete benchmark using remote PC Ornith 64K
mode: primary
model: ollama-pc/ornith-cline-64k
temperature: 0.1
steps: 100
permission:
  "*": deny
  read: allow
  glob: allow
  grep: allow
  edit: allow
  bash: allow
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

Work only inside the current repository.
Respect every restriction in AGENTS.md and BENCHMARK_TASK.md.
Do not ask for confirmation.
Do not use web access, external directories, sudo or package managers.
Use the installed Java 21, javac and Maven.
Create the required project.
Run mvn test.
Diagnose and correct failures.
Continue until mvn test reports BUILD SUCCESS or a genuine environmental blocker is proven.
Do not claim success without real Maven output.
Create the required Git commits.
