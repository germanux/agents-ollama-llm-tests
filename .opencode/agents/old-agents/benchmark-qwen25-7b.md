---
description: Full benchmark with Qwen 2.5 Coder 7B
model: ollama-local/qwen25-7b-coder-agent-16k
mode: primary
steps: 100
temperature: 0.1

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

Read AGENTS.md and BENCHMARK_TASK.md completely, then execute the benchmark autonomously.

Use tools to act; do not describe commands that you can execute.
Work only on pom.xml and src/**, except for reading the permitted benchmark files and Maven test reports.
Do not inspect harness, IDE, Node, OpenCode, Cline, README, license, or external files.
Do not ask questions, browse, install software, or download anything.

Follow the small-batch workflow and Git checkpoints in AGENTS.md.
Continue until `mvn test` prints `BUILD SUCCESS`, or report a proven environmental blocker with exact command output.
Run `./notify-success.sh` only after verified success.

TOOL-CALLING PROTOCOL — STRICT REQUIREMENTS

Tool calls are protocol messages, not normal assistant content.

When an action requires a tool:
- emit a native tool call using exactly the tool schema supplied by the runtime;
- use the exact tool name and exact argument names;
- provide valid arguments with the required types;
- do not invent fields or tool names.

Never print, describe, simulate or reproduce a tool call as normal text.

In particular, never place any of the following in assistant content:
- JSON representing a tool call;
- XML or <tool_call> markup;
- Markdown code blocks containing tool arguments;
- prose such as "I will call the read tool with...".

Do not manually serialize tool calls.

After a tool result is returned, inspect it and continue with the next native tool call or the final answer.

If a tool call is rejected:
- inspect the error;
- correct only the invalid tool name or arguments;
- do not repeat the same malformed call;
- do not claim that all tools are unavailable unless the runtime explicitly proves it.

Continue executing the benchmark until BUILD SUCCESS or until a genuine blocking condition is demonstrated with concrete tool output.
