package com.example.benchmark.backend.controller;

import com.example.benchmark.backend.dto.BookRequest;
import com.example.benchmark.backend.dto.BookResponse;
import com.example.benchmark.backend.exception.ResourceNotFoundException;
import com.example.benchmark.backend.service.LibraryService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

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
        var book = libraryService.persistBookWithAuthors(request.title(), request.argument(), request.genre(), request.authorIds(), request.publisherId());

        return new BookResponse(
                book.getId(),
                book.getTitle(),
                book.getArgumento(),
                book.getGenre(),
                book.getAuthors().stream().map(a -> a.getId()).collect(java.util.stream.Collectors.toSet()),
                book.getPublisher() != null ? book.getPublisher().getId() : null
        );
    }

    @GetMapping
    public List<BookResponse> listBooks() {
        return libraryService.findAllBooks()
                .stream()
                .map(b -> new BookResponse(
                        b.getId(),
                        b.getTitle(),
                        b.getArgumento(),
                        b.getGenre(),
                        b.getAuthors().stream().map(a -> a.getId()).collect(java.util.stream.Collectors.toSet()),
                        b.getPublisher() != null ? b.getPublisher().getId() : null
                ))
                .toList();
    }

    @PutMapping("/{id}")
    public ResponseEntity<BookResponse> updateBook(@PathVariable Long id, @Valid @RequestBody BookRequest request) {
        try {
            var book = libraryService.updateBook(id, request.title(), request.argument(), request.genre(), request.authorIds(), request.publisherId());
            return ResponseEntity.ok(BookResponse.fromEntity(book));
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBook(@PathVariable Long id) {
        try {
            libraryService.deleteBook(id);
            return ResponseEntity.noContent().build();
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/{id}/cover")
    public ResponseEntity<BookResponse> uploadCover(@PathVariable Long id, @RequestParam("file") MultipartFile file) throws IOException {
        try {
            var book = libraryService.updateBookCover(id, file.getContentType(), file.getBytes());
            return ResponseEntity.ok(BookResponse.fromEntity(book));
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}/cover")
    public ResponseEntity<Void> deleteCover(@PathVariable Long id) {
        try {
            libraryService.deleteBookCover(id);
            return ResponseEntity.noContent().build();
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/{id}/cover")
    public ResponseEntity<byte[]> getCover(@PathVariable Long id) {
        try {
            var book = libraryService.getBookById(id);
            if (book.getCoverImageData() == null) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok()
                    .header("Content-Type", book.getCoverImageContentType())
                    .body(book.getCoverImageData());
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.notFound().build();
        }
    }
}
