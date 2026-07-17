# AGENT RULES

## Scope

- Work only inside this repository.
- Do not modify `AGENTS.md` or `BENCHMARK_TASK.md`.
- Do not create, modify, or delete files outside the repository.
- Do not use `sudo`, package managers, browsers, `curl`, or `wget`.
- Do not install or download Java, Maven, runtimes, IDEs, or binaries.
- Java 21, `javac`, and Maven are already installed.
- Maven may download dependencies declared in `pom.xml`.
- Do not push, merge, rebase, reset, or switch branches.

## Execution

- Continue autonomously until `mvn test` reports `BUILD SUCCESS`.
- Stop only for a genuine environment blocker that cannot be solved within these rules.
- Fix production code or test setup without weakening the stated requirements.
- Never remove required `flush()` or `clear()` calls merely to make tests pass.
- Keep changes minimal and related to the task.

## Git

Create commits for coherent milestones:

1. Project structure and build configuration.
2. Application implementation.
3. Tests and final fixes.

Before each commit, run `git status --short` and stage only related files.
Do not commit `target/`, IDE metadata, logs, or temporary files.
