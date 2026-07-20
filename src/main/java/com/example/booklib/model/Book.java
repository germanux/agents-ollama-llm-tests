package com.example.booklib.model;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Book entity for a book library management system.
 */
@Entity
@Table(name = "books")
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition="TEXT")
    private String description;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "book_authors",
        joinColumns = @JoinColumn(name = "book_id"),
        inverseJoinColumns = @JoinColumn(name = "author_id")
    )
    private List<Author> authors = new ArrayList<>();

    // Default constructor for JPA
    public Book() {}

    /**
     * Constructor with book details.
     */
    public Book(String title, String description) {
        this.title = title;
        this.description = description;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public List<Author> getAuthors() { return authors; }

    /**
     * Helper method to add an author to this book's collection.
     */
    public void addAuthor(Author author) {
        this.authors.add(author);
        author.getBooks().add(this);
    }

    /**
     * Helper method to remove an author from this book's collection.
     */
    public void removeAuthor(Author author) {
        this.authors.remove(author);
        author.getBooks().remove(this);
    }
}
