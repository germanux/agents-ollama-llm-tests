# ANGULAR FRONTEND EXTENSION BENCHMARK

Continue from the committed Spring Boot REST application.

Create an Angular frontend under frontend/.

Implement one simple application that can:

- List authors.
- Create an author.
- List books and their authors.
- Create a book by selecting one or more existing authors.
- Select an author and display their book titles.
- Display loading, success and error states.

Technical requirements:

- Angular with TypeScript.
- Standalone components.
- HttpClient.
- Reactive Forms.
- Typed interfaces and API service.
- Basic responsive CSS.
- No Angular Material or other UI framework.
- Do not duplicate backend business logic in the frontend.

Build and integration:

- The Angular production build must succeed.
- Configure the build so Spring Boot serves the generated frontend.
- The REST API must remain under /api.
- The application root / must serve the Angular application.
- Preserve all existing backend tests.
- Add a backend test verifying that the frontend index is served.
- Run the Angular build and the complete Maven test/package process.
- Fix all failures until both builds succeed.
- Review git status and git diff.
- Create one commit for the Angular extension.
- Run notify-success.sh only after all required builds succeed.
