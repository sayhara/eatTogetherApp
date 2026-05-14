package com.eattogether.fcm.controller;

import com.eattogether.common.response.ApiResponse;
import com.eattogether.fcm.dto.FcmTokenRequest;
import com.eattogether.fcm.service.FcmService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/fcm")
@RequiredArgsConstructor
public class FcmController {

    private final FcmService fcmService;

    @PostMapping("/token")
    public ApiResponse<Void> registerToken(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody FcmTokenRequest request) {
        Long userId = Long.parseLong(userDetails.getUsername());
        fcmService.registerToken(userId, request);
        return ApiResponse.ok(null);
    }
}
