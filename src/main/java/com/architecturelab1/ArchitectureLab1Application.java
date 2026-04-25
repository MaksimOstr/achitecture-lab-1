package com.architecturelab1;

import com.architecturelab1.config.MyWebAppProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(MyWebAppProperties.class)
public class ArchitectureLab1Application {

    public static void main(String[] args) {
        SpringApplication.run(ArchitectureLab1Application.class, args);
    }

}
