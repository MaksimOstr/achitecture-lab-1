package com.architecturelab1.notes;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import org.springframework.stereotype.Service;

@Service
public class NoteService {

    private final AtomicLong sequence = new AtomicLong();
    private final Map<Long, Note> notes = new ConcurrentHashMap<>();

    public List<NoteListItem> getNotes() {
        return notes.values().stream()
            .sorted((left, right) -> Long.compare(left.id(), right.id()))
            .map(note -> new NoteListItem(note.id(), note.title()))
            .toList();
    }

    public Note getNote(long id) {
        Note note = notes.get(id);
        if (note == null) {
            throw new NoteNotFoundException(id);
        }
        return note;
    }

    public Note createNote(String title, String content) {
        long id = sequence.incrementAndGet();
        Note note = new Note(id, title, content, OffsetDateTime.now());
        notes.put(id, note);
        return note;
    }
}
