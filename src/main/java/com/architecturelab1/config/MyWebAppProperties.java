package com.architecturelab1.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "mywebapp")
public record MyWebAppProperties(boolean migrateOnly) {
}
