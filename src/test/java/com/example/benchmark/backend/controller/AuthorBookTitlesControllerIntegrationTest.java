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
class AuthorBookTitlesControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testGetBookTitlesByAuthorId() throws Exception {
        // Create an author and books
        mockMvc.perform(post("/api/authors")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"George\",\"lastName\":\"Orwell\",\"age\":46}"))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/books")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"1984\",\"argument\":\"Dystopian\",\"genre\":\"Fiction\",\"authorIds\":[1]}"))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/books")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Animal Farm\",\"argument\":\"Allegory\",\"genre\":\"Fiction\",\"authorIds\":[1]}"))
                .andExpect(status().isCreated());

        // Get book titles by author ID
        var result = mockMvc.perform(get("/api/authors/1/book-titles"))
                .andExpect(status().isOk())
                .andReturn();

        var content = result.getResponse().getContentAsString();
        org.junit.jupiter.api.Assertions.assertTrue(content.contains("\"1984\""), "Response should contain first book title");
        org.junit.jupiter.api.Assertions.assertTrue(content.contains("\"Animal Farm\""), "Response should contain second book title");
    }

    @Test
    void testGetBookTitlesForMissingAuthorReturns404() throws Exception {
        mockMvc.perform(get("/api/authors/999/book-titles"))
                .andExpect(status().isNotFound());
    }
}
