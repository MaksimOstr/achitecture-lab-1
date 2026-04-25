package com.architecturelab1.model;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CreateNoteRequest {

    @Schema(description = "Short note title", example = "Lab note")
    @NotBlank
    private String title;

    @Schema(description = "Full note text", example = "Implementation details")
    @NotBlank
    private String content;
}
