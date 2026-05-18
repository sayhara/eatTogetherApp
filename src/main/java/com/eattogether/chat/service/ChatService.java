package com.eattogether.chat.service;

import com.eattogether.chat.domain.ChatMessage;
import com.eattogether.chat.domain.ChatReadStatus;
import com.eattogether.chat.domain.MessageType;
import com.eattogether.chat.dto.ChatMessageRequest;
import com.eattogether.chat.dto.ChatMessageResponse;
import com.eattogether.chat.dto.UnreadCountResponse;
import com.eattogether.chat.repository.ChatMessageRepository;
import com.eattogether.chat.repository.ChatReadStatusRepository;
import com.eattogether.common.exception.BusinessException;
import com.eattogether.common.exception.ErrorCode;
import com.eattogether.fcm.service.FcmService;
import com.eattogether.gathering.domain.ParticipantStatus;
import com.eattogether.gathering.repository.GatheringParticipantRepository;
import com.eattogether.user.domain.User;
import com.eattogether.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final ChatReadStatusRepository readStatusRepository;
    private final UserRepository userRepository;
    private final GatheringParticipantRepository participantRepository;
    private final FcmService fcmService;

    @Transactional
    public ChatMessageResponse saveMessage(Long gatheringId, Long senderId, ChatMessageRequest request) {
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

        ChatMessage message = chatMessageRepository.save(ChatMessage.builder()
                .gatheringId(gatheringId)
                .sender(sender)
                .content(request.getContent())
                .type(MessageType.TALK)
                .build());

        List<Long> otherIds = participantRepository.findUserIdsByGatheringId(gatheringId, ParticipantStatus.APPROVED).stream()
                .filter(id -> !id.equals(senderId))
                .collect(Collectors.toList());
        if (!otherIds.isEmpty()) {
            fcmService.sendToUsers(otherIds, sender.getNickname(), request.getContent());
        }

        return ChatMessageResponse.from(message);
    }

    public List<ChatMessageResponse> getChatHistory(Long gatheringId, int page, int size) {
        return chatMessageRepository
                .findByGatheringId(gatheringId, PageRequest.of(page, size))
                .stream()
                .map(ChatMessageResponse::from)
                .collect(Collectors.toList());
    }

    public ChatMessageResponse buildEnterMessage(Long gatheringId, Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        return ChatMessageResponse.system(gatheringId, user.getNickname() + "님이 입장했습니다.", MessageType.ENTER);
    }

    @Transactional
    public void markAsRead(Long userId, Long gatheringId) {
        ChatReadStatus status = readStatusRepository
                .findByUserIdAndGatheringId(userId, gatheringId)
                .orElseGet(() -> readStatusRepository.save(ChatReadStatus.builder()
                        .userId(userId)
                        .gatheringId(gatheringId)
                        .build()));
        status.updateReadAt();
    }

    public UnreadCountResponse getUnreadCount(Long userId, Long gatheringId) {
        LocalDateTime lastReadAt = readStatusRepository
                .findByUserIdAndGatheringId(userId, gatheringId)
                .map(ChatReadStatus::getLastReadAt)
                .orElse(LocalDateTime.MIN);
        long count = chatMessageRepository.countByGatheringIdAndCreatedAtAfter(gatheringId, lastReadAt);
        return new UnreadCountResponse(gatheringId, count);
    }
}
