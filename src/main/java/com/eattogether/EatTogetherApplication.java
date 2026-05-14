package com.eattogether;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class EatTogetherApplication {

    public static void main(String[] args) {
        SpringApplication.run(EatTogetherApplication.class, args);
    }
}
