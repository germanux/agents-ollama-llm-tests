package com.example.benchmark.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AuthorRequest(@NotBlank String firstName, @NotBlank String lastName, Integer age) {
}
