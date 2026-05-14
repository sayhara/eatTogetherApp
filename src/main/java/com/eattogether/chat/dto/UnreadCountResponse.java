package com.eattogether.chat.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class UnreadCountResponse {
    private Long gatheringId;
    private long unreadCount;
}
