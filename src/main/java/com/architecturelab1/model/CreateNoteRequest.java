package com.architecturelab1.model;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

public record CreateNoteRequest(
    @Schema(description = "Short note title", example = "Lab note")
    @NotBlank String title,
    @Schema(description = "Full note text", example = "Implementation details")
    @NotBlank String content
) {
}
