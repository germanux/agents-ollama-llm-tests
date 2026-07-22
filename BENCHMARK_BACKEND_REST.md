# REST BACKEND EXTENSION BENCHMARK

Extend the committed persistence application. Preserve all existing functionality and tests.

## Required API

Implement these endpoints under `/api`:

- `POST /api/authors` — create an author;
- `GET /api/authors` — list authors;
- `POST /api/books` — create a book associated with existing authors;
- `GET /api/books` — list books with their authors;
- `GET /api/authors/{authorId}/book-titles` — return the exact titles for an author.

Book creation must accept:

- `title`;
- `description`;
- `authorIds` containing at least one author ID.

## Design requirements

- Use request and response DTOs. Java records are permitted.
- Never serialize JPA entities directly from controllers.
- Use Jakarta Bean Validation for required text, age, and author ID collections.
- Keep business logic in services, not controllers.
- Load every requested author from the database and reject missing IDs.
- Preserve lazy JPA associations; do not introduce `EAGER` to make serialization work.
- Use correct HTTP semantics:
  - `201 Created` for successful creation;
  - `200 OK` for successful reads;
  - `400 Bad Request` for validation failures;
  - `404 Not Found` for missing authors, books, or author IDs.
- Add a global REST exception handler with a small, consistent error response.
- Do not use Lombok.

## Required integration tests

Use MockMvc integration tests that verify at minimum:

1. valid author creation returns `201` and the created response;
2. invalid author input returns `400`;
3. author listing returns persisted authors;
4. valid book creation with existing author IDs returns `201`;
5. book creation with any missing author ID returns `404` and persists no partial book;
6. book listing returns books and their authors without serializing entities directly;
7. title lookup returns the exact expected titles;
8. title lookup for a missing author returns `404`.

Keep all persistence integration tests passing.

## Phase validation and checkpoint

Run the complete Maven test suite until Maven reports `BUILD SUCCESS`.

Then:

```bash
git status --short
git diff --check
```

Review the diff and create one coherent REST milestone commit. Do not run `notify-success.sh` in this phase.
