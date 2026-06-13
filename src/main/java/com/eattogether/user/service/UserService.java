package com.eattogether.user.service;

import com.eattogether.common.exception.BusinessException;
import com.eattogether.common.exception.ErrorCode;
import com.eattogether.user.domain.User;
import com.eattogether.user.dto.LocationUpdateRequest;
import com.eattogether.user.dto.NotificationUpdateRequest;
import com.eattogether.user.dto.UserProfileResponse;
import com.eattogether.user.dto.UserUpdateRequest;
import com.eattogether.review.repository.ReviewRepository;
import com.eattogether.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final ReviewRepository reviewRepository;

    public UserProfileResponse getProfile(Long userId) {
        User user = findById(userId);
        Double avg = reviewRepository.findAverageRatingByRevieweeId(userId);
        return UserProfileResponse.from(user, avg != null ? avg : 0.0);
    }

    @Transactional
    public UserProfileResponse updateNickname(Long userId, UserUpdateRequest request) {
        if (userRepository.existsByNickname(request.getNickname())) {
            throw new BusinessException(ErrorCode.DUPLICATE_NICKNAME);
        }
        User user = findById(userId);
        user.updateNickname(request.getNickname());
        return UserProfileResponse.from(user);
    }

    @Transactional
    public void updateLocation(Long userId, LocationUpdateRequest request) {
        findById(userId).updateLocation(request.getLatitude(), request.getLongitude());
    }

    @Transactional
    public UserProfileResponse updateNotification(Long userId, NotificationUpdateRequest request) {
        User user = findById(userId);
        user.updateNotification(request.getEnabled());
        return UserProfileResponse.from(user);
    }

    public boolean isNicknameAvailable(Long userId, String nickname) {
        return !userRepository.existsByNicknameAndIdNot(nickname, userId);
    }

    private User findById(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
    }
}
