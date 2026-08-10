package com.eattogether.auth.controller;

import com.eattogether.auth.dto.LinkTokenRequest;
import com.eattogether.auth.dto.ReissueRequest;
import com.eattogether.auth.dto.TokenResponse;
import com.eattogether.auth.service.AuthService;
import com.eattogether.auth.service.OAuthAccountLinkService;
import com.eattogether.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final OAuthAccountLinkService oAuthAccountLinkService;

    @PostMapping("/reissue")
    public ApiResponse<TokenResponse> reissue(@Valid @RequestBody ReissueRequest request) {
        return ApiResponse.ok(TokenResponse.from(authService.reissue(request.getRefreshToken())));
    }

    @PostMapping("/oauth/link")
    public ApiResponse<TokenResponse> linkOAuthAccount(@Valid @RequestBody LinkTokenRequest request) {
        return ApiResponse.ok(TokenResponse.from(oAuthAccountLinkService.confirmLink(request.getLinkToken())));
    }

    @PostMapping("/oauth/create-separate")
    public ApiResponse<TokenResponse> createSeparateOAuthAccount(@Valid @RequestBody LinkTokenRequest request) {
        return ApiResponse.ok(TokenResponse.from(oAuthAccountLinkService.createSeparateAccount(request.getLinkToken())));
    }

    @PostMapping("/logout")
    public ApiResponse<Void> logout(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestHeader("Authorization") String bearerToken) {
        Long userId = Long.parseLong(userDetails.getUsername());
        String accessToken = bearerToken.substring(7); // "Bearer " 제거
        authService.logout(accessToken, userId);
        return ApiResponse.ok(null);
    }
}
