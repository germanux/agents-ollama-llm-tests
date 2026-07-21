package com.example.benchmark.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public record AuthorDto(
    Long id,

    @NotNull
    @NotBlank
    String firstName,

    @NotNull
    @NotBlank
    String lastName,

    @Min(0)
    int age
) {
    public static AuthorDto fromEntity(com.example.benchmark.entity.Author author) {
        return new AuthorDto(
            author.getId(),
            author.getFirstName(),
            author.getLastName(),
            author.getAge()
        );
    }
}
