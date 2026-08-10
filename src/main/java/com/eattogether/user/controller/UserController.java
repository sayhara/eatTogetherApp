package com.eattogether.user.controller;

import com.eattogether.auth.service.AuthService;
import com.eattogether.common.response.ApiResponse;
import com.eattogether.user.dto.LocationUpdateRequest;
import com.eattogether.user.dto.NotificationUpdateRequest;
import com.eattogether.user.dto.UserProfileResponse;
import com.eattogether.user.dto.UserUpdateRequest;
import com.eattogether.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final AuthService authService;

    @GetMapping("/me")
    public ApiResponse<UserProfileResponse> getMyProfile(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ApiResponse.ok(userService.getProfile(userId(userDetails)));
    }

    @PatchMapping("/me/nickname")
    public ApiResponse<UserProfileResponse> updateNickname(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody UserUpdateRequest request) {
        return ApiResponse.ok(userService.updateNickname(userId(userDetails), request));
    }

    @PutMapping("/me/location")
    public ApiResponse<Void> updateLocation(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody LocationUpdateRequest request) {
        userService.updateLocation(userId(userDetails), request);
        return ApiResponse.ok(null);
    }

    @PatchMapping("/me/notification")
    public ApiResponse<UserProfileResponse> updateNotification(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody NotificationUpdateRequest request) {
        return ApiResponse.ok(userService.updateNotification(userId(userDetails), request));
    }

    @GetMapping("/nickname/check")
    public ApiResponse<Boolean> checkNickname(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam String nickname) {
        return ApiResponse.ok(userService.isNicknameAvailable(userId(userDetails), nickname));
    }

    @DeleteMapping("/me")
    public ApiResponse<Void> withdraw(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestHeader("Authorization") String bearerToken) {
        Long userId = userId(userDetails);
        userService.withdraw(userId);
        authService.logout(bearerToken.substring(7), userId); // "Bearer " 제거
        return ApiResponse.ok(null);
    }

    private Long userId(UserDetails userDetails) {
        return Long.parseLong(userDetails.getUsername());
    }
}
