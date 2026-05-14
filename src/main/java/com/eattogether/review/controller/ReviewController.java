package com.eattogether.review.controller;

import com.eattogether.common.response.ApiResponse;
import com.eattogether.review.dto.ReviewCreateRequest;
import com.eattogether.review.dto.ReviewResponse;
import com.eattogether.review.service.ReviewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;

    @PostMapping("/api/gatherings/{gatheringId}/reviews")
    public ApiResponse<ReviewResponse> create(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long gatheringId,
            @Valid @RequestBody ReviewCreateRequest request) {
        Long reviewerId = Long.parseLong(userDetails.getUsername());
        return ApiResponse.ok(reviewService.create(reviewerId, gatheringId, request));
    }

    @GetMapping("/api/users/{userId}/reviews")
    public ApiResponse<List<ReviewResponse>> getReviews(@PathVariable Long userId) {
        return ApiResponse.ok(reviewService.getReviewsForUser(userId));
    }

    @GetMapping("/api/users/{userId}/average-rating")
    public ApiResponse<Double> getAverageRating(@PathVariable Long userId) {
        return ApiResponse.ok(reviewService.getAverageRating(userId));
    }
}
