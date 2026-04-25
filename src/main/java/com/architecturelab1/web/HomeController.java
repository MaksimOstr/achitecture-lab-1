package com.architecturelab1.web;

import com.architecturelab1.html.HtmlResponseBuilder;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HomeController {

    private final HtmlResponseBuilder htmlResponseBuilder;

    public HomeController(HtmlResponseBuilder htmlResponseBuilder) {
        this.htmlResponseBuilder = htmlResponseBuilder;
    }

    @GetMapping(path = "/", produces = MediaType.TEXT_HTML_VALUE)
    public String home() {
        return htmlResponseBuilder.renderHome();
    }
}
