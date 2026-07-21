# AGENTIC CODING BENCHMARK

## Mandatory preflight

Before creating or modifying project files, run:

```bash
java -version
javac -version
mvn -version
```

Proceed only when Java 21, `javac` 21, and Maven running on Java 21 are confirmed. Otherwise report the exact blocker.

## Objective

Create from scratch a Java 21 Maven project using Spring Boot 3, Spring Data JPA, and H2.

### Author

- `id`
- `firstName`
- `lastName`
- `age`

### Book

- `id`
- `title`
- `description`

The relationship is bidirectional many-to-many: an author has many books and a book has many authors.

## Required implementation

Create:

- `pom.xml`
- Spring Boot application class
- `Author` and `Book` JPA entities
- one repository per entity
- a service
- JUnit 5 integration tests
- minimal H2 test configuration

The service must:

1. Persist a book associated with multiple authors.
2. Return `List<String>` containing the titles of books associated with an author ID through a real repository query.

## Persistence design

- Use `jakarta.persistence`.
- Use exactly one owning side with `@JoinTable`; prefer `Book` as the owning side.
- Maintain both Java-side collections through helper methods such as `book.addAuthor(author)`.
- Do not use `CascadeType.ALL`.
- Keep the design minimal; no DTOs, mappers, extra domain layers, or unrelated utilities are required.

## Required tests

Use `@SpringBootTest`, JUnit 5, and AssertJ or JUnit assertions. Never use native Java `assert`.

Create tests that prove:

1. **Book with multiple authors is persisted**
   - create two authors and one book;
   - associate them through the helper method;
   - persist through the service;
   - call `flush()` and `clear()`;
   - reload from the database;
   - assert that the reloaded book has exactly both authors.

2. **Titles are queried by author ID**
   - persist an author associated with at least two books;
   - call `flush()` and `clear()` before querying;
   - invoke the service method using the persisted author ID;
   - assert the exact returned titles.

Do not replace database reloads with assertions against objects still held in the persistence context. Do not weaken or remove `flush()` and `clear()` checks.

## Completion

Run `mvn test` after test creation and after every meaningful correction. Continue until Maven reports:

```text
BUILD SUCCESS
```

Only then run:

```bash
./notify-success.sh
```
