package com.example.benchmark.backend.repository;

import com.example.benchmark.backend.model.Author;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface AuthorRepository extends JpaRepository<Author, Long> {

    @Query("SELECT b.title FROM Book b JOIN b.authors a WHERE a.id = :authorId")
    List<String> findBookTitlesByAuthorId(Long authorId);
}
