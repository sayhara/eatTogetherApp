package com.eattogether.auth.service;

import com.eattogether.common.exception.BusinessException;
import com.eattogether.common.exception.ErrorCode;
import com.eattogether.security.jwt.JwtTokenProvider;
import com.eattogether.security.jwt.TokenDto;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final String REFRESH_PREFIX = "RT:";
    private static final String BLACKLIST_PREFIX = "BL:";

    private final JwtTokenProvider jwtTokenProvider;
    private final RedisTemplate<String, String> redisTemplate;

    @Value("${jwt.refresh-token-expire}")
    private long refreshTokenExpire;

    @Value("${jwt.access-token-expire}")
    private long accessTokenExpire;

    public TokenDto issueTokens(Long userId, String role) {
        TokenDto tokenDto = jwtTokenProvider.generateTokens(userId, role);
        redisTemplate.opsForValue().set(
                REFRESH_PREFIX + userId,
                tokenDto.getRefreshToken(),
                refreshTokenExpire,
                TimeUnit.MILLISECONDS
        );
        return tokenDto;
    }

    public TokenDto reissue(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw new BusinessException(ErrorCode.INVALID_REFRESH_TOKEN);
        }

        Long userId = jwtTokenProvider.getUserId(refreshToken);
        String stored = redisTemplate.opsForValue().get(REFRESH_PREFIX + userId);

        if (!refreshToken.equals(stored)) {
            throw new BusinessException(ErrorCode.INVALID_REFRESH_TOKEN);
        }

        return issueTokens(userId, "USER");
    }

    public void logout(String accessToken, Long userId) {
        redisTemplate.opsForValue().set(
                BLACKLIST_PREFIX + accessToken,
                "logout",
                accessTokenExpire,
                TimeUnit.MILLISECONDS
        );
        redisTemplate.delete(REFRESH_PREFIX + userId);
    }
}
