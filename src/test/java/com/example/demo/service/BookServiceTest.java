package com.example.demo.service;

import com.example.demo.entity.Author;
import com.example.demo.entity.Book;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class BookServiceTest {

    @Autowired
    private BookService bookService;

    @Autowired
    private EntityManager entityManager;

    @Autowired
    private PlatformTransactionManager transactionManager;

    private TransactionTemplate transactionTemplate;

    @org.junit.jupiter.api.BeforeEach
    void setUp() {
        this.transactionTemplate = new TransactionTemplate(transactionManager);
    }

    @Test
    void shouldCreateBookWithMultipleAuthors() {
        Author author1 = new Author("John", "Doe", 30);
        Author author2 = new Author("Jane", "Smith", 28);

        Book savedBook = transactionTemplate.execute(status -> {
            return bookService.createBookWithAuthors(
                "Spring Boot in Action",
                "A comprehensive guide to Spring Boot",
                List.of(author1, author2)
            );
        });

        assertThat(savedBook).isNotNull();
        assertThat(savedBook.getId()).isNotNull();
        assertThat(savedBook.getTitle()).isEqualTo("Spring Boot in Action");
        assertThat(savedBook.getAuthors()).hasSize(2);
    }

    @Test
    void shouldReturnBookTitlesByAuthorId() {
        Author author1 = new Author("Alice", "Johnson", 35);

        transactionTemplate.executeWithoutResult(status -> {
            bookService.createBookWithAuthors(
                "Java Programming",
                "Learn Java from scratch",
                List.of(author1)
            );
        });

        Set<String> titles = transactionTemplate.execute(status -> {
            Author savedAuthor = entityManager.createQuery(
                "SELECT a FROM Author a WHERE a.firstName = :firstName", Author.class)
                .setParameter("firstName", "Alice")
                .getSingleResult();

            return bookService.findBookTitlesByAuthorId(savedAuthor.getId());
        });

        assertThat(titles).containsExactlyInAnyOrder("Java Programming");
    }

    @Test
    void shouldPersistAndRetrieveWithFlushClear() {
        Author author = new Author("Charlie", "Brown", 25);

        Book savedBook = transactionTemplate.execute(status -> {
            return bookService.createBookWithAuthors(
                "The Great Gatsby",
                "A classic American novel",
                List.of(author)
            );
        });

        assertThat(savedBook).isNotNull();
        assertThat(savedBook.getTitle()).isEqualTo("The Great Gatsby");

        // Flush and clear to ensure data is persisted, then reload
        transactionTemplate.executeWithoutResult(status -> {
            entityManager.flush();
            entityManager.clear();

            var titles = bookService.findBookTitlesByAuthorId(
                savedBook.getAuthors().get(0).getId());
            assertThat(titles).containsExactlyInAnyOrder("The Great Gatsby");
        });
    }

    @Test
    void shouldHandleMultipleBooksPerAuthor() {
        Author author = new Author("David", "Lee", 32);

        transactionTemplate.executeWithoutResult(status -> {
            bookService.createBookWithAuthors(
                "First Book",
                "Description of first book",
                List.of(author)
            );
        });

        Set<String> titles = transactionTemplate.execute(status -> {
            Author savedAuthor = entityManager.createQuery(
                "SELECT a FROM Author a WHERE a.firstName = :firstName", Author.class)
                .setParameter("firstName", "David")
                .getSingleResult();

            bookService.createBookWithAuthors(
                "Second Book",
                "Description of second book",
                List.of(savedAuthor)
            );

            entityManager.flush();
            entityManager.clear();

            return bookService.findBookTitlesByAuthorId(savedAuthor.getId());
        });

        assertThat(titles).containsExactlyInAnyOrder("First Book", "Second Book");
    }
}
