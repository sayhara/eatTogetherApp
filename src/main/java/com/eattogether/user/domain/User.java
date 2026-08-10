package com.eattogether.user.domain;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "users",
    uniqueConstraints = @UniqueConstraint(columnNames = {"provider", "provider_id"})
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Builder
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nickname;

    private String email;

    private String profileImageUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Provider provider;

    @Column(nullable = false)
    private String providerId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Builder.Default
    @Column(nullable = false)
    private boolean notificationEnabled = true;

    @Builder.Default
    @Column(nullable = false)
    private boolean nicknameSet = false;

    // 앱 실행 시 업데이트되는 마지막 위치
    private Double latitude;
    private Double longitude;

    private LocalDateTime withdrawnAt;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public void updateProfileImage(String profileImageUrl) {
        if (profileImageUrl != null) this.profileImageUrl = profileImageUrl;
    }

    public void updateNickname(String nickname) {
        this.nickname = nickname;
        this.nicknameSet = true;
    }

    public void updateLocation(Double latitude, Double longitude) {
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public void updateNotification(boolean enabled) {
        this.notificationEnabled = enabled;
    }

    public void withdraw(String anonymizedNickname) {
        this.nickname = anonymizedNickname;
        this.email = null;
        this.profileImageUrl = null;
        this.withdrawnAt = LocalDateTime.now();
    }

    public boolean isWithdrawn() {
        return this.withdrawnAt != null;
    }

    // 탈퇴했던 사용자가 같은 소셜 계정으로 다시 로그인하면 신규 가입과 동일하게 초기화한다.
    public void reactivate(String tempNickname, String email, String profileImageUrl) {
        this.nickname = tempNickname;
        this.email = email;
        this.profileImageUrl = profileImageUrl;
        this.nicknameSet = false;
        this.withdrawnAt = null;
    }
}
