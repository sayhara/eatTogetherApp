package com.eattogether.gathering.domain;

public enum GatheringStatus {
    OPEN,       // 모집 중
    CLOSED,     // 마감 (정원 초과 또는 호스트 마감)
    COMPLETED,  // 식사 완료
    CANCELLED   // 취소
}
