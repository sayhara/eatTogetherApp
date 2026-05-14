package com.eattogether.gathering.repository;

import com.eattogether.gathering.domain.GatheringParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface GatheringParticipantRepository extends JpaRepository<GatheringParticipant, Long> {
    boolean existsByGatheringIdAndUserId(Long gatheringId, Long userId);
    Optional<GatheringParticipant> findByGatheringIdAndUserId(Long gatheringId, Long userId);
    long countByGatheringId(Long gatheringId);

    @Query("SELECT p FROM GatheringParticipant p JOIN FETCH p.user WHERE p.gathering.id = :gatheringId ORDER BY p.joinedAt ASC")
    List<GatheringParticipant> findByGatheringIdWithUser(@Param("gatheringId") Long gatheringId);

    @Query("SELECT p.user.id FROM GatheringParticipant p WHERE p.gathering.id = :gatheringId")
    List<Long> findUserIdsByGatheringId(@Param("gatheringId") Long gatheringId);
}
