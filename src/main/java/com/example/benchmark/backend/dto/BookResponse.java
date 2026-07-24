package com.example.benchmark.backend.dto;

import java.util.Set;

public record BookResponse(Long id, String title, String argument, String genre, Set<Long> authorIds, Long publisherId) {
    public static BookResponse fromEntity(com.example.benchmark.backend.model.Book book) {
        return new BookResponse(
                book.getId(),
                book.getTitle(),
                book.getArgumento(),
                book.getGenre(),
                book.getAuthors().stream().map(a -> a.getId()).collect(java.util.stream.Collectors.toSet()),
                book.getPublisher() != null ? book.getPublisher().getId() : null
        );
    }
}
