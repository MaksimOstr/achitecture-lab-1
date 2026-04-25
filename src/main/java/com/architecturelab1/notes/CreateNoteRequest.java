package com.architecturelab1.notes;

import jakarta.validation.constraints.NotBlank;

public record CreateNoteRequest(
    @NotBlank String title,
    @NotBlank String content
) {
}
