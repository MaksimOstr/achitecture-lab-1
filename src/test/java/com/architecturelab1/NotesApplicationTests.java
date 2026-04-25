package com.architecturelab1;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
class NotesApplicationTests {

    @org.springframework.beans.factory.annotation.Autowired
    private WebApplicationContext context;

    @org.springframework.beans.factory.annotation.Autowired
    private JdbcTemplate jdbcTemplate;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).build();
        jdbcTemplate.execute("TRUNCATE TABLE notes RESTART IDENTITY");
    }

    @Test
    void homeReturnsHtmlOnly() throws Exception {
        mockMvc.perform(get("/").accept(MediaType.TEXT_HTML))
            .andExpect(status().isOk())
            .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
            .andExpect(content().string(org.hamcrest.Matchers.containsString("GET /notes")));
    }

    @Test
    void healthEndpointsWork() throws Exception {
        mockMvc.perform(get("/health/alive"))
            .andExpect(status().isOk())
            .andExpect(content().string("OK"));

        mockMvc.perform(get("/health/ready"))
            .andExpect(status().isOk())
            .andExpect(content().string("OK"));
    }

    @Test
    void notesSupportJsonFlow() throws Exception {
        mockMvc.perform(post("/notes")
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "title": "Lab note",
                      "content": "Implementation"
                    }
                    """))
            .andExpect(status().isCreated())
            .andExpect(header().string("Location", "/notes/1"))
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.title").value("Lab note"))
            .andExpect(jsonPath("$.content").value("Implementation"));

        mockMvc.perform(get("/notes").accept(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].id").value(1))
            .andExpect(jsonPath("$[0].title").value("Lab note"));

        mockMvc.perform(get("/notes/1").accept(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.title").value("Lab note"))
            .andExpect(jsonPath("$.content").value("Implementation"));
    }

    @Test
    void notesSupportHtmlResponses() throws Exception {
        mockMvc.perform(post("/notes")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .accept(MediaType.TEXT_HTML)
                .param("title", "HTML note")
                .param("content", "Rendered"))
            .andExpect(status().isCreated())
            .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
            .andExpect(content().string(org.hamcrest.Matchers.containsString("HTML note")));

        mockMvc.perform(get("/notes").accept(MediaType.TEXT_HTML))
            .andExpect(status().isOk())
            .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
            .andExpect(content().string(org.hamcrest.Matchers.containsString("<table")));
    }
}
