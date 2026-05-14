package com.eattogether.security.jwt;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TokenDto {
    private String accessToken;
    private String refreshToken;
    private long accessTokenExpireIn;
}
