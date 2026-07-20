package com.example.opencode.repository;

import com.example.opencode.Book;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BookRepository extends JpaRepository<Book, Long> {
    Book findByTitle(String title);
}
