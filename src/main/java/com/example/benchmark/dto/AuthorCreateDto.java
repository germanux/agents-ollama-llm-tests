package com.example.benchmark.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record AuthorCreateDto(
    @NotNull
    @NotBlank
    String firstName,

    @NotNull
    @NotBlank
    String lastName,

    @Min(0)
    int age
) {
}
