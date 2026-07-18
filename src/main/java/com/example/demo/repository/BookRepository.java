package com.example.demo.repository;

import com.example.demo.entity.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Set;

@Repository
public interface BookRepository extends JpaRepository<Book, Long> {

    @org.springframework.data.jpa.repository.Query(
        "SELECT DISTINCT b.title FROM Book b JOIN b.authors a WHERE a.id = :authorId"
    )
    Set<String> findBookTitlesByAuthorId(Long authorId);
}
