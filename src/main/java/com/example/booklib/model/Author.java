package com.example.booklib.model;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Author entity for a book library management system.
 */
@Entity
@Table(name = "authors")
public class Author {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String firstName;

    @Column(nullable = false)
    private String lastName;

    @ManyToMany(mappedBy = "authors", fetch = FetchType.LAZY, cascade = {CascadeType.PERSIST})
    private List<Book> books = new ArrayList<>();

    // Default constructor for JPA
    public Author() {}

    /**
     * Constructor with id and author details.
     */
    public Author(Long id, String firstName, String lastName) {
        this.id = id;
        this.firstName = firstName;
        this.lastName = lastName;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String first) { this.firstName = first; }

    public String getLastName() { return lastName; }
    public void setLastName(String last) { this.lastName = last; }

    public List<Book> getBooks() { return books; }
}
