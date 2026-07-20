package com.example.opencodepc64k.service;

import com.example.opencodepc64k.domain.Book;
import com.example.opencodepc64k.repository.AuthorRepository;
import com.example.opencodepc64k.repository.BookRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class BookService {

    private final BookRepository bookRepository;
    private final AuthorRepository authorRepository;

    public BookService(BookRepository bookRepository, AuthorRepository authorRepository) {
        this.bookRepository = bookRepository;
        this.authorRepository = authorRepository;
    }

    @Transactional
    public Book saveBookWithAuthors(Book book, List<Long> authorIds) {
        if (authorIds != null) {
            authorIds.forEach(id -> authorRepository.findById(id)
                .ifPresent(book.getAuthors()::add));
        }
        return bookRepository.save(book);
    }

    @Transactional(readOnly = true)
    public List<String> findBookTitlesByAuthorId(Long authorId) {
        return bookRepository.findDistinctByAuthorsId(authorId)
            .stream()
            .map(Book::getTitle)
            .collect(Collectors.toList());
    }
}
