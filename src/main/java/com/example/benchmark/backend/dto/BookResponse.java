package com.example.benchmark.backend.dto;

import java.util.Set;

public record BookResponse(Long id, String title, String description, Set<Long> authorIds) {
}
