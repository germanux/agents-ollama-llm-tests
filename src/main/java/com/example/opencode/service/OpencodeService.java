package com.example.opencode.service;

import com.example.opencode.Author;
import com.example.opencode.Book;
import com.example.opencode.repository.AuthorRepository;
import com.example.opencode.repository.BookRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class OpencodeService {

    private final AuthorRepository authorRepository;
    private final BookRepository bookRepository;

    @PersistenceContext
    private EntityManager entityManager;

    public OpencodeService(AuthorRepository authorRepository, BookRepository bookRepository) {
        this.authorRepository = authorRepository;
        this.bookRepository = bookRepository;
    }

    @Transactional
    public void persistBookWithAuthors(Book book, List<Author> authors) {
        for (Author author : authors) {
            book.addAuthor(author);
        }
        bookRepository.save(book);
        entityManager.flush();
        entityManager.clear();
    }

    public List<String> findBookTitlesByAuthorId(Long authorId) {
        Author author = authorRepository.findById(authorId)
                .orElseThrow(() -> new RuntimeException("Author not found: " + authorId));
        
        return author.getBooks().stream()
                .map(Book::getTitle)
                .toList();
    }
}
