package com.eattogether.gathering.domain;

import com.eattogether.user.domain.User;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "gathering_participants",
    uniqueConstraints = @UniqueConstraint(columnNames = {"gathering_id", "user_id"})
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Builder
@AllArgsConstructor
public class GatheringParticipant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "gathering_id", nullable = false)
    private Gathering gathering;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, columnDefinition = "VARCHAR(20) DEFAULT 'APPROVED'")
    @Builder.Default
    private ParticipantStatus status = ParticipantStatus.PENDING;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime joinedAt;

    public void approve() {
        this.status = ParticipantStatus.APPROVED;
    }

    public void reject() {
        this.status = ParticipantStatus.REJECTED;
    }

    public void resetToPending() {
        this.status = ParticipantStatus.PENDING;
    }
}
