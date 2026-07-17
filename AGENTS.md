# AGENT OPERATING RULES

## Scope and safety

- Work only inside the current repository directory.
- Do not create, modify, move, or delete files outside the current repository.
- Do not use `sudo`, `apt`, `apt-get`, `dnf`, `pacman`, `snap`, or `flatpak`.
- Do not install or download Java, Maven, build tools, IDEs, runtimes, or binaries.
- Do not use `curl`, `wget`, a browser, or external web services to solve the task.
- Java 21, `javac`, and Maven are already installed globally.
- If `java`, `javac`, or `mvn` are unavailable, stop and report the exact blocking condition.
- Do not modify `AGENTS.md` or `BENCHMARK_TASK.md`.
- Do not use `git push`, `merge`, `rebase`, `reset`, or switch branches.

## Build and validation

- Use `mvn test` as the validation command.
- Do not claim that the project compiles unless you have run `mvn test`.
- Do not declare the task complete while compilation or any test is failing.
- After each failure, inspect the output and fix only the identified cause.
- The task may end only in one of these states:
  1. `mvn test` finishes with `BUILD SUCCESS`.
  2. A genuine environment blocker prevents further progress without violating these rules.

## Git workflow

Create one commit after each coherent logical unit:

1. Project structure and `pom.xml`.
2. JPA entities.
3. Repositories and service.
4. Tests.
5. Final fixes required to obtain `BUILD SUCCESS`.

Before every commit:

- Run `git status --short`.
- Stage only the files related to that logical unit.
- Use a clear, descriptive commit message.
- Do not commit `target/`, downloaded files, generated binaries, or temporary files.

## Completion report

At the end, report only:

- Files created or modified.
- Commits created.
- Validation commands executed.
- Final test result.
- Any remaining limitation.
