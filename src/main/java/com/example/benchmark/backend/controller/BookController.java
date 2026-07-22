package com.example.benchmark.backend.controller;

import com.example.benchmark.backend.dto.BookRequest;
import com.example.benchmark.backend.dto.BookResponse;
import com.example.benchmark.backend.exception.ResourceNotFoundException;
import com.example.benchmark.backend.service.LibraryService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/api/books")
public class BookController {

    private final LibraryService libraryService;

    public BookController(LibraryService libraryService) {
        this.libraryService = libraryService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BookResponse createBook(@Valid @RequestBody BookRequest request) {
        var book = libraryService.persistBookWithAuthors(request.title(), request.description(), request.authorIds());

        return new BookResponse(
                book.getId(),
                book.getTitle(),
                book.getDescription(),
                book.getAuthors().stream().map(a -> a.getId()).collect(java.util.stream.Collectors.toSet())
        );
    }

    @GetMapping
    public List<BookResponse> listBooks() {
        return libraryService.findAllBooks()
                .stream()
                .map(b -> new BookResponse(
                        b.getId(),
                        b.getTitle(),
                        b.getDescription(),
                        b.getAuthors().stream().map(a -> a.getId()).collect(java.util.stream.Collectors.toSet())
                ))
                .toList();
    }
}
