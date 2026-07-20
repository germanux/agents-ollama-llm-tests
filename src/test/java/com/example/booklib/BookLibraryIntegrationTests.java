package com.example.booklib;

import com.example.booklib.model.Author;
import com.example.booklib.model.Book;
import com.example.booklib.repository.AuthorRepository;
import com.example.booklib.repository.BookRepository;
import com.example.booklib.service.BookLibraryService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class BookLibraryIntegrationTests {

    @Autowired
    private AuthorRepository authorRepository;

    @Autowired
    private BookRepository bookRepository;

    @Autowired
    private BookLibraryService bookLibraryService;

    /**
     * Test that a book with multiple authors is persisted and can be reloaded from the database.
     */
    @Test
    void testBookWithMultipleAuthorsPersists() {
        // Create two authors
        Author author1 = new Author("John", "Doe", 35);
        Author author2 = new Author("Jane", "Smith", 42);

        authorRepository.save(author1);
        authorRepository.save(author2);

        // Create one book and associate with both authors via helper methods
        Book book = new Book("The Great Adventure", "An exciting journey");
        book.addAuthor(author1);
        book.addAuthor(author2);

        // Persist the book through service (service handles flush/clear)
        bookLibraryService.persistBookWithAuthors(book, Arrays.asList(author1, author2));

        // Reload from database using a new query (triggers DB round-trip after clear)
        Book reloadedBook = bookRepository.findById(book.getId()).orElseThrow();

        // Assert that the reloaded book has exactly both authors
        assertThat(reloadedBook.getAuthors()).hasSize(2);
        assertThat(reloadedBook.getAuthors())
                .extracting(Author::getFirstName)
                .containsOnly("John", "Jane");
    }

    /**
     * Test that titles are queried by author ID using a real repository query.
     */
    @Test
    void testTitlesQueriedByAuthorId() {
        // Persist an author associated with at least two books
        Author author = new Author("George", "Martin", 50);
        authorRepository.save(author);

        Book book1 = new Book("Book One", "Description one");
        Book book2 = new Book("Book Two", "Description two");

        book1.addAuthor(author);
        book2.addAuthor(author);

        bookRepository.save(book1);
        bookRepository.save(book2);

        // Invoke service method (service handles flush/clear for query)
        List<String> titles = bookLibraryService.getBookTitlesByAuthorId(author.getId());

        // Assert the exact returned titles
        assertThat(titles).hasSize(2);
        assertThat(titles).containsExactlyInAnyOrder("Book One", "Book Two");
    }
}
