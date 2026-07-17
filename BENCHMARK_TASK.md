# AGENTIC CODING BENCHMARK

Work directly in this repository and create the complete project from scratch.

## Objective

Implement a Spring Boot 3 project using Java 21 and Maven to manage books and authors with JPA.

An author has exactly:

- `id`
- `nombre`
- `apellidos`
- `edad`

A book has exactly:

- `id`
- `titulo`
- `descripcion`

A book can have multiple authors, and an author can have multiple books.

## Required implementation

Create:

- A valid Maven `pom.xml`.
- The Spring Boot application class.
- JPA entities.
- Spring Data JPA repositories.
- A basic service.
- JUnit 5 tests.
- Any minimal configuration required to run the tests with an in-memory H2 database.

## Functional requirements

The tests must verify:

1. Creating and persisting one book with multiple authors.
2. Retrieving from the database the titles of all books belonging to a given author.

## Technical constraints

- Use Spring Boot 3.
- Use Java 21.
- Use `jakarta.persistence`.
- Do not use Lombok.
- Do not add REST controllers.
- Model the many-to-many relationship with exactly one owning side.
- Keep both sides of the bidirectional relationship synchronized through helper methods.
- Do not use `CascadeType.ALL` in the many-to-many relationship.
- The service must support associating a book with multiple authors.
- The title lookup must execute a real database query.
- Tests must use JUnit 5.
- Tests must verify real persistence by calling `flush()` and `clear()` before reloading data.
- Do not use native Java `assert`; use JUnit 5 or AssertJ assertions.
- Do not modify this file or `AGENTS.md`.
- Do not consult the Internet or external documentation.
- Do not only print code in the chat: create and modify the repository files.
- Do not modify unrelated files.

## Validation

Run:

```bash
mvn test
```

Analyze every failure and continue correcting the project until all tests pass.

Do not declare completion until Maven reports:

```text
BUILD SUCCESS
```

## Success notification

Only after `mvn test` finishes with `BUILD SUCCESS`, run:

```bash
./notify-success.sh
```

Do not run the notification script if compilation or any test fails.
