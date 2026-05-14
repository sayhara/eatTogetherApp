package com.eattogether.user.dto;

import com.eattogether.user.domain.UserBlock;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class BlockedUserResponse {
    private Long blockedUserId;
    private LocalDateTime blockedAt;

    public static BlockedUserResponse from(UserBlock block) {
        return BlockedUserResponse.builder()
                .blockedUserId(block.getBlockedId())
                .blockedAt(block.getCreatedAt())
                .build();
    }
}
