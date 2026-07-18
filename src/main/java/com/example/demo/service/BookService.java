package com.example.demo.service;

import com.example.demo.entity.Author;
import com.example.demo.entity.Book;
import com.example.demo.repository.AuthorRepository;
import com.example.demo.repository.BookRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;

@Service
public class BookService {

    private final AuthorRepository authorRepository;
    private final BookRepository bookRepository;

    public BookService(AuthorRepository authorRepository, BookRepository bookRepository) {
        this.authorRepository = authorRepository;
        this.bookRepository = bookRepository;
    }

    @Transactional
    public Book createBookWithAuthors(String title, String description, List<Author> authors) {
        Book book = new Book(title, description);
        for (Author author : authors) {
            if (author.getId() == null) {
                authorRepository.save(author);
            }
            book.addAuthor(author);
        }
        return bookRepository.save(book);
    }

    @Transactional(readOnly = true)
    public Set<String> findBookTitlesByAuthorId(Long authorId) {
        return bookRepository.findBookTitlesByAuthorId(authorId);
    }

    @Transactional(readOnly = true)
    public Author getAuthorById(Long id) {
        return authorRepository.findById(id).orElse(null);
    }

    @Transactional(readOnly = true)
    public Book getBookById(Long id) {
        return bookRepository.findById(id).orElse(null);
    }
}
