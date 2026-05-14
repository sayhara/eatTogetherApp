package com.eattogether.review.dto;

import com.eattogether.review.domain.Review;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class ReviewResponse {
    private Long id;
    private Long gatheringId;
    private Long reviewerId;
    private String reviewerNickname;
    private String reviewerProfileImageUrl;
    private Integer rating;
    private String comment;
    private LocalDateTime createdAt;

    public static ReviewResponse from(Review r) {
        return ReviewResponse.builder()
                .id(r.getId())
                .gatheringId(r.getGatheringId())
                .reviewerId(r.getReviewer().getId())
                .reviewerNickname(r.getReviewer().getNickname())
                .reviewerProfileImageUrl(r.getReviewer().getProfileImageUrl())
                .rating(r.getRating())
                .comment(r.getComment())
                .createdAt(r.getCreatedAt())
                .build();
    }
}
