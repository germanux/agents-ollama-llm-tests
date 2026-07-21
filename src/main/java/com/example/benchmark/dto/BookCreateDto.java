package com.example.benchmark.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record BookCreateDto(
    @NotNull
    @NotBlank
    String title,

    String description,

    @NotNull
    @Size(min = 1)
    List<Long> authorIds
) {
}
