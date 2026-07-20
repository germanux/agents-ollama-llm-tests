package com.example.opencodepc64k.repository;

import com.example.opencodepc64k.domain.Author;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuthorRepository extends JpaRepository<Author, Long> {
}
