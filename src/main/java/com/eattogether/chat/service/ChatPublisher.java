package com.eattogether.chat.service;

import com.eattogether.chat.dto.ChatMessageResponse;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class ChatPublisher {

    private static final String CHANNEL_PREFIX = "chat:gathering:";

    private final RedisTemplate<String, String> redisTemplate;
    private final ObjectMapper objectMapper;

    public void publish(Long gatheringId, ChatMessageResponse message) {
        try {
            String json = objectMapper.writeValueAsString(message);
            redisTemplate.convertAndSend(CHANNEL_PREFIX + gatheringId, json);
        } catch (JsonProcessingException e) {
            log.error("채팅 메시지 직렬화 실패: {}", e.getMessage());
        }
    }
}
