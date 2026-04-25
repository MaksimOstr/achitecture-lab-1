package com.architecturelab1.config;

import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.stereotype.Component;

@Component
public class MigrationOnlyRunner implements ApplicationRunner {

    private final MyWebAppProperties properties;
    private final DataSource dataSource;
    private final ConfigurableApplicationContext context;

    public MigrationOnlyRunner(MyWebAppProperties properties, DataSource dataSource, ConfigurableApplicationContext context) {
        this.properties = properties;
        this.dataSource = dataSource;
        this.context = context;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!properties.migrateOnly()) {
            return;
        }
        Flyway flyway = Flyway.configure().dataSource(dataSource).load();
        flyway.migrate();
        int exitCode = SpringApplication.exit(context, () -> 0);
        System.exit(exitCode);
    }
}
