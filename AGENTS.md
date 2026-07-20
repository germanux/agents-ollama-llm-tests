# AGENT RULES

## Scope and safety

- Work only inside this repository.
- Do not modify `AGENTS.md` or `BENCHMARK_TASK.md`.
- Do not access or change files outside the permitted benchmark paths.
- Do not use `sudo`, package managers, browsers, `curl`, or `wget`.
- Do not install or download Java, Maven, runtimes, IDEs, or binaries.
- Java 21, `javac`, and Maven are already installed.
- Maven may download dependencies declared in `pom.xml`.
- Do not push, merge, rebase, reset, switch branches, or amend commits.

## Engineering method

- Think before editing. Identify the current objective and the evidence available.
- Do not hide uncertainty. When ambiguity remains, choose the simplest interpretation consistent with `BENCHMARK_TASK.md`; do not invent requirements.
- Implement the minimum code needed. Avoid speculative abstractions, extra layers, and unrelated cleanup.
- Make surgical changes. Every changed line must support the benchmark objective.
- Preserve working code and change one cause at a time.
- Never weaken tests or requirements merely to obtain a green build.

## Small-batch execution

Work in coherent batches of no more than two new or materially changed project files.

After each batch:

1. Run the narrowest meaningful verification:
   - `mvn -q -DskipTests compile` for production-code batches.
   - `mvn -q test` for test-related batches or final validation.
2. If it fails, use the exact output to diagnose and fix the cause before committing.
3. Run `git status --short` and `git diff`.
4. Stage only the files from that batch and create one coherent commit.

If a batch is temporarily uncompilable because two tightly coupled files are required, finish that pair before verification. Do not accumulate a larger batch.

Recommended milestones:

1. `pom.xml` and application class.
2. `Author` and `Book` entities.
3. Two repositories.
4. Service and test configuration.
5. Integration tests and final fixes.

## Failure recovery

- Never repeat an unchanged failed tool call.
- After a failed edit, read the current file before retrying.
- After two failed edits on the same file, rewrite that file completely.
- After a failed command, use its actual output as the next diagnostic input.
- Change strategy after every repeated failure.
- Do not stop because the task is difficult or the model is local.
- Report a blocker only when command output proves that the environment prevents progress.

## Validation and completion

- Define success as all requirements implemented and `mvn test` reporting `BUILD SUCCESS`.
- Tests must verify database persistence after `flush()` and `clear()`; cached in-memory state is insufficient.
- Do not claim success while compilation or any test is failing.
- Keep reasoning concise and issue the next tool call as soon as the action is clear.
- Run `./notify-success.sh` only after verified `BUILD SUCCESS`.
