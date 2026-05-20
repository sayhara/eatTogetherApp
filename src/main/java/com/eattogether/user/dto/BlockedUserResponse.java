package com.eattogether.user.dto;

import com.eattogether.user.domain.User;
import com.eattogether.user.domain.UserBlock;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class BlockedUserResponse {
    private Long blockedUserId;
    private String nickname;
    private String profileImageUrl;
    private LocalDateTime blockedAt;

    public static BlockedUserResponse from(UserBlock block, User blockedUser) {
        return BlockedUserResponse.builder()
                .blockedUserId(block.getBlockedId())
                .nickname(blockedUser.getNickname())
                .profileImageUrl(blockedUser.getProfileImageUrl())
                .blockedAt(block.getCreatedAt())
                .build();
    }
}
