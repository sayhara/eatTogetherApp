package com.eattogether.gathering.dto;

import com.eattogether.gathering.domain.GatheringParticipant;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class ParticipantResponse {
    private Long userId;
    private String nickname;
    private String profileImageUrl;
    private LocalDateTime joinedAt;
    private boolean host;
    private String status;

    public static ParticipantResponse from(GatheringParticipant participant, Long hostId) {
        return ParticipantResponse.builder()
                .userId(participant.getUser().getId())
                .nickname(participant.getUser().getNickname())
                .profileImageUrl(participant.getUser().getProfileImageUrl())
                .joinedAt(participant.getJoinedAt())
                .host(participant.getUser().getId().equals(hostId))
                .status(participant.getStatus().name())
                .build();
    }
}
