package com.eattogether.fcm.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class FcmTokenRequest {

    @NotBlank(message = "FCM 토큰은 필수입니다.")
    private String token;

    @NotBlank(message = "디바이스 ID는 필수입니다.")
    private String deviceId;
}
