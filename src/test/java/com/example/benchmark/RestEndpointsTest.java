package com.example.benchmark;

import com.example.benchmark.dto.AuthorCreateDto;
import com.example.benchmark.dto.BookCreateDto;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class RestEndpointsTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testCreateAuthor() throws Exception {
        AuthorCreateDto dto = new AuthorCreateDto("John", "Doe", 40);
        String json = mapper().writeValueAsString(dto);

        mockMvc.perform(post("/api/authors")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.firstName").value("John"))
                .andExpect(jsonPath("$.lastName").value("Doe"))
                .andExpect(jsonPath("$.age").value(40));
    }

    @Test
    void testCreateBookWithoutValidAuthors() throws Exception {
        BookCreateDto dto = new BookCreateDto("Test Book", "Description", List.of(999L));
        String json = mapper().writeValueAsString(dto);

        mockMvc.perform(post("/api/books")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
                .andExpect(status().isBadRequest());
    }

    @Test
    void testCreateBookWithValidAuthors() throws Exception {
        AuthorCreateDto authorDto = new AuthorCreateDto("Jane", "Smith", 35);
        String authorJson = mapper().writeValueAsString(authorDto);

        mockMvc.perform(post("/api/authors")
                .contentType(MediaType.APPLICATION_JSON)
                .content(authorJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty());

        BookCreateDto bookDto = new BookCreateDto("Test Book", "Description", List.of(1L));
        String bookJson = mapper().writeValueAsString(bookDto);

        mockMvc.perform(post("/api/books")
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.title").value("Test Book"))
                .andExpect(jsonPath("$.authors").exists());
    }

    @Test
    void testListAuthors() throws Exception {
        AuthorCreateDto dto = new AuthorCreateDto("Test", "Author", 50);
        String json = mapper().writeValueAsString(dto);

        mockMvc.perform(post("/api/authors")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json));

        mockMvc.perform(get("/api/authors"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    void testListBooks() throws Exception {
        AuthorCreateDto authorDto = new AuthorCreateDto("Author", "Test", 45);
        String authorJson = mapper().writeValueAsString(authorDto);

        mockMvc.perform(post("/api/authors")
                .contentType(MediaType.APPLICATION_JSON)
                .content(authorJson))
                .andExpect(status().isCreated());

        BookCreateDto bookDto = new BookCreateDto("Book One", "Desc", List.of(1L));
        String bookJson = mapper().writeValueAsString(bookDto);

        mockMvc.perform(post("/api/books")
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookJson))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/api/books"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    void testGetBookTitlesByAuthorId() throws Exception {
        AuthorCreateDto authorDto = new AuthorCreateDto("Book", "Author", 40);
        String authorJson = mapper().writeValueAsString(authorDto);

        mockMvc.perform(post("/api/authors")
                .contentType(MediaType.APPLICATION_JSON)
                .content(authorJson))
                .andExpect(status().isCreated());

        BookCreateDto bookDto1 = new BookCreateDto("Book One", "Desc1", List.of(1L));
        BookCreateDto bookDto2 = new BookCreateDto("Book Two", "Desc2", List.of(1L));

        String bookJson1 = mapper().writeValueAsString(bookDto1);
        String bookJson2 = mapper().writeValueAsString(bookDto2);

        mockMvc.perform(post("/api/books").contentType(MediaType.APPLICATION_JSON).content(bookJson1));
        mockMvc.perform(post("/api/books").contentType(MediaType.APPLICATION_JSON).content(bookJson2));

        mockMvc.perform(get("/api/books/author/1/titles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    private com.fasterxml.jackson.databind.ObjectMapper mapper() {
        return new com.fasterxml.jackson.databind.ObjectMapper();
    }
}
