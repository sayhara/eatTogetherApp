package com.eattogether.gathering.domain;

import com.eattogether.user.domain.User;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "gatherings")
@EntityListeners(AuditingEntityListener.class)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Builder
@AllArgsConstructor
public class Gathering {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "host_id", nullable = false)
    private User host;

    @Column(nullable = false, length = 50)
    private String title;

    @Column(length = 200)
    private String description;

    @Column(nullable = false)
    private String restaurantName;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    private String address;

    @Enumerated(EnumType.STRING)
    private FoodCategory category;

    @Column(nullable = false)
    private Integer maxParticipants;

    @Column(nullable = false)
    private LocalDateTime mealTime;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private GatheringStatus status = GatheringStatus.OPEN;

    @OneToMany(mappedBy = "gathering", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<GatheringParticipant> participants = new ArrayList<>();

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public int getCurrentParticipantCount() {
        return participants.size();
    }

    public boolean isFull() {
        return participants.size() >= maxParticipants;
    }

    public boolean isHost(Long userId) {
        return host.getId().equals(userId);
    }

    public void close() {
        this.status = GatheringStatus.CLOSED;
    }

    public void cancel() {
        this.status = GatheringStatus.CANCELLED;
    }

    public void complete() {
        this.status = GatheringStatus.COMPLETED;
    }

    public void reopen() {
        this.status = GatheringStatus.OPEN;
    }

    public void update(String title, String description, String restaurantName,
                       String address, FoodCategory category, Integer maxParticipants, LocalDateTime mealTime) {
        if (title != null) this.title = title;
        if (description != null) this.description = description;
        if (restaurantName != null) this.restaurantName = restaurantName;
        if (address != null) this.address = address;
        if (category != null) this.category = category;
        if (maxParticipants != null) this.maxParticipants = maxParticipants;
        if (mealTime != null) this.mealTime = mealTime;
    }
}
