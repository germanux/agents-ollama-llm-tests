# REST BACKEND EXTENSION BENCHMARK

Extend the existing Spring Boot application. Preserve all existing functionality
and tests.

Implement:

- REST endpoints for creating and listing authors.
- REST endpoints for creating and listing books.
- An endpoint that returns book titles for an author ID.
- Request and response DTOs.
- Jakarta Bean Validation.
- Correct HTTP status codes.
- A global REST exception handler.
- No direct serialization of JPA entities.
- MockMvc integration tests for the endpoints.

Book creation must accept:

- title
- description
- authorIds

The service must load the authors from the database and reject missing IDs.

Requirements:

- Keep the existing JPA tests passing.
- Use Java 21 and Spring Boot 3.
- Do not use Lombok.
- Run the complete Maven test suite.
- Fix all failures until Maven reports BUILD SUCCESS.
- Review git status and git diff.
- Create one commit for this REST extension.
- Run notify-success.sh only after the real successful build.
- 
