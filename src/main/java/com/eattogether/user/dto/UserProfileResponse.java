package com.eattogether.user.dto;

import com.eattogether.user.domain.User;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserProfileResponse {
    private Long id;
    private String nickname;
    private String email;
    private String profileImageUrl;
    private String provider;
    private Double averageRating;
    private boolean notificationEnabled;

    public static UserProfileResponse from(User user) {
        return from(user, 0.0);
    }

    public static UserProfileResponse from(User user, Double averageRating) {
        return UserProfileResponse.builder()
                .id(user.getId())
                .nickname(user.getNickname())
                .email(user.getEmail())
                .profileImageUrl(user.getProfileImageUrl())
                .provider(user.getProvider().name().toLowerCase())
                .averageRating(averageRating)
                .notificationEnabled(user.isNotificationEnabled())
                .build();
    }
}
