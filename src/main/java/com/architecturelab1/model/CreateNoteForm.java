package com.architecturelab1.model;

import jakarta.validation.constraints.NotBlank;

public record CreateNoteForm(
    @NotBlank String title,
    @NotBlank String content
) {
}
