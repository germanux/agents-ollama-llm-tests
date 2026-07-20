package com.example.booklib.service;

import com.example.booklib.model.Author;
import com.example.booklib.model.Book;
import com.example.booklib.repository.AuthorRepository;
import com.example.booklib.repository.BookRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@Transactional
public class BookLibraryService {

    private final AuthorRepository authorRepository;
    private final BookRepository bookRepository;
    private final EntityManager entityManager;

    public BookLibraryService(AuthorRepository authorRepository, BookRepository bookRepository, EntityManager entityManager) {
        this.authorRepository = authorRepository;
        this.bookRepository = bookRepository;
        this.entityManager = entityManager;
    }

    /**
     * Persist a book associated with multiple authors.
     */
    @Transactional
    public void persistBookWithAuthors(Book book, List<Author> authors) {
        for (Author author : authors) {
            book.addAuthor(author);
        }
        bookRepository.save(book);
        // Flush to database and clear persistence context
        entityManager.flush();
        entityManager.clear();
    }

    /**
     * Return titles of books associated with an author ID through a real repository query.
     */
    @Transactional(readOnly = true)
    public List<String> getBookTitlesByAuthorId(Long authorId) {
        // Flush any pending changes and clear persistence context
        entityManager.flush();
        entityManager.clear();
        
        return bookRepository.findTitlesByAuthorId(authorId);
    }
}
