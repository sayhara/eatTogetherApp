package com.eattogether.fcm.domain;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "fcm_tokens",
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "device_id"})
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Builder
@AllArgsConstructor
public class FcmToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false, unique = true)
    private String token;

    @Column(name = "device_id", nullable = false)
    private String deviceId;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public void updateToken(String token) {
        this.token = token;
    }
}
