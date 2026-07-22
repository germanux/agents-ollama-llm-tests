package com.example.benchmark.backend.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class BookControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testCreateBookWithExistingAuthorsReturns201() throws Exception {
        // First create authors
        mockMvc.perform(post("/api/authors")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"John\",\"lastName\":\"Doe\",\"age\":35}"))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/authors")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"Jane\",\"lastName\":\"Smith\",\"age\":42}"))
                .andExpect(status().isCreated());

        // Then create a book with both authors
        mockMvc.perform(post("/api/books")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Spring Boot Guide\",\"description\":\"A comprehensive guide\",\"authorIds\":[1,2]}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.title").value("Spring Boot Guide"))
                .andExpect(jsonPath("$.description").value("A comprehensive guide"));
    }

    @Test
    void testCreateBookWithMissingAuthorIdReturns404() throws Exception {
        // Create one author first
        mockMvc.perform(post("/api/authors")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"John\",\"lastName\":\"Doe\",\"age\":35}"))
                .andExpect(status().isCreated());

        // Try to create a book with a non-existent author ID
        mockMvc.perform(post("/api/books")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Test Book\",\"description\":\"A test\",\"authorIds\":[1,999]}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void testListBooksReturnsBooksAndAuthors() throws Exception {
        // Create authors and a book
        mockMvc.perform(post("/api/authors")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"John\",\"lastName\":\"Doe\",\"age\":35}"))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/books")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Spring Boot Guide\",\"description\":\"A guide\",\"authorIds\":[1]}"))
                .andExpect(status().isCreated());

        // List books - verify response contains the book
        var result = mockMvc.perform(get("/api/books"))
                .andExpect(status().isOk())
                .andReturn();

        result.getResponse().getContentAsString().contains("\"title\":\"Spring Boot Guide\"");
    }
}
