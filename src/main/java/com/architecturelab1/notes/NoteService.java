package com.architecturelab1.notes;

import java.util.List;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class NoteService {

    private final NoteRepository noteRepository;

    public NoteService(NoteRepository noteRepository) {
        this.noteRepository = noteRepository;
    }

    public List<NoteListItem> getNotes() {
        return noteRepository.findAll(Sort.by(Sort.Direction.ASC, "id")).stream()
            .map(NoteListItem::from)
            .toList();
    }

    public Note getNote(long id) {
        return noteRepository.findById(id).orElseThrow(() -> new NoteNotFoundException(id));
    }

    @Transactional
    public Note createNote(String title, String content) {
        return noteRepository.save(new Note(title, content));
    }
}
