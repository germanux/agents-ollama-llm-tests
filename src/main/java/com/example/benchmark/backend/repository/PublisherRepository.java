package com.example.benchmark.backend.repository;

import com.example.benchmark.backend.model.Publisher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface PublisherRepository extends JpaRepository<Publisher, Long> {

    @Query("SELECT COUNT(b) > 0 FROM Book b WHERE b.publisher.id = :publisherId")
    boolean existsWithBooks(Long publisherId);
}
