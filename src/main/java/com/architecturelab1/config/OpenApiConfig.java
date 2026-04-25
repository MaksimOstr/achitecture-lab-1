package com.architecturelab1.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI myWebAppOpenApi() {
        return new OpenAPI()
            .info(new Info()
                .title("mywebapp Notes API")
                .version("1.0")
                .description("Interactive API documentation for the notes service"));
    }
}
