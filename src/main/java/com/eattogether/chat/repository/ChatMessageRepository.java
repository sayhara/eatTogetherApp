package com.eattogether.chat.repository;

import com.eattogether.chat.domain.ChatMessage;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    @Query("""
        SELECT m FROM ChatMessage m
        JOIN FETCH m.sender
        WHERE m.gatheringId = :gatheringId
        ORDER BY m.createdAt ASC
        """)
    List<ChatMessage> findByGatheringId(@Param("gatheringId") Long gatheringId, Pageable pageable);

    long countByGatheringIdAndCreatedAtAfter(Long gatheringId, LocalDateTime after);
}
