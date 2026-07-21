package com.example.spring.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.spring.entity.Book;

public interface BookRepository extends JpaRepository<Book, Long> {
    List<Book> findByTitleLike(String title);
}
