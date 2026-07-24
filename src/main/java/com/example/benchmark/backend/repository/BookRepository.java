package com.example.benchmark.backend.repository;

import com.example.benchmark.backend.model.Book;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BookRepository extends JpaRepository<Book, Long> {
}
