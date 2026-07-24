package com.example.benchmark.backend.dto;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

public record AuthorResponse(Long id, String firstName, String lastName, Integer age, List<String> genres) {
    public static AuthorResponse fromEntity(com.example.benchmark.backend.model.Author author) {
        Set<String> genreSet = author.getBooks().stream()
                .map(book -> book.getGenre())
                .filter(genre -> genre != null && !genre.isEmpty())
                .collect(Collectors.toSet());

        List<String> genres = genreSet.stream().sorted().toList();

        return new AuthorResponse(
            author.getId(),
            author.getFirstName(),
            author.getLastName(),
            author.getAge(),
            genres
        );
    }
}
