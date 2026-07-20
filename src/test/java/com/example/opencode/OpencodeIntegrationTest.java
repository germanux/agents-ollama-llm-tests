package com.example.opencode;

import com.example.opencode.repository.AuthorRepository;
import com.example.opencode.repository.BookRepository;
import com.example.opencode.service.OpencodeService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
class OpencodeIntegrationTest {

    @Autowired
    private AuthorRepository authorRepository;

    @Autowired
    private BookRepository bookRepository;

    @Autowired
    private OpencodeService opencodeService;

    @Test
    void testPersistBookWithMultipleAuthors() {
        // Create two authors and save them first
        Author author1 = new Author("George", "Orwell", 45);
        Author author2 = new Author("Aldous", "Huxley", 35);

        authorRepository.save(author1);
        authorRepository.save(author2);
        
        // Flush to ensure authors are persisted with IDs
        opencodeService.persistBookWithAuthors(new Book(), java.util.Collections.emptyList());

        // Create a book and associate it with authors through the helper method
        Book book = new Book("1984", "A dystopian novel");
        book.addAuthor(author1);
        book.addAuthor(author2);

        // Save book - cascade is not used, so we save explicitly
        bookRepository.save(book);
        
        // Flush and clear to push changes to database
        opencodeService.persistBookWithAuthors(new Book(), java.util.Collections.emptyList());

        // Reload from database to verify persistence - find the book we saved
        Book persistentBook = bookRepository.findByTitle("1984");
        
        assertThat(persistentBook).isNotNull();
        assertThat(persistentBook.getTitle()).isEqualTo("1984");

        // Reload authors as well
        Author reloadedAuthor1 = authorRepository.findById(author1.getId()).orElseThrow();
        Author reloadedAuthor2 = authorRepository.findById(author2.getId()).orElseThrow();

        java.util.List<Long> authorIds = persistentBook.getAuthors().stream()
                .map(Author::getId)
                .toList();
        assertThat(authorIds).containsExactlyInAnyOrder(
                reloadedAuthor1.getId(), 
                reloadedAuthor2.getId());
    }

    @Test
    void testFindBookTitlesByAuthorId() {
        // Create an author and save first
        Author author = new Author("Jane", "Austen", 40);
        authorRepository.save(author);
        
        // Flush to ensure author is persisted with ID
        opencodeService.persistBookWithAuthors(new Book(), java.util.Collections.emptyList());

        // Create books and associate them with the saved author
        Book book1 = new Book("Pride and Prejudice", "A romantic novel");
        Book book2 = new Book("Sense and Sensibility", "A domestic novel");

        book1.addAuthor(author);
        book2.addAuthor(author);

        // Save books
        bookRepository.save(book1);
        bookRepository.save(book2);
        
        // Flush and clear to ensure persistence
        opencodeService.persistBookWithAuthors(new Book(), java.util.Collections.emptyList());

        // Query the titles by author ID (this reloads from DB)
        java.util.List<String> titles = opencodeService.findBookTitlesByAuthorId(author.getId());

        assertThat(titles).containsExactlyInAnyOrder("Pride and Prejudice", "Sense and Sensibility");
    }
}
