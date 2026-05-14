package com.eattogether.fcm.service;

import com.eattogether.fcm.domain.FcmToken;
import com.eattogether.fcm.dto.FcmTokenRequest;
import com.eattogether.fcm.repository.FcmTokenRepository;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FcmService {

    private final FcmTokenRepository fcmTokenRepository;

    @Transactional
    public void registerToken(Long userId, FcmTokenRequest request) {
        FcmToken fcmToken = fcmTokenRepository
                .findByUserIdAndDeviceId(userId, request.getDeviceId())
                .orElseGet(() -> fcmTokenRepository.save(FcmToken.builder()
                        .userId(userId)
                        .token(request.getToken())
                        .deviceId(request.getDeviceId())
                        .build()));
        fcmToken.updateToken(request.getToken());
    }

    public void sendToUser(Long userId, String title, String body) {
        List<String> tokens = fcmTokenRepository.findTokensByUserId(userId);
        if (tokens.isEmpty()) return;
        sendMulticast(tokens, title, body);
    }

    public void sendToUsers(List<Long> userIds, String title, String body) {
        List<String> tokens = fcmTokenRepository.findTokensByUserIds(userIds);
        if (tokens.isEmpty()) return;
        sendMulticast(tokens, title, body);
    }

    private void sendMulticast(List<String> tokens, String title, String body) {
        if (FirebaseApp.getApps().isEmpty()) return;
        try {
            List<String> batch = tokens.size() > 500 ? tokens.subList(0, 500) : tokens;
            MulticastMessage message = MulticastMessage.builder()
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .addAllTokens(batch)
                    .build();
            FirebaseMessaging.getInstance().sendEachForMulticast(message);
        } catch (Exception e) {
            log.warn("FCM 전송 실패: {}", e.getMessage());
        }
    }
}
