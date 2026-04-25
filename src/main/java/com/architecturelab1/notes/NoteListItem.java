package com.architecturelab1.notes;

public record NoteListItem(
    long id,
    String title
) {
    public static NoteListItem from(Note note) {
        return new NoteListItem(note.getId(), note.getTitle());
    }
}
