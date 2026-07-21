package com.example.benchmark.controller;

import com.example.benchmark.dto.AuthorCreateDto;
import com.example.benchmark.dto.AuthorDto;
import com.example.benchmark.entity.Author;
import com.example.benchmark.repo.AuthorRepository;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/authors")
public class AuthorController {

    private final AuthorRepository authorRepository;

    public AuthorController(AuthorRepository authorRepository) {
        this.authorRepository = authorRepository;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AuthorDto createAuthor(@RequestBody AuthorCreateDto dto) {
        Author author = new Author(dto.firstName(), dto.lastName(), dto.age());
        authorRepository.save(author);
        return AuthorDto.fromEntity(author);
    }

    @GetMapping
    public List<AuthorDto> listAuthors() {
        return authorRepository.findAll().stream()
                .map(AuthorDto::fromEntity)
                .collect(Collectors.toList());
    }
}
