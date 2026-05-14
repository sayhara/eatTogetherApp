package com.eattogether.chat.service;

import com.eattogether.chat.dto.ChatMessageResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class ChatSubscriber implements MessageListener {

    private final SimpMessagingTemplate messagingTemplate;
    private final ObjectMapper objectMapper;

    @Override
    public void onMessage(Message message, byte[] pattern) {
        try {
            ChatMessageResponse response = objectMapper.readValue(message.getBody(), ChatMessageResponse.class);
            messagingTemplate.convertAndSend("/topic/gathering/" + response.getGatheringId(), response);
        } catch (Exception e) {
            log.error("채팅 메시지 역직렬화 실패: {}", e.getMessage());
        }
    }
}
