# RELIABLE EXECUTION

Apply these checks throughout the task:

1. Think before editing: inspect the current file and identify the smallest change that addresses the observed failure.
2. Keep it simple: do not add abstractions, dependencies, or files that are not required.
3. Make surgical changes: preserve working code and change one cause at a time.
4. Verify the goal: run `mvn test` after each meaningful correction.

## Tool failure recovery

- Never repeat an unchanged failed tool call.
- If a search-and-replace edit fails, read the current file again before retrying.
- After two failed patch attempts on the same file, rewrite that file completely with the intended final content.
- After a command fails, use its actual output as the next diagnostic input.
- Do not stop merely because the task is difficult or the model is local.
- Do not claim the context is full unless the harness actually blocks execution.
