# FULL-STACK AGENTIC CODING BENCHMARK

## Objective

Build and validate a complete Spring Boot and Angular application in three ordered phases:

1. persistence and service layer;
2. REST backend;
3. Angular frontend and Spring Boot integration.

The phase specifications are authoritative:

- `BENCHMARK_BACKEND_DB.md`
- `BENCHMARK_BACKEND_REST.md`
- `BENCHMARK_ANGULAR.md`

Complete each phase, validate it, and create its milestone commit before starting the next phase. Preserve all previously working behavior and tests.

## Fixed toolchain

Use the toolchain already selected by the launcher or shell:

- Java 21;
- Maven 3.x running on Java 21;
- Node.js 20.x, at least 20.9;
- npm;
- Angular CLI `17.3.17`, obtained project-locally through the pinned bootstrap command in `BENCHMARK_ANGULAR.md`.

Do not install or change system runtimes during the benchmark. Angular CLI does not need to exist before Phase 3; the phase task explicitly permits downloading the pinned CLI and project dependencies through npm.

## Mandatory preflight

Before creating or modifying project files, run:

```bash
java -version
javac -version
mvn -version
node --version
npm --version
git status --short
```

Proceed only when all of the following are confirmed:

- Java 21;
- `javac` 21;
- Maven running on Java 21;
- Node.js 20.x and npm are available;
- no unrelated working-tree changes would be overwritten.

Do not require a preinstalled global or repository-level Angular CLI. Do not treat a missing `node_modules/.bin/ng` as a blocker before the Angular workspace has been created.

Maven and npm may access their normal package registries only for dependency resolution explicitly required by this benchmark. `sudo`, operating-system package managers, global npm installation, `curl`, `wget`, and arbitrary downloads remain prohibited.

## Execution order

### Phase 1 — Persistence

Re-read `AGENTS.md`, then read and execute `BENCHMARK_BACKEND_DB.md` completely.

Gate before Phase 2:

- all persistence requirements implemented;
- complete Maven test suite reports `BUILD SUCCESS`;
- persistence milestone committed.

### Phase 2 — REST backend

Re-read `AGENTS.md`, then read and execute `BENCHMARK_BACKEND_REST.md` completely.

Gate before Phase 3:

- all persistence and REST tests pass together;
- complete Maven test suite reports `BUILD SUCCESS`;
- REST milestone committed.

### Phase 3 — Angular frontend

Re-read `AGENTS.md`, then read and execute `BENCHMARK_ANGULAR.md` completely.

The Angular phase may scaffold `frontend/`, create `package.json` and `package-lock.json`, and download pinned project dependencies through npm as specified by the phase task.

## Final validation

After all phases are implemented, run the real commands without hiding their exit status:

```bash
npm --prefix frontend run build
mvn clean package
git diff --check
git status --short
```

Success requires:

- Angular production build succeeds;
- complete Maven build and all backend tests succeed;
- the packaged Spring Boot application contains and serves the Angular frontend;
- all phase requirements remain satisfied;
- final Angular milestone is committed;
- `git status --short` is clean after final validation.

Only after all of the above succeeds, run:

```bash
./notify-success.sh
```

Do not notify after an intermediate phase.
