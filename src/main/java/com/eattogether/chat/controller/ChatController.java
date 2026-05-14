package com.eattogether.chat.controller;

import com.eattogether.chat.dto.ChatMessageRequest;
import com.eattogether.chat.dto.ChatMessageResponse;
import com.eattogether.chat.dto.UnreadCountResponse;
import com.eattogether.chat.service.ChatPublisher;
import com.eattogether.chat.service.ChatService;
import com.eattogether.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@Slf4j
@RestController
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;
    private final ChatPublisher chatPublisher;
    private final SimpMessagingTemplate messagingTemplate;

    @MessageMapping("/chat/{gatheringId}")
    public void sendMessage(@DestinationVariable Long gatheringId,
                            @Payload ChatMessageRequest request,
                            Principal principal) {
        Long userId = Long.parseLong(principal.getName());
        // DB 저장 후 Redis 채널에 발행 → ChatSubscriber가 받아 WebSocket으로 브로드캐스트
        ChatMessageResponse response = chatService.saveMessage(gatheringId, userId, request);
        chatPublisher.publish(gatheringId, response);
        log.debug("Chat message published: gatheringId={}, userId={}", gatheringId, userId);
    }

    @MessageMapping("/chat/{gatheringId}/enter")
    public void enterGathering(@DestinationVariable Long gatheringId, Principal principal) {
        Long userId = Long.parseLong(principal.getName());
        ChatMessageResponse response = chatService.buildEnterMessage(gatheringId, userId);
        // 입장 메시지는 시스템 메시지로 Redis Pub/Sub 없이 직접 전송
        messagingTemplate.convertAndSend("/topic/gathering/" + gatheringId, response);
    }

    @GetMapping("/api/chat/{gatheringId}/history")
    public ApiResponse<List<ChatMessageResponse>> getChatHistory(
            @PathVariable Long gatheringId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ApiResponse.ok(chatService.getChatHistory(gatheringId, page, size));
    }

    @PostMapping("/api/chat/{gatheringId}/read")
    public ApiResponse<Void> markAsRead(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId) {
        Long userId = Long.parseLong(userDetails.getUsername());
        chatService.markAsRead(userId, gatheringId);
        return ApiResponse.ok(null);
    }

    @GetMapping("/api/chat/{gatheringId}/unread")
    public ApiResponse<UnreadCountResponse> getUnreadCount(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return ApiResponse.ok(chatService.getUnreadCount(userId, gatheringId));
    }
}
