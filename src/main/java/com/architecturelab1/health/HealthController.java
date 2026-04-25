package com.architecturelab1.health;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/health")
public class HealthController {

    @GetMapping(path = "/alive", produces = MediaType.TEXT_PLAIN_VALUE)
    public String alive() {
        return "OK";
    }

    @GetMapping(path = "/ready", produces = MediaType.TEXT_PLAIN_VALUE)
    public ResponseEntity<String> ready() {
        return ResponseEntity.ok("OK");
    }
}
