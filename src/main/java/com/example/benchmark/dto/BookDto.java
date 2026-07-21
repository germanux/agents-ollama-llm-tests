package com.example.benchmark.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record BookDto(
    Long id,

    @NotNull
    @NotBlank
    String title,

    @NotNull
    @Size(min = 1)
    List<String> authors
) {
    public static BookDto fromEntity(com.example.benchmark.entity.Book book, List<String> authorNames) {
        return new BookDto(
            book.getId(),
            book.getTitle(),
            authorNames
        );
    }
}
