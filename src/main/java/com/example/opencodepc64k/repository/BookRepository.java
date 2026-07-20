package com.example.opencodepc64k.repository;

import com.example.opencodepc64k.domain.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface BookRepository extends JpaRepository<Book, Long> {
    @Query("SELECT DISTINCT b FROM Book b JOIN FETCH b.authors WHERE :authorId MEMBER OF b.authors")
    List<Book> findDistinctByAuthorsId(Long authorId);
}
