package com.architecturelab1.model;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class NoteListItem {

    @Schema(description = "Note id", example = "1")
    private final long id;

    @Schema(description = "Short note title", example = "Lab note")
    private final String title;

    public static NoteListItem from(Note note) {
        return new NoteListItem(note.getId(), note.getTitle());
    }
}
