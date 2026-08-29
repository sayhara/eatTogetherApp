package com.eattogether.legal.controller;

import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

@RestController
public class LegalPageController {

    @GetMapping("/privacy")
    public ResponseEntity<String> privacy() throws IOException {
        return htmlPage("legal/privacy.html");
    }

    @GetMapping("/delete-account")
    public ResponseEntity<String> deleteAccount() throws IOException {
        return htmlPage("legal/delete-account.html");
    }

    @GetMapping("/child-safety-standards")
    public ResponseEntity<String> childSafetyStandards() throws IOException {
        return htmlPage("legal/child-safety-standards.html");
    }

    private ResponseEntity<String> htmlPage(String classpathLocation) throws IOException {
        String html = new String(
                new ClassPathResource(classpathLocation).getInputStream().readAllBytes(),
                StandardCharsets.UTF_8
        );
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE + ";charset=UTF-8")
                .body(html);
    }
}
