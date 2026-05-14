package com.eattogether.chat.repository;

import com.eattogether.chat.domain.ChatReadStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ChatReadStatusRepository extends JpaRepository<ChatReadStatus, Long> {
    Optional<ChatReadStatus> findByUserIdAndGatheringId(Long userId, Long gatheringId);
}
