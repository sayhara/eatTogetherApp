package com.eattogether.user.controller;

import com.eattogether.common.response.ApiResponse;
import com.eattogether.user.dto.BlockedUserResponse;
import com.eattogether.user.service.UserBlockService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserBlockController {

    private final UserBlockService userBlockService;

    @PostMapping("/{userId}/block")
    public ApiResponse<Void> block(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long userId) {
        userBlockService.block(Long.parseLong(userDetails.getUsername()), userId);
        return ApiResponse.ok(null);
    }

    @DeleteMapping("/{userId}/block")
    public ApiResponse<Void> unblock(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long userId) {
        userBlockService.unblock(Long.parseLong(userDetails.getUsername()), userId);
        return ApiResponse.ok(null);
    }

    @GetMapping("/me/blocks")
    public ApiResponse<List<BlockedUserResponse>> getBlockedUsers(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ApiResponse.ok(userBlockService.getBlockedUsers(Long.parseLong(userDetails.getUsername())));
    }
}
