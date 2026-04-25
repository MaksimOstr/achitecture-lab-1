package com.architecturelab1.model;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;

@Entity
@Table(name = "notes")
public class Note {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Schema(description = "Note id", example = "1")
    private Long id;

    @Column(nullable = false)
    @Schema(description = "Short note title", example = "Lab note")
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    @Schema(description = "Full note text", example = "Implementation details")
    private String content;

    @Column(name = "created_at", nullable = false)
    @Schema(description = "Creation timestamp", example = "2026-04-26T14:30:00+03:00")
    private OffsetDateTime createdAt;

    protected Note() {
    }

    public Note(String title, String content) {
        this.title = title;
        this.content = content;
    }

    @PrePersist
    void prePersist() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
    }

    public Long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getContent() {
        return content;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }
}
