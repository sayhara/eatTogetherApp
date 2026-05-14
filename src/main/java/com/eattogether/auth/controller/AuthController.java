package com.eattogether.auth.controller;

import com.eattogether.auth.dto.ReissueRequest;
import com.eattogether.auth.dto.TokenResponse;
import com.eattogether.auth.service.AuthService;
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

    @PostMapping("/reissue")
    public ApiResponse<TokenResponse> reissue(@Valid @RequestBody ReissueRequest request) {
        return ApiResponse.ok(TokenResponse.from(authService.reissue(request.getRefreshToken())));
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
