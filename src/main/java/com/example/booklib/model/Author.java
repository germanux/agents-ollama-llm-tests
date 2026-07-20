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

    @Column(nullable = false)
    private Integer age;

    @ManyToMany(mappedBy = "authors", fetch = FetchType.LAZY)
    private List<Book> books = new ArrayList<>();

    // Default constructor for JPA
    public Author() {}

    /**
     * Constructor with author details.
     */
    public Author(String firstName, String lastName, Integer age) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.age = age;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String first) { this.firstName = first; }

    public String getLastName() { return lastName; }
    public void setLastName(String last) { this.lastName = last; }

    public Integer getAge() { return age; }
    public void setAge(Integer age) { this.age = age; }

    public List<Book> getBooks() { return books; }

    /**
     * Helper method to add a book to this author's collection.
     */
    public void addBook(Book book) {
        this.books.add(book);
        book.getAuthors().add(this);
    }

    /**
     * Helper method to remove a book from this author's collection.
     */
    public void removeBook(Book book) {
        this.books.remove(book);
        book.getAuthors().remove(this);
    }
}
