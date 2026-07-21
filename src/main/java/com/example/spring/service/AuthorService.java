package com.example.spring.service;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.spring.entity.Author;
import com.example.spring.repository.AuthorRepository;
import jakarta.persistence.EntityManager;
import com.example.spring.repository.BookRepository;
import com.example.spring.entity.Book;

@Service
public class AuthorService {

    private final AuthorRepository authorRepo;
    private final BookRepository bookRepo;
    private final EntityManager entityManager;

    public AuthorService(AuthorRepository authorRepo,
                         BookRepository bookRepo,
                         EntityManager entityManager) {
        this.authorRepo = authorRepo;
        this.bookRepo = bookRepo;
        this.entityManager = entityManager;
    }

    // -- Authors --

    @Transactional
    public Author createAuthor(String firstName, String lastName, Integer age) {
        Author author = new Author(firstName, lastName, age);
        return authorRepo.save(author);
    }

    @Transactional(readOnly = true)
    public List<Author> getAllAuthors() {
        return authorRepo.findAll();
    }

    @Transactional(readOnly = true)
    public Optional<Author> getAuthorById(Long id) {
        return authorRepo.findById(id);
    }

    // -- Books (handled by AuthorService for ManyToMany coordination) --

    @Transactional
    public Book createBook(String title, String description) {
        Book book = new Book(title, description);
        return bookRepo.save(book);
    }

    @Transactional(readOnly = true)
    public List<Book> getAllBooks() {
        return bookRepo.findAll();
    }

    // -- Author-Book links (ManyToMany sync + flush verification) --

    @Transactional
    public Book addAuthorToBook(Long authorId, Long bookId) {
        Author a = entityManager.find(Author.class, authorId);
        Book b = entityManager.find(Book.class, bookId);
        if (a != null && b != null) {
            // Sync both sides via helper methods
            a.addBook(b);
            b.addAuthor(a);

            // Persist the link into book_author JoinTable
            authorRepo.flush();
            return b;
        }
        throw new IllegalArgumentException(
                "Cannot link: Author(id=" + authorId + ") or Book(id=" + bookId + ") not found");
    }

    /** Verify a flush committed persisted data by re-fetching after clear. */
    @Transactional(readOnly = true)
    public boolean verifyPersistedBookAfterFlush(Long bookId, String expectedTitle) {
        entityManager.flush();
        Book b = entityManager.find(Book.class, bookId);
        if (b == null) {
            return false;
        }
        return expectedTitle.equals(b.getTitle());
    }

}
