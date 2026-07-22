package com.example.benchmark.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.Set;

public record BookRequest(@NotBlank String title,
                          @Size(max = 1000) String description,
                          @Size(min = 1) Set<Long> authorIds) {
}
