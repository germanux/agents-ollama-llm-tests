package com.example.librosautores.repository;

import com.example.librosautores.entity.Libro;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LibroRepository extends JpaRepository<Libro, Long> {

    @Query("SELECT l FROM Libro l JOIN l.autores a WHERE a.id = :autorId")
    List<Libro> findLibrosByAutorId(Long autorId);
}
