package com.architecturelab1.notes;

import jakarta.validation.constraints.NotBlank;

public record CreateNoteForm(
    @NotBlank String title,
    @NotBlank String content
) {
}
