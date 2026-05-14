package com.eattogether.auth.dto;

import com.eattogether.security.jwt.TokenDto;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TokenResponse {
    private String accessToken;
    private String refreshToken;
    private long accessTokenExpireIn;

    public static TokenResponse from(TokenDto tokenDto) {
        return TokenResponse.builder()
                .accessToken(tokenDto.getAccessToken())
                .refreshToken(tokenDto.getRefreshToken())
                .accessTokenExpireIn(tokenDto.getAccessTokenExpireIn())
                .build();
    }
}
