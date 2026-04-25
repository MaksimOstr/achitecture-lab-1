package com.architecturelab1.notes;

import java.time.OffsetDateTime;

public record Note(
    long id,
    String title,
    String content,
    OffsetDateTime createdAt
) {
}
