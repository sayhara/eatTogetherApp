package com.eattogether.gathering.dto;

import com.eattogether.gathering.domain.FoodCategory;
import jakarta.validation.constraints.*;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class GatheringCreateRequest {

    @NotBlank(message = "제목은 필수입니다.")
    @Size(max = 50, message = "제목은 50자 이내여야 합니다.")
    private String title;

    @Size(max = 200, message = "설명은 200자 이내여야 합니다.")
    private String description;

    @NotBlank(message = "식당 이름은 필수입니다.")
    private String restaurantName;

    @NotNull(message = "위도는 필수입니다.")
    private Double latitude;

    @NotNull(message = "경도는 필수입니다.")
    private Double longitude;

    private String address;

    private FoodCategory category;

    @NotNull(message = "최대 인원은 필수입니다.")
    @Min(value = 2, message = "최소 2명 이상이어야 합니다.")
    @Max(value = 10, message = "최대 10명까지 가능합니다.")
    private Integer maxParticipants;

    @NotNull(message = "식사 시간은 필수입니다.")
    @Future(message = "식사 시간은 미래여야 합니다.")
    private LocalDateTime mealTime;
}
