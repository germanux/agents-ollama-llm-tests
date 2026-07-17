package com.example.library.repository;

import com.example.library.entity.Author;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AuthorRepository extends JpaRepository<Author, Long> {

    @Query("SELECT b.titulo FROM Book b JOIN b.authors a WHERE a.nombre = :nombre")
    List<String> findBookTitlesByNombre(@Param("nombre") String nombre);
}
