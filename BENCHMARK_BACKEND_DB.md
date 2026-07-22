# PERSISTENCE BACKEND BENCHMARK

Create from scratch a Java 21 Maven project using Spring Boot 3, Spring Data JPA, and H2.

## Domain model

### Author

- `id`
- `firstName`
- `lastName`
- `age`
- books authored by the author

### Book

- `id`
- `title`
- `description`
- authors of the book

The relationship is bidirectional many-to-many.

## Required implementation

Create:

- `pom.xml`;
- Spring Boot application class;
- `Author` and `Book` JPA entities;
- one Spring Data repository per entity;
- transactional service layer;
- JUnit 5 integration tests;
- minimal H2 test configuration that is actually activated by the tests.

The service must:

1. persist authors;
2. persist a book associated with multiple persisted author IDs;
3. reject any missing author ID rather than silently ignoring it;
4. return `List<String>` containing the titles associated with an author ID through a real repository query.

## Persistence design

- Use `jakarta.persistence`.
- Use exactly one owning side with `@JoinTable`; `Book` must be the owning side.
- Keep both Java-side collections synchronized through helper methods.
- Use `Set` for many-to-many collections.
- Keep associations lazy; do not use `FetchType.EAGER` as a workaround.
- Do not use `CascadeType.ALL`.
- Do not expose public setters that replace relationship collections.
- Do not base `equals()` or `hashCode()` on mutable relationship collections.
- The title lookup must be a repository query that returns titles directly, not traversal of an already loaded collection.
- Keep the design minimal. Do not create controllers, DTOs, mappers, or unrelated domain layers in this phase.
- Do not use Lombok.

## Required tests

Use `@SpringBootTest`, JUnit 5, and AssertJ or JUnit assertions. Never use native Java `assert`.

Create tests that prove:

1. **Book with multiple authors is persisted**
   - persist two authors;
   - create one book associated through the relationship helper;
   - persist through the service using the persisted author IDs;
   - call `flush()` and `clear()` explicitly;
   - reload the book from the database;
   - assert exactly both author IDs.

2. **Titles are queried by author ID**
   - persist one author associated with at least two books;
   - call `flush()` and `clear()` explicitly before querying;
   - invoke the service using the persisted author ID;
   - assert the exact returned titles.

Do not replace database reloads with assertions against objects still held in the persistence context. Do not weaken or remove the `flush()` and `clear()` checks.

## Phase validation and checkpoint

Run the complete Maven test suite until Maven reports `BUILD SUCCESS`.

Then:

```bash
git status --short
git diff --check
```

Review the diff and create one coherent persistence milestone commit. Do not run `notify-success.sh` in this phase.
