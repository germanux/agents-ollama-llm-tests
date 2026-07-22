package com.example.benchmark.backend.controller;

import org.springframework.core.io.ClassPathResource;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import java.nio.file.Files;
import java.nio.file.Path;

@Controller
public class FrontendController {

    @GetMapping("/")
    public ResponseEntity<String> index() throws Exception {
        ClassPathResource resource = new ClassPathResource("static/browser/index.html");
        String content = Files.readString(Path.of(resource.getURI()));
        return ResponseEntity.ok().contentType(org.springframework.http.MediaType.TEXT_HTML).body(content);
    }
}
