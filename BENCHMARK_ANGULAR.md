# ANGULAR FRONTEND EXTENSION BENCHMARK

Continue from the committed Spring Boot REST application. Preserve all backend behavior and tests.

Create the Angular application entirely under `frontend/` using Angular 17. Use the exact pinned Angular CLI version `17.3.17` and Node.js 20.x. Do not use a global Angular CLI.

## Bootstrap policy

First inspect whether `frontend/package.json` already exists.

### New frontend workspace

When `frontend/package.json` does not exist, scaffold the application from the repository root with this exact non-interactive command:

```bash
npm exec --yes --package=@angular/cli@17.3.17 -- \
  ng new frontend \
  --directory frontend \
  --standalone \
  --routing=false \
  --style=css \
  --skip-git \
  --skip-tests \
  --package-manager=npm \
  --strict \
  --defaults
```

This command is explicitly permitted to download the pinned Angular CLI and the dependencies declared by the generated Angular project.

### Existing frontend workspace

When both `frontend/package.json` and `frontend/package-lock.json` exist, install exactly the locked dependencies with:

```bash
npm --prefix frontend ci
```

Use `npm --prefix frontend install` only when the project intentionally needs a new or changed declared dependency and the lockfile must be updated. Do not install global packages. Do not use unpinned `npx` or `npm exec` packages. Do not run `npm update` or `npm audit fix`.

Ensure Git ignores at least:

```text
frontend/node_modules/
frontend/.angular/
frontend/dist/
```

Do not commit dependency directories or caches. Commit `frontend/package.json` and `frontend/package-lock.json`.

## Required user flows

Implement one simple application that can:

- list authors;
- create an author;
- list books and their authors;
- create a book by selecting one or more existing authors;
- select an author and display that author's book titles;
- display clear loading, success, empty, validation, and server-error states.

## Technical requirements

- Angular 17 with TypeScript.
- Standalone components.
- `HttpClient`.
- Reactive Forms.
- Typed interfaces and one focused API service.
- Basic responsive CSS.
- No Angular Material or other UI framework.
- No duplicated backend business logic.
- Use relative `/api` URLs so frontend and backend share one origin.
- Keep the structure compact; avoid unnecessary state libraries, routing, or abstraction layers.

Use Angular CLI scaffolding only for the initial workspace and basic project files. Implement the application deliberately; do not generate unrelated components or libraries.

## Build and Spring Boot integration

- Keep the production build command in `frontend/package.json` as a local CLI script, normally `ng build`.
- Configure the Angular production output so the generated application is copied to or produced under `src/main/resources/static/`.
- The REST API must remain under `/api`.
- Spring Boot must serve the Angular application at `/`.
- Add a backend integration test proving that `GET /` returns the frontend index successfully.
- The Angular production build must succeed.
- The complete Maven test and package process must succeed after the Angular build.

Generated frontend assets required by the packaged application may be committed for this benchmark. Do not commit `node_modules`, Angular caches, or unrelated build caches.

## Phase validation and checkpoint

Run:

```bash
npm --prefix frontend run build
mvn clean package
git status --short
git diff --check
```

Fix every failure until both builds succeed. Review the complete diff and create one coherent Angular integration milestone commit.

Do not run `notify-success.sh` here; return to the master task for final validation and notification.
