package com.example.booklibrary.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import com.example.booklibrary.entity.Author;

@Repository
public interface AuthorRepository extends JpaRepository<Author, Long> {
}
