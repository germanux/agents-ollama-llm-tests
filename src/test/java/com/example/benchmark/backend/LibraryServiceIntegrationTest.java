package com.example.benchmark.backend;

import com.example.benchmark.backend.model.Author;
import com.example.benchmark.backend.model.Book;
import com.example.benchmark.backend.repository.AuthorRepository;
import com.example.benchmark.backend.repository.BookRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class LibraryServiceIntegrationTest {

    @Autowired
    private AuthorRepository authorRepository;

    @Autowired
    private BookRepository bookRepository;

    @Test
    void testBookWithMultipleAuthorsIsPersisted() {
        // Persist two authors
        Author author1 = new Author("John", "Doe", 35);
        Author savedAuthor1 = authorRepository.save(author1);

        Author author2 = new Author("Jane", "Smith", 42);
        Author savedAuthor2 = authorRepository.save(author2);

        // Create one book associated through the relationship helper
        Book book = new Book("Spring Boot Guide", "A comprehensive guide to Spring Boot");
        book.addAuthor(savedAuthor1);
        book.addAuthor(savedAuthor2);

        // Persist through the repository
        Book savedBook = bookRepository.save(book);

        // Flush explicitly
        bookRepository.flush();

        // Reload the book from the database using a new query
        Book reloadedBook = bookRepository.findById(savedBook.getId()).orElseThrow();

        // Assert exactly both author IDs by querying them directly
        var authorIds = reloadedBook.getAuthors().stream()
                .map(Author::getId)
                .toList();
        
        assertThat(authorIds).hasSize(2);
        assertThat(authorIds).containsExactlyInAnyOrder(savedAuthor1.getId(), savedAuthor2.getId());
    }

    @Test
    void testTitlesAreQueriedByAuthorId() {
        // Persist one author associated with at least two books
        Author author = new Author("George", "Orwell", 46);
        Author savedAuthor = authorRepository.save(author);

        Book book1 = new Book("1984", "A dystopian novel");
        book1.addAuthor(savedAuthor);
        Book savedBook1 = bookRepository.save(book1);

        Book book2 = new Book("Animal Farm", "A satirical allegory");
        book2.addAuthor(savedAuthor);
        Book savedBook2 = bookRepository.save(book2);

        // Flush explicitly before querying
        authorRepository.flush();

        // Invoke the repository query using the persisted author ID
        var titles = authorRepository.findBookTitlesByAuthorId(savedAuthor.getId());

        // Assert the exact returned titles
        assertThat(titles).containsExactlyInAnyOrder("1984", "Animal Farm");
    }
}
