package com.eattogether.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class LinkTokenRequest {

    @NotBlank(message = "연동 토큰은 필수입니다.")
    private String linkToken;
}
