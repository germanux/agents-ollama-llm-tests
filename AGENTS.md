# AGENT RULES

## Scope and safety

- Work only inside this repository.
- Do not modify `AGENTS.md` or `BENCHMARK_TASK.md`.
- Do not create, modify, or delete files outside the repository.
- Do not use `sudo`, package managers, browsers, `curl`, or `wget`.
- Do not install or download Java, Maven, runtimes, IDEs, or binaries.
- Java 21, `javac`, and Maven are already installed.
- Maven may download dependencies declared in `pom.xml`.
- Do not push, merge, rebase, reset, or switch branches.

## Working method

- Think before editing and identify the actual cause of the failure.
- Keep the implementation simple.
- Make the smallest change that addresses the observed problem.
- Preserve working code and change one cause at a time.
- Do not weaken or remove task requirements merely to make tests pass.
- Continue autonomously until `mvn test` reports `BUILD SUCCESS`.

## Tool failure recovery

- Never repeat an unchanged failed tool call.
- After a failed patch, read the current file again before retrying.
- After two failed patch attempts on the same file, rewrite that file completely.
- After a failed command, use its actual output as the next diagnostic input.
- Change strategy after every repeated failure.
- Do not stop merely because the task is difficult or the model is local.
- Do not claim the context is full unless execution is actually blocked.

## Validation

- Run `mvn test` after every meaningful correction.
- Do not claim success while compilation or any test is failing.
- Keep required `flush()` and `clear()` persistence checks.
- Stop only after `BUILD SUCCESS` or a genuine environment blocker.

## Git

Create commits for coherent milestones:

1. Project structure and build configuration.
2. Application implementation.
3. Tests and final fixes.

Before each commit:

- Run `git status --short`.
- Stage only related files.
- Do not commit `target/`, IDE metadata, logs, or temporary files.
