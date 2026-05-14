package com.eattogether.gathering.dto;

import com.eattogether.gathering.domain.Gathering;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class GatheringResponse {
    private Long id;
    private Long hostId;
    private String hostNickname;
    private String hostProfileImageUrl;
    private String title;
    private String description;
    private String restaurantName;
    private Double latitude;
    private Double longitude;
    private String address;
    private String category;
    private Integer maxParticipants;
    private Integer currentParticipants;
    private LocalDateTime mealTime;
    private String status;
    private Double distanceKm;
    private LocalDateTime createdAt;

    public static GatheringResponse from(Gathering g) {
        return from(g, null);
    }

    public static GatheringResponse from(Gathering g, Double distanceKm) {
        return GatheringResponse.builder()
                .id(g.getId())
                .hostId(g.getHost().getId())
                .hostNickname(g.getHost().getNickname())
                .hostProfileImageUrl(g.getHost().getProfileImageUrl())
                .title(g.getTitle())
                .description(g.getDescription())
                .restaurantName(g.getRestaurantName())
                .latitude(g.getLatitude())
                .longitude(g.getLongitude())
                .address(g.getAddress())
                .category(g.getCategory() != null ? g.getCategory().name() : null)
                .maxParticipants(g.getMaxParticipants())
                .currentParticipants(g.getCurrentParticipantCount())
                .mealTime(g.getMealTime())
                .status(g.getStatus().name())
                .distanceKm(distanceKm)
                .createdAt(g.getCreatedAt())
                .build();
    }
}
