package com.eattogether.user.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

@Getter
public class LocationUpdateRequest {

    @NotNull(message = "위도는 필수입니다.")
    private Double latitude;

    @NotNull(message = "경도는 필수입니다.")
    private Double longitude;
}
