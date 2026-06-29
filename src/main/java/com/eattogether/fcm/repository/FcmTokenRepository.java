package com.eattogether.fcm.repository;

import com.eattogether.fcm.domain.FcmToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FcmTokenRepository extends JpaRepository<FcmToken, Long> {
    Optional<FcmToken> findByUserIdAndDeviceId(Long userId, String deviceId);
    void deleteByToken(String token);

    @Query("SELECT f.token FROM FcmToken f WHERE f.userId = :userId")
    List<String> findTokensByUserId(@Param("userId") Long userId);

    @Query("SELECT f.token FROM FcmToken f WHERE f.userId IN :userIds")
    List<String> findTokensByUserIds(@Param("userIds") List<Long> userIds);
}
