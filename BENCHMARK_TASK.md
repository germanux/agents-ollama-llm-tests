# AGENTIC CODING BENCHMARK

## Mandatory preflight

Before creating or modifying project files, run:

```bash
java -version
javac -version
mvn -version
```

Confirm Java 21, `javac` 21, and Maven using Java 21. If any check fails, stop and report the exact blocker.

## Objective

Create from scratch a Java 21 Maven project using Spring Boot 3, Spring Data JPA, and H2.

Implement these entities:

### Author

- `id`
- `firstName`
- `lastName`
- `age`

### Book

- `id`
- `title`
- `description`

An author can have many books and a book can have many authors.

## Required components

Create:

- `pom.xml`
- Spring Boot application class
- JPA entities
- Spring Data repositories
- A service
- JUnit 5 integration tests
- Minimal H2 test configuration

## Functional requirements

The service must:

1. Create and persist one book associated with multiple authors.
2. Return the titles of all books associated with an author ID using a real database query.

## Technical constraints

- Use `jakarta.persistence`.
- Do not use Lombok.
- Do not add REST controllers.
- Use one owning side for the bidirectional many-to-many relationship.
- Synchronize both sides through helper methods.
- Do not use `CascadeType.ALL`.
- Use JUnit 5 or AssertJ assertions, never native Java `assert`.
- Tests must call `flush()` and `clear()` before reloading persisted data.
- Do not weaken or remove the persistence checks.
- Do not modify unrelated files.
- Do not consult external documentation or browse the Internet.

## Completion

Run:

```bash
mvn test
```

Inspect every failure and continue correcting the project until Maven reports:

```text
BUILD SUCCESS
```

Only after success, run:

```bash
./notify-success.sh
```
