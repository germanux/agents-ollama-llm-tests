package com.example.booklib.repository;

import com.example.booklib.model.Author;
import com.example.booklib.model.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface BookRepository extends JpaRepository<Book, Long> {

    /**
     * Query titles of books associated with a specific author ID.
     */
    @Query("SELECT b.title FROM Book b JOIN b.authors a WHERE a.id = :authorId")
    List<String> findTitlesByAuthorId(@Param("authorId") Long authorId);
}
