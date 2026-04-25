package com.architecturelab1.notes;

import com.architecturelab1.html.HtmlResponseBuilder;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/notes")
public class NotesController {

    private final NoteService noteService;
    private final HtmlResponseBuilder htmlResponseBuilder;

    public NotesController(NoteService noteService, HtmlResponseBuilder htmlResponseBuilder) {
        this.noteService = noteService;
        this.htmlResponseBuilder = htmlResponseBuilder;
    }

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public List<NoteListItem> getNotesJson() {
        return noteService.getNotes();
    }

    @GetMapping(produces = MediaType.TEXT_HTML_VALUE)
    public String getNotesHtml() {
        return htmlResponseBuilder.renderNotes(noteService.getNotes());
    }

    @GetMapping(path = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Note getNoteJson(@PathVariable long id) {
        return noteService.getNote(id);
    }

    @GetMapping(path = "/{id}", produces = MediaType.TEXT_HTML_VALUE)
    public String getNoteHtml(@PathVariable long id) {
        return htmlResponseBuilder.renderNote(noteService.getNote(id));
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Note> createJson(@Valid @RequestBody CreateNoteRequest request) {
        Note note = noteService.createNote(request.title(), request.content());
        return ResponseEntity.created(URI.create("/notes/" + note.id())).body(note);
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> createJsonHtml(@Valid @RequestBody CreateNoteRequest request) {
        Note note = noteService.createNote(request.title(), request.content());
        return ResponseEntity.created(URI.create("/notes/" + note.id())).body(htmlResponseBuilder.renderNote(note));
    }

    @PostMapping(consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Note> createFormJson(@Valid @ModelAttribute CreateNoteForm form) {
        Note note = noteService.createNote(form.title(), form.content());
        return ResponseEntity.created(URI.create("/notes/" + note.id())).body(note);
    }

    @PostMapping(consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE, produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> createFormHtml(@Valid @ModelAttribute CreateNoteForm form) {
        Note note = noteService.createNote(form.title(), form.content());
        return ResponseEntity.created(URI.create("/notes/" + note.id())).body(htmlResponseBuilder.renderNote(note));
    }
}
