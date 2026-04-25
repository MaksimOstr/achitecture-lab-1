package com.architecturelab1.notes;

import io.swagger.v3.oas.annotations.media.Schema;

public record NoteListItem(
    @Schema(description = "Note id", example = "1")
    long id,
    @Schema(description = "Short note title", example = "Lab note")
    String title
) {
    public static NoteListItem from(Note note) {
        return new NoteListItem(note.getId(), note.getTitle());
    }
}
