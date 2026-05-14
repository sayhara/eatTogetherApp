package com.eattogether.user.controller;

import com.eattogether.common.response.ApiResponse;
import com.eattogether.user.dto.LocationUpdateRequest;
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

    private Long userId(UserDetails userDetails) {
        return Long.parseLong(userDetails.getUsername());
    }
}
