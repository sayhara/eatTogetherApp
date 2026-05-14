package com.eattogether.gathering.dto;

import com.eattogether.gathering.domain.FoodCategory;
import jakarta.validation.constraints.*;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class GatheringUpdateRequest {

    @Size(min = 1, max = 50, message = "제목은 1~50자 이내여야 합니다.")
    private String title;

    @Size(max = 200, message = "설명은 200자 이내여야 합니다.")
    private String description;

    @Size(min = 1, max = 100, message = "식당 이름은 1~100자 이내여야 합니다.")
    private String restaurantName;

    private String address;

    private FoodCategory category;

    @Min(value = 2, message = "최소 2명 이상이어야 합니다.")
    @Max(value = 10, message = "최대 10명까지 가능합니다.")
    private Integer maxParticipants;

    @Future(message = "식사 시간은 미래여야 합니다.")
    private LocalDateTime mealTime;
}
