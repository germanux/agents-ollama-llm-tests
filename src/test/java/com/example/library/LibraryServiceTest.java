package com.example.library;

import com.example.library.entity.Author;
import com.example.library.entity.Book;
import com.example.library.service.LibraryService;
import org.junit.jupiter.api.Test;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class LibraryServiceTest {

    @Autowired
    private LibraryService libraryService;

    @Autowired
    private com.example.library.repository.BookRepository bookRepository;

    @Autowired
    private EntityManager entityManager;

    // Scenario 1: Creating and persisting one book with multiple authors.
    @Test
    void shouldPersistBookWithMultipleAuthors() {
        Author author1 = new Author();
        author1.setNombre("Gabriel");
        author1.setApellidos("García Márquez");
        author1.setEdad(70);

        Author author2 = new Author();
        author2.setNombre("Mario");
        author2.setApellidos("Benedetti");
        author2.setEdad(80);

        Book book = new Book();
        book.setTitulo("La casa de hojas vacías");
        book.setDescripcion("Una novela experimental sobre el tiempo y la memoria.");

        libraryService.saveBook(book, author1, author2);
        libraryService.flush();

        var savedBooks = bookRepository.findAll();
        assertThat(savedBooks).hasSize(1);

        Book persisted = savedBooks.get(0);
        assertThat(persisted.getId()).isNotNull();
        assertThat(persisted.getTitulo()).isEqualTo("La casa de hojas vacías");
        assertThat(persisted.getDescripcion()).isEqualTo("Una novela experimental sobre el tiempo y la memoria.");
        assertThat(persisted.getAuthors()).hasSize(2);

        // Verify bidirectional sync on both sides.
        assertThat(author1.getBooks()).contains(book);
        assertThat(author2.getBooks()).contains(book);
    }

    // Scenario 2: Retrieving the titles of all books belonging to a given author.
    @Test
    void shouldFindBookTitlesByAuthorNombre() {
        Author author = new Author();
        author.setNombre("Jorge");
        author.setApellidos("Luis Borges");
        author.setEdad(60);

        Book book1 = new Book();
        book1.setTitulo("El Aleph");
        book1.setDescripcion("Relato de un punto que contiene todos los puntos.");

        Book book2 = new Book();
        book2.setTitulo("Ficciones");
        book2.setDescripcion("Colección de cuentos fantásticos.");

        libraryService.saveBook(book1, author);
        libraryService.saveBook(book2, author);
        libraryService.flush();

        // Flush to DB and clear persistence context so we query fresh.
        bookRepository.flush();
        entityManager.clear();

        var titles = libraryService.findBookTitlesByAuthorNombre("Jorge");
        assertThat(titles).hasSize(2);
        assertThat(titles).containsExactlyInAnyOrder("El Aleph", "Ficciones");
    }
}
