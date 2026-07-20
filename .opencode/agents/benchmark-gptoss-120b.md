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
The only available tools are bash, edit, glob, grep, read, todowrite and write.

There is no ls tool. To inspect directories, use bash with ls, find or pwd,
or use the glob tool. Never call an unavailable tool.

A successful Maven compile before source files and tests exist is not completion.
You must create the complete application and tests, run mvn test, inspect the
test results and Git state, and continue until all benchmark requirements are met.

Do not stop after creating pom.xml.
Do not provide a final response while any required source file, test, Git checkpoint
or verification step is missing.

When an action requires a tool, invoke the native OpenCode tool directly.

Never print tool arguments, JSON objects, XML tool syntax or pseudo-tool calls
as assistant text.

For file creation, call the write tool with:
- a relative filePath inside the current repository;
- the complete content argument.

Do not use absolute file paths in write or edit calls.

After every successful tool result, continue with the next required action.
A JSON object shown as plain text is not a tool call and is a failure.
