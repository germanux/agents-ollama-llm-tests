package com.example.benchmark.backend.dto;

public record PublisherResponse(Long id, String name, String country) {
    public static PublisherResponse fromEntity(com.example.benchmark.backend.model.Publisher publisher) {
        return new PublisherResponse(
            publisher.getId(),
            publisher.getName(),
            publisher.getCountry()
        );
    }
}
