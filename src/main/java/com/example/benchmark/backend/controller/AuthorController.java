package com.example.benchmark.backend.controller;

import com.example.benchmark.backend.dto.AuthorRequest;
import com.example.benchmark.backend.dto.AuthorResponse;
import com.example.benchmark.backend.service.LibraryService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/authors")
public class AuthorController {

    private final LibraryService libraryService;

    public AuthorController(LibraryService libraryService) {
        this.libraryService = libraryService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AuthorResponse createAuthor(@Valid @RequestBody AuthorRequest request) {
        var author = libraryService.persistAuthor(request.firstName(), request.lastName(), request.age());
        return new AuthorResponse(author.getId(), author.getFirstName(), author.getLastName(), author.getAge());
    }

    @GetMapping
    public List<AuthorResponse> listAuthors() {
        return libraryService.findAllAuthors()
                .stream()
                .map(a -> new AuthorResponse(a.getId(), a.getFirstName(), a.getLastName(), a.getAge()))
                .toList();
    }
}
