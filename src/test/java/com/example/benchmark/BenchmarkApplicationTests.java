package com.example.benchmark;

import com.example.benchmark.entity.Author;
import com.example.benchmark.entity.Book;
import com.example.benchmark.repo.AuthorRepository;
import com.example.benchmark.repo.BookRepository;
import com.example.benchmark.service.BookService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class BenchmarkApplicationTests {

    @Autowired
    private BookService bookService;

    @Autowired
    private AuthorRepository authorRepository;

    @Autowired
    private BookRepository bookRepository;

    @PersistenceContext
    private EntityManager entityManager;

    @Test
    void testBookWithMultipleAuthorsIsPersisted() {
        // Create two authors and one book
        Author author1 = new Author("Author", "One", 30);
        Author author2 = new Author("Author", "Two", 40);

        // Persist authors first to get IDs
        authorRepository.saveAndFlush(author1);
        authorRepository.saveAndFlush(author2);

        Book book = new Book("Test Book", "A test book description");

        // Use a copy of the list to avoid ConcurrentModificationException
        List<Author> authorList = new ArrayList<>();
        authorList.add(author1);
        authorList.add(author2);

        // Persist through the service
        bookService.persistBookWithAuthors(book, authorList);

        // Call flush() and clear()
        bookRepository.flush();
        authorRepository.flush();

        // Reload from the database by clearing JPA context
        entityManager.clear();

        // Reload book and verify authors
        Book reloadedBook = bookRepository.findById(book.getId()).orElseThrow();
        assertThat(reloadedBook.getAuthors()).hasSize(2);
        assertThat(reloadedBook.getAuthors().stream().map(Author::getId).toList())
                .containsExactlyInAnyOrder(author1.getId(), author2.getId());
    }

    @Test
    void testTitlesAreQueriedByAuthorId() {
        // Persist an author associated with at least two books
        Author author = new Author("Author", "Three", 50);
        authorRepository.saveAndFlush(author);

        Book book1 = new Book("Book One", "Description 1");
        Book book2 = new Book("Book Two", "Description 2");
        book1.addAuthor(author);
        book2.addAuthor(author);

        bookRepository.saveAndFlush(book1);
        bookRepository.saveAndFlush(book2);

        // Call flush() and clear() before querying
        bookRepository.flush();
        authorRepository.flush();
        entityManager.clear();

        // Invoke the service method using the persisted author ID
        List<String> titles = bookService.getBookTitlesByAuthorId(author.getId());

        // Assert the exact returned titles
        assertThat(titles).hasSize(2);
        assertThat(titles).containsExactlyInAnyOrder("Book One", "Book Two");
    }
}
