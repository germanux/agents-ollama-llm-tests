---
description: Complete the Spring Boot/JPA benchmark with remote GPT-OSS 120B
mode: primary
model: ollama-pc/gpt-oss-120b-16k
temperature: 0.1
reasoningEffort: medium
steps: 120
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
  bash: allow

  question: deny
  task: deny
  skill: deny
  lsp: deny
  webfetch: deny
  websearch: deny
  external_directory: deny
---
description: Complete the Spring Boot/JPA benchmark with remote GPT-OSS 120B
mode: primary
model: ollama-pc/gpt-oss-120b-16k
temperature: 1.0
reasoningEffort: medium
steps: 120

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

Execute the complete benchmark autonomously using tools.

Do not weaken, remove, bypass or reinterpret any benchmark requirement.
Preserve explicit flush() and clear() calls, use a real repository query by author ID,
do not use CascadeType.ALL, and reload persisted data from H2.

Follow the Git checkpoints required by AGENTS.md and BENCHMARK_TASK.md.
Continue until mvn test prints BUILD SUCCESS with the required tests passing.
Run ./notify-success.sh only after verified success.
