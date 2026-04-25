package com.architecturelab1.exception;

public class NoteNotFoundException extends RuntimeException {

    public NoteNotFoundException(long id) {
        super("Note %d was not found".formatted(id));
    }
}
