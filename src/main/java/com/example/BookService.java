package com.example;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class BookService {

    @Autowired
    private BookRepository bookRepository;

    @Autowired
    private AuthorRepository authorRepository;

    @PersistenceContext
    private EntityManager entityManager;

    public Book createBookWithAuthors(String title, String description, List<Author> authors) {
        Book book = new Book(title, description);
        
        for (Author author : authors) {
            book.addAuthor(author);
        }
        
        return bookRepository.save(book);
    }

    public List<String> getBookTitlesByAuthorId(Long authorId) {
        // Primero cargamos el autor desde la base de datos para asegurar que esté en contexto
        Author author = authorRepository.findById(authorId)
                .orElseThrow(() -> new RuntimeException("Author not found with id: " + authorId));
        
        // Forzamos la carga de la relación con autores
        entityManager.refresh(author);
        
        return author.getBooks().stream()
                .map(Book::getTitle)
                .collect(Collectors.toList());
    }
}