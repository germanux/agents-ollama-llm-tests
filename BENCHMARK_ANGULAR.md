# ANGULAR FRONTEND EXTENSION BENCHMARK

Continue from the committed Spring Boot REST application. Preserve all backend behavior and tests.

Create the Angular application entirely under `frontend/`. Use the repository-provisioned Angular CLI and dependencies. Do not run `npm install`, `npm ci`, `npx`, or any command that downloads packages.

## Required user flows

Implement one simple application that can:

- list authors;
- create an author;
- list books and their authors;
- create a book by selecting one or more existing authors;
- select an author and display that author's book titles;
- display clear loading, success, empty, validation, and server-error states.

## Technical requirements

- Angular with TypeScript.
- Standalone components.
- `HttpClient`.
- Reactive Forms.
- Typed interfaces and one focused API service.
- Basic responsive CSS.
- No Angular Material or other UI framework.
- No duplicated backend business logic.
- Use relative `/api` URLs so frontend and backend share one origin.
- Keep the structure compact; avoid unnecessary state libraries, routing, or abstraction layers.

## Build and Spring Boot integration

- Configure `frontend/package.json` so `npm --prefix frontend run build` uses the repository-provisioned Angular CLI.
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
