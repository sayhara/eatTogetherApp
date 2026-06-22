package com.eattogether.security.oauth2;

import com.eattogether.security.oauth2.userinfo.GoogleOAuth2UserInfo;
import com.eattogether.security.oauth2.userinfo.KakaoOAuth2UserInfo;
import com.eattogether.security.oauth2.userinfo.NaverOAuth2UserInfo;
import com.eattogether.security.oauth2.userinfo.OAuth2UserInfo;
import com.eattogether.user.domain.Provider;
import com.eattogether.user.domain.Role;
import com.eattogether.user.domain.User;
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
import java.util.concurrent.atomic.AtomicBoolean;

@Service
@RequiredArgsConstructor
public class CustomOAuth2UserService extends DefaultOAuth2UserService {

    private final UserRepository userRepository;

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
        AtomicBoolean isNewUser = new AtomicBoolean(false);

        User user = userRepository.findByProviderAndProviderId(provider, userInfo.getProviderId())
                .orElseGet(() -> {
                    isNewUser.set(true);
                    String tempNickname = "user_" + userInfo.getProviderId().substring(0, Math.min(8, userInfo.getProviderId().length()));
                    return userRepository.save(User.builder()
                            .email(userInfo.getEmail())
                            .nickname(tempNickname)
                            .profileImageUrl(userInfo.getProfileImageUrl())
                            .provider(provider)
                            .providerId(userInfo.getProviderId())
                            .role(Role.USER)
                            .build());
                });

        if (!isNewUser.get()) {
            user.updateProfileImage(userInfo.getProfileImageUrl());
        }

        return new CustomOAuth2User(
                Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + user.getRole().name())),
                attributes,
                userNameAttributeName,
                user.getId(),
                user.getEmail(),
                isNewUser.get()
        );
    }
}
