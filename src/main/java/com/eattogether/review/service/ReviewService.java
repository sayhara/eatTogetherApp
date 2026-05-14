package com.eattogether.review.service;

import com.eattogether.common.exception.BusinessException;
import com.eattogether.common.exception.ErrorCode;
import com.eattogether.gathering.domain.Gathering;
import com.eattogether.gathering.domain.GatheringStatus;
import com.eattogether.gathering.repository.GatheringParticipantRepository;
import com.eattogether.gathering.repository.GatheringRepository;
import com.eattogether.review.domain.Review;
import com.eattogether.review.dto.ReviewCreateRequest;
import com.eattogether.review.dto.ReviewResponse;
import com.eattogether.review.repository.ReviewRepository;
import com.eattogether.user.domain.User;
import com.eattogether.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final GatheringRepository gatheringRepository;
    private final GatheringParticipantRepository participantRepository;
    private final UserRepository userRepository;

    @Transactional
    public ReviewResponse create(Long reviewerId, Long gatheringId, ReviewCreateRequest request) {
        Gathering gathering = gatheringRepository.findById(gatheringId)
                .orElseThrow(() -> new BusinessException(ErrorCode.GATHERING_NOT_FOUND));

        if (gathering.getStatus() != GatheringStatus.COMPLETED) {
            throw new BusinessException(ErrorCode.GATHERING_NOT_COMPLETED);
        }
        if (reviewerId.equals(request.getRevieweeId())) {
            throw new BusinessException(ErrorCode.CANNOT_REVIEW_YOURSELF);
        }
        if (!participantRepository.existsByGatheringIdAndUserId(gatheringId, reviewerId)) {
            throw new BusinessException(ErrorCode.NOT_JOINED);
        }
        if (!participantRepository.existsByGatheringIdAndUserId(gatheringId, request.getRevieweeId())) {
            throw new BusinessException(ErrorCode.REVIEWEE_NOT_PARTICIPANT);
        }
        if (reviewRepository.existsByGatheringIdAndReviewerIdAndRevieweeId(
                gatheringId, reviewerId, request.getRevieweeId())) {
            throw new BusinessException(ErrorCode.ALREADY_REVIEWED);
        }

        User reviewer = userRepository.findById(reviewerId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        User reviewee = userRepository.findById(request.getRevieweeId())
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

        Review review = reviewRepository.save(Review.builder()
                .gatheringId(gatheringId)
                .reviewer(reviewer)
                .reviewee(reviewee)
                .rating(request.getRating())
                .comment(request.getComment())
                .build());

        return ReviewResponse.from(review);
    }

    public List<ReviewResponse> getReviewsForUser(Long userId) {
        return reviewRepository.findByRevieweeId(userId).stream()
                .map(ReviewResponse::from)
                .toList();
    }

    public Double getAverageRating(Long userId) {
        return reviewRepository.findAverageRatingByRevieweeId(userId);
    }
}
