package com.eattogether.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${firebase.credentials-json:}")
    private String credentialsJson;

    @PostConstruct
    public void initialize() {
        if (credentialsJson == null || credentialsJson.isBlank()) {
            log.warn("Firebase 설정 없음 — FCM 푸시 알림이 비활성화됩니다. (firebase.credentials-json 환경변수 설정 필요)");
            return;
        }
        try {
            if (!FirebaseApp.getApps().isEmpty()) return;

            InputStream stream = new ByteArrayInputStream(credentialsJson.getBytes(StandardCharsets.UTF_8));
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(stream))
                    .build();
            FirebaseApp.initializeApp(options);
            log.info("Firebase 초기화 완료");
        } catch (IOException e) {
            log.error("Firebase 초기화 실패: {}", e.getMessage());
        }
    }
}
