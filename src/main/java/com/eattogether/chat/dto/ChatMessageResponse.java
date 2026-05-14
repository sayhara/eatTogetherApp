package com.eattogether.chat.dto;

import com.eattogether.chat.domain.ChatMessage;
import com.eattogether.chat.domain.MessageType;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class ChatMessageResponse {
    private Long id;
    private Long gatheringId;
    private Long senderId;
    private String senderNickname;
    private String senderProfileImageUrl;
    private String content;
    private MessageType type;
    private LocalDateTime createdAt;

    public static ChatMessageResponse from(ChatMessage message) {
        return ChatMessageResponse.builder()
                .id(message.getId())
                .gatheringId(message.getGatheringId())
                .senderId(message.getSender().getId())
                .senderNickname(message.getSender().getNickname())
                .senderProfileImageUrl(message.getSender().getProfileImageUrl())
                .content(message.getContent())
                .type(message.getType())
                .createdAt(message.getCreatedAt())
                .build();
    }

    // ENTER/LEAVE 시스템 메시지용
    public static ChatMessageResponse system(Long gatheringId, String content, MessageType type) {
        return ChatMessageResponse.builder()
                .gatheringId(gatheringId)
                .content(content)
                .type(type)
                .createdAt(LocalDateTime.now())
                .build();
    }
}
