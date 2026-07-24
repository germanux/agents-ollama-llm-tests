package com.example.benchmark.backend.controller;

import org.springframework.core.io.ClassPathResource;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.stream.Collectors;

@Controller
public class FrontendController {

    @GetMapping("/")
    public ResponseEntity<String> index() throws IOException {
        ClassPathResource resource = new ClassPathResource("META-INF/resources/index.html");
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
            String content = reader.lines().collect(Collectors.joining("\n"));
            return ResponseEntity.ok().contentType(org.springframework.http.MediaType.TEXT_HTML).body(content);
        }
    }
}
