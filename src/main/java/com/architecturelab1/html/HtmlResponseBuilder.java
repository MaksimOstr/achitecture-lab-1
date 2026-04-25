package com.architecturelab1.html;

import com.architecturelab1.notes.Note;
import com.architecturelab1.notes.NoteListItem;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class HtmlResponseBuilder {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public String renderHome() {
        return """
            <html>
            <head><title>mywebapp</title></head>
            <body>
            <h1>mywebapp</h1>
            <ul>
            <li>GET /notes</li>
            <li>POST /notes</li>
            <li>GET /notes/{id}</li>
            </ul>
            </body>
            </html>
            """;
    }

    public String renderNotes(List<NoteListItem> notes) {
        StringBuilder builder = new StringBuilder();
        builder.append("<html><head><title>Notes</title></head><body><h1>Notes</h1><table border=\"1\"><thead><tr><th>id</th><th>title</th></tr></thead><tbody>");
        for (NoteListItem note : notes) {
            builder.append("<tr><td>").append(note.id()).append("</td><td>").append(escape(note.title())).append("</td></tr>");
        }
        builder.append("</tbody></table></body></html>");
        return builder.toString();
    }

    public String renderNote(Note note) {
        return "<html><head><title>Note</title></head><body><h1>Note</h1><dl><dt>id</dt><dd>" + note.getId()
            + "</dd><dt>title</dt><dd>" + escape(note.getTitle())
            + "</dd><dt>created_at</dt><dd>" + FORMATTER.format(note.getCreatedAt())
            + "</dd><dt>content</dt><dd>" + escape(note.getContent())
            + "</dd></dl></body></html>";
    }

    private String escape(String value) {
        return value
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#39;");
    }
}
