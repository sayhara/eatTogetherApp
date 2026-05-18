package com.eattogether.gathering.controller;

import com.eattogether.common.response.ApiResponse;
import com.eattogether.config.RateLimit;
import com.eattogether.gathering.dto.GatheringCreateRequest;
import com.eattogether.gathering.dto.GatheringUpdateRequest;
import com.eattogether.gathering.dto.GatheringResponse;
import com.eattogether.gathering.dto.NearbyGatheringRequest;
import com.eattogether.gathering.dto.ParticipantResponse;
import com.eattogether.gathering.service.GatheringService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/gatherings")
@RequiredArgsConstructor
public class GatheringController {

    private final GatheringService gatheringService;

    @RateLimit(maxRequests = 10, windowSeconds = 3600, key = "gathering.create")
    @PostMapping
    public ApiResponse<GatheringResponse> create(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody GatheringCreateRequest request) {
        return ApiResponse.ok(gatheringService.create(userId(userDetails), request));
    }

    @GetMapping("/nearby")
    public ApiResponse<List<GatheringResponse>> findNearby(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @ModelAttribute NearbyGatheringRequest request) {
        return ApiResponse.ok(gatheringService.findNearby(userId(userDetails), request));
    }

    @GetMapping("/{gatheringId}")
    public ApiResponse<GatheringResponse> getById(@PathVariable Long gatheringId) {
        return ApiResponse.ok(gatheringService.getById(gatheringId));
    }

    @PutMapping("/{gatheringId}")
    public ApiResponse<GatheringResponse> update(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId,
            @Valid @RequestBody GatheringUpdateRequest request) {
        return ApiResponse.ok(gatheringService.update(userId(userDetails), gatheringId, request));
    }

    @GetMapping("/{gatheringId}/participants")
    public ApiResponse<List<ParticipantResponse>> getParticipants(@PathVariable Long gatheringId) {
        return ApiResponse.ok(gatheringService.getParticipants(gatheringId));
    }

    @GetMapping("/{gatheringId}/participants/pending")
    public ApiResponse<List<ParticipantResponse>> getPendingParticipants(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId) {
        return ApiResponse.ok(gatheringService.getPendingParticipants(userId(userDetails), gatheringId));
    }

    @PostMapping("/{gatheringId}/participants/{targetUserId}/approve")
    public ApiResponse<Void> approveParticipant(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId,
            @PathVariable Long targetUserId) {
        gatheringService.approve(userId(userDetails), gatheringId, targetUserId);
        return ApiResponse.ok(null);
    }

    @PostMapping("/{gatheringId}/participants/{targetUserId}/reject")
    public ApiResponse<Void> rejectParticipant(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId,
            @PathVariable Long targetUserId) {
        gatheringService.reject(userId(userDetails), gatheringId, targetUserId);
        return ApiResponse.ok(null);
    }

    @GetMapping("/{gatheringId}/my-status")
    public ApiResponse<String> getMyParticipationStatus(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId) {
        return ApiResponse.ok(gatheringService.getMyParticipationStatus(userId(userDetails), gatheringId));
    }

    @RateLimit(maxRequests = 20, windowSeconds = 3600, key = "gathering.join")
    @PostMapping("/{gatheringId}/join")
    public ApiResponse<Void> join(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId) {
        gatheringService.join(userId(userDetails), gatheringId);
        return ApiResponse.ok(null);
    }

    @DeleteMapping("/{gatheringId}/leave")
    public ApiResponse<Void> leave(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId) {
        gatheringService.leave(userId(userDetails), gatheringId);
        return ApiResponse.ok(null);
    }

    @DeleteMapping("/{gatheringId}")
    public ApiResponse<Void> cancel(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId) {
        gatheringService.cancel(userId(userDetails), gatheringId);
        return ApiResponse.ok(null);
    }

    @PostMapping("/{gatheringId}/complete")
    public ApiResponse<Void> complete(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId) {
        gatheringService.complete(userId(userDetails), gatheringId);
        return ApiResponse.ok(null);
    }

    @GetMapping("/my/hosted")
    public ApiResponse<List<GatheringResponse>> getMyHosted(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ApiResponse.ok(gatheringService.getMyHosted(userId(userDetails)));
    }

    @GetMapping("/my/joined")
    public ApiResponse<List<GatheringResponse>> getMyJoined(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ApiResponse.ok(gatheringService.getMyJoined(userId(userDetails)));
    }

    private Long userId(UserDetails userDetails) {
        return Long.parseLong(userDetails.getUsername());
    }
}
