package com.example.benchmark.backend.controller;

import com.example.benchmark.backend.dto.PublisherRequest;
import com.example.benchmark.backend.dto.PublisherResponse;
import com.example.benchmark.backend.exception.ConflictException;
import com.example.benchmark.backend.exception.ResourceNotFoundException;
import com.example.benchmark.backend.repository.PublisherRepository;
import com.example.benchmark.backend.service.LibraryService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/publishers")
public class PublisherController {

    private final LibraryService libraryService;

    public PublisherController(LibraryService libraryService) {
        this.libraryService = libraryService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PublisherResponse createPublisher(@Valid @RequestBody PublisherRequest request) {
        var publisher = libraryService.persistPublisher(request.name(), request.country());
        return PublisherResponse.fromEntity(publisher);
    }

    @GetMapping
    public List<PublisherResponse> listPublishers() {
        return libraryService.findAllPublishers()
                .stream()
                .map(PublisherResponse::fromEntity)
                .toList();
    }

    @PutMapping("/{id}")
    public ResponseEntity<PublisherResponse> updatePublisher(@PathVariable Long id, @Valid @RequestBody PublisherRequest request) {
        try {
            var publisher = libraryService.updatePublisher(id, request.name(), request.country());
            return ResponseEntity.ok(PublisherResponse.fromEntity(publisher));
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePublisher(@PathVariable Long id) {
        try {
            libraryService.deletePublisher(id);
            return ResponseEntity.noContent().build();
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.notFound().build();
        } catch (ConflictException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
    }
}
