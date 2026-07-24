package com.example.benchmark.backend.controller;

import com.example.benchmark.backend.dto.BookResponse;
import com.example.benchmark.backend.exception.ResourceNotFoundException;
import com.example.benchmark.backend.service.LibraryService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/authors")
public class AuthorBookTitlesController {

    private final LibraryService libraryService;

    public AuthorBookTitlesController(LibraryService libraryService) {
        this.libraryService = libraryService;
    }

    @GetMapping("/{authorId}/book-titles")
    public List<String> getBookTitlesByAuthor(@PathVariable Long authorId) {
        var titles = libraryService.getBookTitlesByAuthorId(authorId);
        
        if (titles.isEmpty()) {
            throw new ResourceNotFoundException("Author", authorId);
        }
        
        return titles;
    }
}
