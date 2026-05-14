package com.eattogether.chat.domain;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "chat_read_status",
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "gathering_id"})
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Builder
@AllArgsConstructor
public class ChatReadStatus {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "gathering_id", nullable = false)
    private Long gatheringId;

    @LastModifiedDate
    private LocalDateTime lastReadAt;

    public void updateReadAt() {
        this.lastReadAt = LocalDateTime.now();
    }
}
