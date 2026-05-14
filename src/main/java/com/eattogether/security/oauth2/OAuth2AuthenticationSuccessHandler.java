package com.eattogether.security.oauth2;

import com.eattogether.auth.service.AuthService;
import com.eattogether.security.jwt.TokenDto;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;

@Slf4j
@Component
@RequiredArgsConstructor
public class OAuth2AuthenticationSuccessHandler extends SimpleUrlAuthenticationSuccessHandler {

    @Value("${app.oauth2.redirect-uri}")
    private String redirectUri;

    private final AuthService authService;

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
                                        Authentication authentication) throws IOException {
        CustomOAuth2User oAuth2User = (CustomOAuth2User) authentication.getPrincipal();
        TokenDto tokenDto = authService.issueTokens(oAuth2User.getUserId(), "USER");

        String targetUrl = UriComponentsBuilder.fromUriString(redirectUri)
                .queryParam("accessToken", tokenDto.getAccessToken())
                .queryParam("refreshToken", tokenDto.getRefreshToken())
                .queryParam("isNewUser", oAuth2User.isNewUser())
                .build().toUriString();

        log.debug("OAuth2 login success, redirecting to app: userId={}", oAuth2User.getUserId());
        getRedirectStrategy().sendRedirect(request, response, targetUrl);
    }
}
