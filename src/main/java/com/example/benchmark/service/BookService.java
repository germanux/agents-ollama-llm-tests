package com.example.benchmark.service;

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
}
