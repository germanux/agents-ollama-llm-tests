package com.example.benchmark.backend.controller;

import com.example.benchmark.backend.dto.AuthorRequest;
import com.example.benchmark.backend.dto.AuthorResponse;
import com.example.benchmark.backend.exception.ResourceNotFoundException;
import com.example.benchmark.backend.service.LibraryService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
        return AuthorResponse.fromEntity(author);
    }

    @GetMapping
    public List<AuthorResponse> listAuthors() {
        return libraryService.findAllAuthors()
                .stream()
                .map(AuthorResponse::fromEntity)
                .toList();
    }

    @PutMapping("/{id}")
    public ResponseEntity<AuthorResponse> updateAuthor(@PathVariable Long id, @Valid @RequestBody AuthorRequest request) {
        try {
            var author = libraryService.updateAuthor(id, request.firstName(), request.lastName(), request.age());
            return ResponseEntity.ok(AuthorResponse.fromEntity(author));
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAuthor(@PathVariable Long id) {
        try {
            libraryService.deleteAuthor(id);
            return ResponseEntity.noContent().build();
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.notFound().build();
        }
    }
}
