package com.eattogether.security.oauth2;

import com.eattogether.auth.service.OAuthAccountLinkService;
import com.eattogether.security.oauth2.userinfo.GoogleOAuth2UserInfo;
import com.eattogether.security.oauth2.userinfo.KakaoOAuth2UserInfo;
import com.eattogether.security.oauth2.userinfo.NaverOAuth2UserInfo;
import com.eattogether.security.oauth2.userinfo.OAuth2UserInfo;
import com.eattogether.user.domain.Provider;
import com.eattogether.user.domain.User;
import com.eattogether.user.domain.UserOAuthConnection;
import com.eattogether.user.repository.UserOAuthConnectionRepository;
import com.eattogether.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class CustomOAuth2UserService extends DefaultOAuth2UserService {

    private final UserRepository userRepository;
    private final UserOAuthConnectionRepository connectionRepository;
    private final OAuthAccountLinkService oAuthAccountLinkService;

    @Override
    @Transactional
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User oAuth2User = super.loadUser(userRequest);
        String registrationId = userRequest.getClientRegistration().getRegistrationId();
        String userNameAttributeName = userRequest.getClientRegistration()
                .getProviderDetails().getUserInfoEndpoint().getUserNameAttributeName();

        Map<String, Object> attributes = oAuth2User.getAttributes();
        OAuth2UserInfo userInfo = switch (registrationId) {
            case "google" -> new GoogleOAuth2UserInfo(attributes);
            case "kakao"  -> new KakaoOAuth2UserInfo(attributes);
            case "naver"  -> new NaverOAuth2UserInfo(attributes);
            default -> throw new OAuth2AuthenticationException("지원하지 않는 소셜 로그인: " + registrationId);
        };

        Provider provider = Provider.valueOf(registrationId.toUpperCase());
        String providerId = userInfo.getProviderId();

        // 1. 이미 연동된 provider 계정인지 확인
        Optional<UserOAuthConnection> connection = connectionRepository.findByProviderAndProviderId(provider, providerId);
        if (connection.isPresent()) {
            return resolveExistingUser(connection.get().getUser(), providerId, userInfo, attributes, userNameAttributeName);
        }

        // 2. 레거시 폴백: V4 마이그레이션 백필 이전(로컬 등)에 생성된 기존 계정 자가 치유
        Optional<User> legacyUser = userRepository.findByProviderAndProviderId(provider, providerId);
        if (legacyUser.isPresent()) {
            User user = legacyUser.get();
            connectionRepository.save(UserOAuthConnection.builder()
                    .user(user)
                    .provider(provider)
                    .providerId(providerId)
                    .build());
            return resolveExistingUser(user, providerId, userInfo, attributes, userNameAttributeName);
        }

        // 3. 연동 후보: 다른 provider로 이미 가입된 동일 이메일 계정이 있으면 즉시 계정을 만들지 않고 확인 절차로 넘김
        String email = userInfo.getEmail();
        if (email != null) {
            Optional<User> existingByEmail = userRepository.findByEmail(email);
            if (existingByEmail.isPresent()) {
                String linkToken = oAuthAccountLinkService.issuePendingLink(
                        provider, providerId, email, existingByEmail.get().getId());
                return new CustomOAuth2User(
                        Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER")),
                        attributes, userNameAttributeName,
                        null, email, false, true, linkToken);
            }
        }

        // 4. 완전히 새로운 사용자
        User newUser = oAuthAccountLinkService.createUserAndConnection(
                provider, providerId, email, userInfo.getProfileImageUrl());
        return buildOAuth2User(newUser, attributes, userNameAttributeName, true);
    }

    // 탈퇴한 계정으로 같은 provider 로그인을 다시 시도하면 신규 가입처럼 재활성화한다.
    private CustomOAuth2User resolveExistingUser(User user, String providerId, OAuth2UserInfo userInfo,
                                                  Map<String, Object> attributes, String nameAttributeKey) {
        if (user.isWithdrawn()) {
            String tempNickname = "user_" + providerId.substring(0, Math.min(8, providerId.length()));
            user.reactivate(tempNickname, userInfo.getEmail(), userInfo.getProfileImageUrl());
            return buildOAuth2User(user, attributes, nameAttributeKey, true);
        }
        user.updateProfileImage(userInfo.getProfileImageUrl());
        return buildOAuth2User(user, attributes, nameAttributeKey, false);
    }

    private CustomOAuth2User buildOAuth2User(User user, Map<String, Object> attributes, String nameAttributeKey,
                                              boolean isNewUser) {
        return new CustomOAuth2User(
                Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + user.getRole().name())),
                attributes,
                nameAttributeKey,
                user.getId(),
                user.getEmail(),
                isNewUser,
                false,
                null
        );
    }
}
