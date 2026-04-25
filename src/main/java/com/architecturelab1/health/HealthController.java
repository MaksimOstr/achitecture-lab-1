package com.architecturelab1.health;

import javax.sql.DataSource;
import org.springframework.http.MediaType;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/health")
public class HealthController {

    private final JdbcClient jdbcClient;

    public HealthController(DataSource dataSource) {
        this.jdbcClient = JdbcClient.create(dataSource);
    }

    @GetMapping(path = "/alive", produces = MediaType.TEXT_PLAIN_VALUE)
    public String alive() {
        return "OK";
    }

    @GetMapping(path = "/ready", produces = MediaType.TEXT_PLAIN_VALUE)
    public ResponseEntity<String> ready() {
        try {
            Integer result = jdbcClient.sql("SELECT 1").query(Integer.class).single();
            if (result == 1) {
                return ResponseEntity.ok("OK");
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Database probe returned unexpected result");
        } catch (Exception exception) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Database is unavailable");
        }
    }
}
