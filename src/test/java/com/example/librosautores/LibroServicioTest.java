package com.example.librosautores;

import com.example.librosautores.entity.Autor;
import com.example.librosautores.entity.Libro;
import com.example.librosautores.repository.AutorRepository;
import com.example.librosautores.repository.LibroRepository;
import com.example.librosautores.service.LibroServicio;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class LibroServicioTest {

    @Autowired
    private LibroServicio libroServicio;

    @Autowired
    private AutorRepository autorRepository;

    @Autowired
    private LibroRepository libroRepository;

    @Autowired
    private EntityManager entityManager;

    @BeforeEach
    void setUp() {
        autorRepository.deleteAll();
        libroRepository.deleteAll();
        entityManager.flush();
        entityManager.clear();
    }

    /**
     * Test: crear y persistir un libro con varios autores.
     */
    @Test
    void testCrearLibroConVariosAutores() {
        // Crear autores
        Autor autor1 = new Autor("Gabriel", "García Márquez", 70);
        Autor autor2 = new Autor("Isabel", "Allende", 80);

        autor1 = autorRepository.save(autor1);
        autor2 = autorRepository.save(autor2);

        // Crear libro con ambos autores
        Libro libro = libroServicio.crearLibroConAutores(
                "Cien Años de Soledad",
                "Novela de la familia Buendía",
                List.of(autor1, autor2)
        );

        entityManager.flush();
        entityManager.clear();

        // Verificar que se persistió en BD
        Libro libroPersistido = libroRepository.findById(libro.getId()).orElse(null);
        assertNotNull(libroPersistido);
        assertEquals("Cien Años de Soledad", libroPersistido.getTitulo());

        // Verificar la relación muchos a muchos
        List<String> titulos = libroServicio.obtenerTitulosPorAutor(autor1.getId());
        assertTrue(titulos.contains("Cien Años de Soledad"));

        List<String> titulos2 = libroServicio.obtenerTitulosPorAutor(autor2.getId());
        assertTrue(titulos2.contains("Cien Años de Soledad"));
    }

    /**
     * Test: recuperar desde la base de datos los títulos de los libros de un autor.
     */
    @Test
    void testRecuperarTitulosPorAutor() {
        // Crear autor
        Autor autor = new Autor("Jorge", "Luis Borges", 60);
        autor = autorRepository.save(autor);

        // Crear dos libros del mismo autor
        libroServicio.crearLibroConAutores("El Aleph", "Colección de cuentos", List.of(autor));
        libroServicio.crearLibroConAutores("Ficciones", "Antología de relatos", List.of(autor));

        entityManager.flush();
        entityManager.clear();

        // Recuperar títulos desde BD
        List<String> titulos = libroServicio.obtenerTitulosPorAutor(autor.getId());

        assertEquals(2, titulos.size());
        assertTrue(titulos.contains("El Aleph"));
        assertTrue(titulos.contains("Ficciones"));
    }
}
