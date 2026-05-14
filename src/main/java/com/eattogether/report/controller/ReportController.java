package com.eattogether.report.controller;

import com.eattogether.common.response.ApiResponse;
import com.eattogether.config.RateLimit;
import com.eattogether.report.dto.ReportCreateRequest;
import com.eattogether.report.dto.ReportResponse;
import com.eattogether.report.service.ReportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @RateLimit(maxRequests = 20, windowSeconds = 86400, key = "report.user")
    @PostMapping("/api/users/{userId}/report")
    public ApiResponse<ReportResponse> reportUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long userId,
            @Valid @RequestBody ReportCreateRequest request) {
        Long reporterId = Long.parseLong(userDetails.getUsername());
        return ApiResponse.ok(reportService.reportUser(reporterId, userId, request));
    }

    @RateLimit(maxRequests = 20, windowSeconds = 86400, key = "report.gathering")
    @PostMapping("/api/gatherings/{gatheringId}/report")
    public ApiResponse<ReportResponse> reportGathering(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId,
            @Valid @RequestBody ReportCreateRequest request) {
        Long reporterId = Long.parseLong(userDetails.getUsername());
        return ApiResponse.ok(reportService.reportGathering(reporterId, gatheringId, request));
    }
}
