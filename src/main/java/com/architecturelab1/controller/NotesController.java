package com.architecturelab1.controller;

import com.architecturelab1.model.CreateNoteForm;
import com.architecturelab1.model.CreateNoteRequest;
import com.architecturelab1.model.Note;
import com.architecturelab1.model.NoteListItem;
import com.architecturelab1.service.HtmlResponseBuilder;
import com.architecturelab1.service.NoteService;
import io.swagger.v3.oas.annotations.Hidden;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/notes")
@Tag(name = "Notes", description = "Operations for creating and reading notes")
public class NotesController {

    private final NoteService noteService;
    private final HtmlResponseBuilder htmlResponseBuilder;

    public NotesController(NoteService noteService, HtmlResponseBuilder htmlResponseBuilder) {
        this.noteService = noteService;
        this.htmlResponseBuilder = htmlResponseBuilder;
    }

    @Operation(summary = "List notes", description = "Returns all notes with id and title")
    @ApiResponse(
        responseCode = "200",
        description = "Notes returned",
        content = {
            @Content(mediaType = MediaType.APPLICATION_JSON_VALUE, schema = @Schema(type = "array", implementation = NoteListItem.class)),
            @Content(mediaType = MediaType.TEXT_HTML_VALUE, schema = @Schema(type = "string"), examples = @ExampleObject(value = "<html><body><table><tr><th>id</th><th>title</th></tr><tr><td>1</td><td>Lab note</td></tr></table></body></html>"))
        }
    )
    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public List<NoteListItem> getNotesJson() {
        return noteService.getNotes();
    }

    @Hidden
    @GetMapping(produces = MediaType.TEXT_HTML_VALUE)
    public String getNotesHtml() {
        return htmlResponseBuilder.renderNotes(noteService.getNotes());
    }

    @Operation(summary = "Get note by id", description = "Returns the full note by id")
    @ApiResponses({
        @ApiResponse(
            responseCode = "200",
            description = "Note returned",
            content = {
                @Content(mediaType = MediaType.APPLICATION_JSON_VALUE, schema = @Schema(implementation = Note.class)),
                @Content(mediaType = MediaType.TEXT_HTML_VALUE, schema = @Schema(type = "string"), examples = @ExampleObject(value = "<html><body><dl><dt>id</dt><dd>1</dd><dt>title</dt><dd>Lab note</dd><dt>created_at</dt><dd>2026-04-26 14:30:00</dd><dt>content</dt><dd>Implementation details</dd></dl></body></html>"))
            }
        ),
        @ApiResponse(responseCode = "404", description = "Note not found", content = @Content(schema = @Schema(hidden = true)))
    })
    @GetMapping(path = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Note getNoteJson(@Parameter(description = "Note id", example = "1") @PathVariable long id) {
        return noteService.getNote(id);
    }

    @Hidden
    @GetMapping(path = "/{id}", produces = MediaType.TEXT_HTML_VALUE)
    public String getNoteHtml(@PathVariable long id) {
        return htmlResponseBuilder.renderNote(noteService.getNote(id));
    }

    @Operation(
        summary = "Create note",
        description = "Creates a new note from JSON or form input",
        requestBody = @RequestBody(
            required = true,
            content = {
                @Content(mediaType = MediaType.APPLICATION_JSON_VALUE, schema = @Schema(implementation = CreateNoteRequest.class)),
                @Content(mediaType = MediaType.APPLICATION_FORM_URLENCODED_VALUE, schema = @Schema(implementation = CreateNoteForm.class))
            }
        )
    )
    @ApiResponses({
        @ApiResponse(
            responseCode = "201",
            description = "Note created",
            content = {
                @Content(mediaType = MediaType.APPLICATION_JSON_VALUE, schema = @Schema(implementation = Note.class)),
                @Content(mediaType = MediaType.TEXT_HTML_VALUE, schema = @Schema(type = "string"), examples = @ExampleObject(value = "<html><body><dl><dt>id</dt><dd>1</dd><dt>title</dt><dd>Lab note</dd><dt>created_at</dt><dd>2026-04-26 14:30:00</dd><dt>content</dt><dd>Implementation details</dd></dl></body></html>"))
            }
        ),
        @ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(hidden = true)))
    })
    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Note> createJson(@Valid @org.springframework.web.bind.annotation.RequestBody CreateNoteRequest request) {
        Note note = noteService.createNote(request.getTitle(), request.getContent());
        return ResponseEntity.created(URI.create("/notes/" + note.getId())).body(note);
    }

    @Hidden
    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> createJsonHtml(@Valid @org.springframework.web.bind.annotation.RequestBody CreateNoteRequest request) {
        Note note = noteService.createNote(request.getTitle(), request.getContent());
        return ResponseEntity.created(URI.create("/notes/" + note.getId())).body(htmlResponseBuilder.renderNote(note));
    }

    @Hidden
    @PostMapping(consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Note> createFormJson(@Valid @ModelAttribute CreateNoteForm form) {
        Note note = noteService.createNote(form.getTitle(), form.getContent());
        return ResponseEntity.created(URI.create("/notes/" + note.getId())).body(note);
    }

    @Hidden
    @PostMapping(consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE, produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> createFormHtml(@Valid @ModelAttribute CreateNoteForm form) {
        Note note = noteService.createNote(form.getTitle(), form.getContent());
        return ResponseEntity.created(URI.create("/notes/" + note.getId())).body(htmlResponseBuilder.renderNote(note));
    }
}
