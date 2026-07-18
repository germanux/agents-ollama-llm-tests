package com.example.demo.service;

import com.example.demo.model.Book;
import org.springframework.stereotype.Service;

@Service
public interface BookService {

    /**
     * Creates and persists a book associated with the given author IDs.
     */
    Book createBookWithAuthors(String title, String description, Long... authorIds);

    /**
     * Returns all book titles associated with an author ID using a real database query.
     */
    java.util.List<String> getBookTitlesByAuthorId(Long authorId);
}