package com.example.benchmark.service;

import com.example.benchmark.dto.BookCreateDto;
import com.example.benchmark.entity.Author;
import com.example.benchmark.entity.Book;
import com.example.benchmark.repo.AuthorRepository;
import com.example.benchmark.repo.BookRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class BookService {

    private final AuthorRepository authorRepository;
    private final BookRepository bookRepository;

    public BookService(AuthorRepository authorRepository, BookRepository bookRepository) {
        this.authorRepository = authorRepository;
        this.bookRepository = bookRepository;
    }

    @Transactional
    public void persistBookWithAuthors(Book book, List<Author> authors) {
        for (Author author : authors) {
            book.addAuthor(author);
        }
        bookRepository.save(book);
    }

    public List<String> getBookTitlesByAuthorId(Long authorId) {
        List<Book> books = bookRepository.findByAuthorsId(authorId);
        return books.stream()
                .map(Book::getTitle)
                .collect(Collectors.toList());
    }

    @Transactional
    public Book persistBookWithAuthorIds(BookCreateDto dto) {
        List<Author> authors = authorRepository.findAllById(dto.authorIds());
        
        if (authors.size() != dto.authorIds().size()) {
            throw new IllegalArgumentException("One or more author IDs not found");
        }
        
        Book book = new Book(dto.title(), dto.description());
        for (Author author : authors) {
            book.addAuthor(author);
        }
        bookRepository.save(book);
        return book;
    }

    @Transactional(readOnly = true)
    public List<String> getBookTitlesByAuthorIdWithValidation(Long authorId) {
        if (!authorRepository.existsById(authorId)) {
            throw new IllegalArgumentException("Author not found with ID: " + authorId);
        }
        return getBookTitlesByAuthorId(authorId);
    }

    @Transactional(readOnly = true)
    public List<Book> getBooksByAuthorId(Long authorId) {
        return bookRepository.findByAuthorsId(authorId);
    }

    @Transactional(readOnly = true)
    public List<Book> findAllBooks() {
        return bookRepository.findAll();
    }
}
