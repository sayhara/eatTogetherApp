package com.eattogether.user.service;

import com.eattogether.common.exception.BusinessException;
import com.eattogether.common.exception.ErrorCode;
import com.eattogether.user.domain.User;
import com.eattogether.user.domain.UserBlock;
import com.eattogether.user.dto.BlockedUserResponse;
import com.eattogether.user.repository.UserBlockRepository;
import com.eattogether.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserBlockService {

    private final UserBlockRepository userBlockRepository;
    private final UserRepository userRepository;

    @Transactional
    public void block(Long blockerId, Long blockedId) {
        if (blockerId.equals(blockedId)) {
            throw new BusinessException(ErrorCode.CANNOT_BLOCK_YOURSELF);
        }
        if (!userRepository.existsById(blockedId)) {
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
        if (userBlockRepository.existsByBlockerIdAndBlockedId(blockerId, blockedId)) {
            throw new BusinessException(ErrorCode.ALREADY_BLOCKED);
        }
        userBlockRepository.save(UserBlock.builder()
                .blockerId(blockerId)
                .blockedId(blockedId)
                .build());
    }

    @Transactional
    public void unblock(Long blockerId, Long blockedId) {
        UserBlock block = userBlockRepository.findByBlockerIdAndBlockedId(blockerId, blockedId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_BLOCKED));
        userBlockRepository.delete(block);
    }

    public List<BlockedUserResponse> getBlockedUsers(Long userId) {
        return userBlockRepository.findByBlockerIdOrderByCreatedAtDesc(userId).stream()
                .map(block -> {
                    User blockedUser = userRepository.findById(block.getBlockedId())
                            .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
                    return BlockedUserResponse.from(block, blockedUser);
                })
                .toList();
    }

    public List<Long> getExcludedUserIds(Long userId) {
        List<Long> blockedIds = userBlockRepository.findBlockedIdsByBlockerId(userId);
        List<Long> blockerIds = userBlockRepository.findBlockerIdsByBlockedId(userId);
        blockedIds.addAll(blockerIds);
        return blockedIds;
    }
}
