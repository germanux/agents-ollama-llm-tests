package com.example.benchmark.backend.service;

import com.example.benchmark.backend.model.Author;
import com.example.benchmark.backend.model.Book;
import com.example.benchmark.backend.repository.AuthorRepository;
import com.example.benchmark.backend.repository.BookRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Transactional
public class LibraryService {

    private final AuthorRepository authorRepository;
    private final BookRepository bookRepository;

    public LibraryService(AuthorRepository authorRepository, BookRepository bookRepository) {
        this.authorRepository = authorRepository;
        this.bookRepository = bookRepository;
    }

    public Author persistAuthor(String firstName, String lastName, Integer age) {
        Author author = new Author(firstName, lastName, age);
        return authorRepository.save(author);
    }

    @Transactional
    public Book persistBookWithAuthors(String title, String description, Set<Long> authorIds) {
        List<Author> authors = authorRepository.findAllById(authorIds);

        if (authors.size() != authorIds.size()) {
            throw new IllegalArgumentException("One or more author IDs not found");
        }

        Book book = new Book(title, description);
        for (Author author : authors) {
            book.addAuthor(author);
        }

        return bookRepository.save(book);
    }

    public List<String> getBookTitlesByAuthorId(Long authorId) {
        return authorRepository.findBookTitlesByAuthorId(authorId);
    }
}
