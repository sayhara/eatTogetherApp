package com.eattogether.gathering.dto;

import com.eattogether.gathering.domain.FoodCategory;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class NearbyGatheringRequest {

    @NotNull(message = "위도는 필수입니다.")
    private Double latitude;

    @NotNull(message = "경도는 필수입니다.")
    private Double longitude;

    @Positive(message = "반경은 양수여야 합니다.")
    private Double radiusKm = 3.0;

    private FoodCategory category;

    private String keyword;
}
