package com.eattogether.auth.service;

import com.eattogether.common.exception.BusinessException;
import com.eattogether.common.exception.ErrorCode;
import com.eattogether.security.jwt.TokenDto;
import com.eattogether.user.domain.Provider;
import com.eattogether.user.domain.Role;
import com.eattogether.user.domain.User;
import com.eattogether.user.domain.UserOAuthConnection;
import com.eattogether.user.repository.UserOAuthConnectionRepository;
import com.eattogether.user.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class OAuthAccountLinkService {

    private static final String LINK_PREFIX = "LINK:";
    private static final long LINK_TOKEN_EXPIRE_MINUTES = 5;

    private final UserRepository userRepository;
    private final UserOAuthConnectionRepository connectionRepository;
    private final AuthService authService;
    private final RedisTemplate<String, String> redisTemplate;
    private final ObjectMapper objectMapper;

    public record PendingOAuthLink(Provider provider, String providerId, String email, Long existingUserId) {}

    @Transactional
    public User createUserAndConnection(Provider provider, String providerId, String email, String profileImageUrl) {
        String tempNickname = "user_" + providerId.substring(0, Math.min(8, providerId.length()));
        User user = userRepository.save(User.builder()
                .email(email)
                .nickname(tempNickname)
                .profileImageUrl(profileImageUrl)
                .provider(provider)
                .providerId(providerId)
                .role(Role.USER)
                .build());
        connectionRepository.save(UserOAuthConnection.builder()
                .user(user)
                .provider(provider)
                .providerId(providerId)
                .build());
        return user;
    }

    public String issuePendingLink(Provider provider, String providerId, String email, Long existingUserId) {
        String token = UUID.randomUUID().toString();
        try {
            String json = objectMapper.writeValueAsString(
                    new PendingOAuthLink(provider, providerId, email, existingUserId));
            redisTemplate.opsForValue().set(LINK_PREFIX + token, json, LINK_TOKEN_EXPIRE_MINUTES, TimeUnit.MINUTES);
        } catch (Exception e) {
            log.error("Failed to serialize pending OAuth link", e);
            throw new BusinessException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
        return token;
    }

    @Transactional
    public TokenDto confirmLink(String linkToken) {
        PendingOAuthLink pending = consumePendingLink(linkToken);
        User user = userRepository.findById(pending.existingUserId())
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

        if (connectionRepository.findByProviderAndProviderId(pending.provider(), pending.providerId()).isEmpty()) {
            connectionRepository.save(UserOAuthConnection.builder()
                    .user(user)
                    .provider(pending.provider())
                    .providerId(pending.providerId())
                    .build());
        }
        return authService.issueTokens(user.getId(), "USER");
    }

    @Transactional
    public TokenDto createSeparateAccount(String linkToken) {
        PendingOAuthLink pending = consumePendingLink(linkToken);
        User user = createUserAndConnection(pending.provider(), pending.providerId(), pending.email(), null);
        return authService.issueTokens(user.getId(), "USER");
    }

    private PendingOAuthLink consumePendingLink(String linkToken) {
        String key = LINK_PREFIX + linkToken;
        String json = redisTemplate.opsForValue().get(key);
        if (json == null) {
            throw new BusinessException(ErrorCode.INVALID_LINK_TOKEN);
        }
        redisTemplate.delete(key);
        try {
            return objectMapper.readValue(json, PendingOAuthLink.class);
        } catch (Exception e) {
            throw new BusinessException(ErrorCode.INVALID_LINK_TOKEN);
        }
    }
}
