package com.example.benchmark.controller;

import com.example.benchmark.dto.BookCreateDto;
import com.example.benchmark.dto.BookDto;
import com.example.benchmark.entity.Author;
import com.example.benchmark.entity.Book;
import com.example.benchmark.service.BookService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/books")
public class BookController {

    private final BookService bookService;

    public BookController(BookService bookService) {
        this.bookService = bookService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BookDto createBook(@RequestBody BookCreateDto dto) {
        Book book = bookService.persistBookWithAuthorIds(dto);
        List<String> authorNames = book.getAuthors().stream()
                .map(author -> author.getFirstName() + " " + author.getLastName())
                .collect(Collectors.toList());
        return new BookDto(book.getId(), book.getTitle(), authorNames);
    }

    @GetMapping
    public List<BookDto> listBooks() {
        return bookService.findAllBooks().stream()
                .map(book -> {
                    List<String> authorNames = book.getAuthors().stream()
                            .map(author -> author.getFirstName() + " " + author.getLastName())
                            .collect(Collectors.toList());
                    return new BookDto(book.getId(), book.getTitle(), authorNames);
                })
                .collect(Collectors.toList());
    }

    @GetMapping("/author/{authorId}/titles")
    public List<BookDto> getBooksByAuthorId(@PathVariable Long authorId) {
        return bookService.getBooksByAuthorId(authorId).stream()
                .map(book -> {
                    List<String> authorNames = book.getAuthors().stream()
                            .map(author -> author.getFirstName() + " " + author.getLastName())
                            .collect(Collectors.toList());
                    return new BookDto(book.getId(), book.getTitle(), authorNames);
                })
                .collect(Collectors.toList());
    }
}
