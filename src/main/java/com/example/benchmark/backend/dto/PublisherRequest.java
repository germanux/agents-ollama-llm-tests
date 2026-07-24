package com.example.benchmark.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PublisherRequest(@NotBlank String name, @Size(max = 100) String country) {
}
