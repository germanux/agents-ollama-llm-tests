package com.example.librosautores.service;

import com.example.librosautores.entity.Autor;
import com.example.librosautores.entity.Libro;
import com.example.librosautores.repository.AutorRepository;
import com.example.librosautores.repository.LibroRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class LibroServicio {

    private final LibroRepository libroRepository;
    private final AutorRepository autorRepository;

    public LibroServicio(LibroRepository libroRepository, AutorRepository autorRepository) {
        this.libroRepository = libroRepository;
        this.autorRepository = autorRepository;
    }

    /**
     * Crea un libro y lo asocia a uno o varios autores.
     */
    public Libro crearLibroConAutores(String titulo, String descripcion, List<Autor> autores) {
        Libro libro = new Libro(titulo, descripcion);
        for (Autor autor : autores) {
            autor.addLibro(libro);
        }
        return libroRepository.save(libro);
    }

    /**
     * Obtiene los títulos de todos los libros de un autor dado su id.
     */
    @Transactional(readOnly = true)
    public List<String> obtenerTitulosPorAutor(Long autorId) {
        return libroRepository.findLibrosByAutorId(autorId).stream()
                .map(Libro::getTitulo)
                .toList();
    }
}
