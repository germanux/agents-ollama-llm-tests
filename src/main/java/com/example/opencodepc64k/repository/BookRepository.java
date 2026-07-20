package com.example.opencodepc64k.repository;

import com.example.opencodepc64k.domain.Book;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BookRepository extends JpaRepository<Book, Long> {
}
