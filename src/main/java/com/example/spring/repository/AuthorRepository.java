package com.example.spring.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.spring.entity.Author;

public interface AuthorRepository extends JpaRepository<Author, Long> {
    List<Author> findByFirstNameLike(String firstName);
}
