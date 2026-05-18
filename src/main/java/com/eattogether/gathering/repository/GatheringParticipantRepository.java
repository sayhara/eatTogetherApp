package com.eattogether.gathering.repository;

import com.eattogether.gathering.domain.GatheringParticipant;
import com.eattogether.gathering.domain.ParticipantStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface GatheringParticipantRepository extends JpaRepository<GatheringParticipant, Long> {
    boolean existsByGatheringIdAndUserId(Long gatheringId, Long userId);
    Optional<GatheringParticipant> findByGatheringIdAndUserId(Long gatheringId, Long userId);
    long countByGatheringIdAndStatus(Long gatheringId, ParticipantStatus status);

    @Query("SELECT p FROM GatheringParticipant p JOIN FETCH p.user WHERE p.gathering.id = :gatheringId AND p.status = :status ORDER BY p.joinedAt ASC")
    List<GatheringParticipant> findByGatheringIdAndStatusWithUser(
            @Param("gatheringId") Long gatheringId,
            @Param("status") ParticipantStatus status);

    // ChatService에서 FCM 발송 대상 조회 (APPROVED만)
    @Query("SELECT p.user.id FROM GatheringParticipant p WHERE p.gathering.id = :gatheringId AND p.status = :status")
    List<Long> findUserIdsByGatheringId(@Param("gatheringId") Long gatheringId, @Param("status") ParticipantStatus status);
}
