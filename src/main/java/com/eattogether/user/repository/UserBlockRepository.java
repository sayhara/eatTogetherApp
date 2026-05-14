package com.eattogether.user.repository;

import com.eattogether.user.domain.UserBlock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserBlockRepository extends JpaRepository<UserBlock, Long> {

    boolean existsByBlockerIdAndBlockedId(Long blockerId, Long blockedId);

    Optional<UserBlock> findByBlockerIdAndBlockedId(Long blockerId, Long blockedId);

    @Query("SELECT b.blockedId FROM UserBlock b WHERE b.blockerId = :userId")
    List<Long> findBlockedIdsByBlockerId(@Param("userId") Long userId);

    @Query("SELECT b.blockerId FROM UserBlock b WHERE b.blockedId = :userId")
    List<Long> findBlockerIdsByBlockedId(@Param("userId") Long userId);

    @Query("SELECT b FROM UserBlock b WHERE b.blockerId = :userId ORDER BY b.createdAt DESC")
    List<UserBlock> findByBlockerIdOrderByCreatedAtDesc(@Param("userId") Long userId);
}
