# AGENT RULES

## Scope and safety

- Work only inside this repository and only on paths permitted by the active agent configuration.
- Treat `AGENTS.md` as read-only.
- Do not use `sudo`, operating-system package managers, browsers, `curl`, `wget`, or arbitrary external network tools.
- Do not install runtimes, IDEs, global packages, standalone binaries, or system software.
- Do not push, merge, rebase, reset, switch branches, amend commits, or alter Git history.

## Dependency and tooling policy

- Project-level dependency managers are allowed only when the active task explicitly requires them.
- Maven may resolve dependencies declared in `pom.xml`.
- npm may resolve and install project dependencies only inside `frontend/` or while scaffolding `frontend/` from the repository root.
- Do not install global npm packages and do not use `npm install -g`.
- Prefer `npm ci` when `frontend/package-lock.json` exists and is consistent with `frontend/package.json`.
- Use `npm install` only when initially creating the lockfile or intentionally changing declared project dependencies.
- Use `npm exec` or `npx` only with an explicitly pinned package version. Prefer `npm exec`.
- Do not run unpinned commands such as `npx @angular/cli@latest`, `npm update`, or `npm audit fix`.
- Do not change Node, Java, Maven, npm, Angular, or other toolchain versions unless the active task explicitly requires it.
- Network access is permitted only through Maven or npm dependency resolution explicitly allowed by the active task.
- Never commit `node_modules`, package-manager caches, Angular caches, or generated temporary build caches.

## Tool schema and failure recovery

- Tool arguments must match the declared schema exactly.
- For the `read` tool, `offset` and `limit` must be JSON integers, for example `100` and `40`, never decimal values such as `100.0` or `40.0`.
- After a tool call fails, treat the returned error message as authoritative and correct the arguments before retrying.
- Never repeat an identical failed tool call.
- If the same or an equivalent schema error occurs twice, stop that approach and switch to another valid strategy.
- Do not continue consuming steps while reproducing the same tool error.

## Sources of truth and refresh protocol

- Read `AGENTS.md` and the master task completely before acting.
- Read the active phase task completely before starting that phase.
- Re-read `AGENTS.md` and the active phase task:
  - before each major phase or milestone;
  - after any context compaction or context shift;
  - after repeated failures;
  - whenever a requirement is uncertain.
- Do not rely on memory when the instruction files can be read again.
- Resolve ambiguity with the simplest interpretation consistent with the active task. Do not invent requirements.

## Engineering method

- Inspect the current repository state before editing.
- Plan briefly, then use tools to act. Keep reasoning concise.
- Implement the minimum complete solution. Avoid speculative abstractions and unrelated cleanup.
- Preserve working code and change one cause at a time.
- Work in small, coherent batches, normally one to four tightly related files.
- After each batch, run the narrowest meaningful compile, lint, test, or build command defined by the active task.
- Never weaken requirements or tests merely to obtain a green build.

## Tool and failure discipline

- Use the exact tool schema. After one rejected tool call, correct the arguments before retrying.
- Never repeat an unchanged failed tool call.
- After two failed edits on the same file, read the current file and rewrite it completely or use another permitted editing method.
- After a failed command, use its actual output as the next diagnostic input.
- Change strategy after every repeated failure; do not remain in a loop.
- Do not hide command failures with pipelines. When a pipeline is necessary, use `set -o pipefail` and preserve the real exit status.
- Report a blocker only when command output proves that the environment prevents progress.
- Treat every temporary server as a managed resource: detect and remove only stale benchmark instances before starting, capture the new process PID, wait for readiness, run all required checks, and terminate that exact process within the same tool call, including on failure.

## Resume and reconnaissance discipline

When resuming an existing worktree:

- Read `AGENTS.md` and `BENCHMARK_TASK.md`.
- Use `git status --short` and `git log --oneline -10` to identify completed and pending phases.
- Treat a phase with its required Git checkpoint as completed unless a current validation command proves otherwise.
- Do not proactively inspect or reread the implementation of committed phases.
- Identify the earliest uncommitted or failing phase, then read only its `BENCHMARK_*.md`.
- Run that phase's canonical validation command before reading many implementation files.
- Use validation output to choose the specific files that need inspection.
- Perform no more than five reconnaissance tool calls before either running a validation or making a concrete change.
- Do not check installed tool versions unless a command actually fails because of the environment.
- Preserve context for implementation, testing and recovery rather than broad repository exploration.
- 
## Git checkpoints

- Before each milestone commit, run `git status --short`, review `git diff`, and run the milestone validation.
- Commit only coherent, verified work. Never commit a knowingly failing state.
- Stage only files belonging to the completed milestone.
- Use concise commit messages describing the implemented capability.

## Validation and completion

- The active task defines the authoritative success commands and completion criteria.
- Do not claim success while any required compile, test, lint, or build is failing.
- Re-run the complete required validation after the final correction.

## Mandatory resume completion gate

- When resuming a worktree that appears complete, you must read the current phase document associated with the latest implementation checkpoint before running final validation.
- A successful build, a clean working tree, or a previous validation commit is not sufficient evidence of completion.
- Do not run `notify-success.sh` or declare success unless the packaged application has been started in the current session and HTTP requests have successfully verified both a representative REST endpoint and the frontend HTML at `/`.

- Run `./notify-success.sh` only when the master task explicitly permits it and every required phase or final validation has succeeded.
