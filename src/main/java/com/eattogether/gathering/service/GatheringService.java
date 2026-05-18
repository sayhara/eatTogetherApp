package com.eattogether.gathering.service;

import com.eattogether.common.exception.BusinessException;
import com.eattogether.common.exception.ErrorCode;
import com.eattogether.gathering.domain.Gathering;
import com.eattogether.gathering.domain.GatheringParticipant;
import com.eattogether.gathering.domain.GatheringStatus;
import com.eattogether.gathering.domain.ParticipantStatus;
import com.eattogether.fcm.service.FcmService;
import com.eattogether.gathering.dto.GatheringCreateRequest;
import com.eattogether.gathering.dto.GatheringUpdateRequest;
import com.eattogether.gathering.dto.GatheringResponse;
import com.eattogether.gathering.dto.NearbyGatheringRequest;
import com.eattogether.gathering.dto.ParticipantResponse;
import com.eattogether.gathering.repository.GatheringParticipantRepository;
import com.eattogether.gathering.repository.GatheringRepository;
import com.eattogether.user.domain.User;
import com.eattogether.user.repository.UserRepository;
import com.eattogether.user.service.UserBlockService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class GatheringService {

    private static final double KM_PER_DEGREE = 111.0;

    private final GatheringRepository gatheringRepository;
    private final GatheringParticipantRepository participantRepository;
    private final UserRepository userRepository;
    private final FcmService fcmService;
    private final UserBlockService userBlockService;

    @Transactional
    public GatheringResponse create(Long hostId, GatheringCreateRequest request) {
        User host = findUser(hostId);
        Gathering gathering = gatheringRepository.save(Gathering.builder()
                .host(host)
                .title(request.getTitle())
                .description(request.getDescription())
                .restaurantName(request.getRestaurantName())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .address(request.getAddress())
                .category(request.getCategory())
                .maxParticipants(request.getMaxParticipants())
                .mealTime(request.getMealTime())
                .build());

        participantRepository.save(GatheringParticipant.builder()
                .gathering(gathering)
                .user(host)
                .status(ParticipantStatus.APPROVED)
                .build());

        return GatheringResponse.from(gathering);
    }

    public List<GatheringResponse> findNearby(Long userId, NearbyGatheringRequest request) {
        double lat = request.getLatitude();
        double lng = request.getLongitude();
        double margin = request.getRadiusKm() / KM_PER_DEGREE;

        Set<Long> excludedHostIds = Set.copyOf(userBlockService.getExcludedUserIds(userId));

        String keyword = request.getKeyword() != null
                ? "%" + request.getKeyword().toLowerCase() + "%" : null;

        return gatheringRepository.findByBoundingBox(
                        GatheringStatus.OPEN, LocalDateTime.now(),
                        lat - margin, lat + margin,
                        lng - margin, lng + margin,
                        request.getCategory(), keyword)
                .stream()
                .filter(g -> !excludedHostIds.contains(g.getHost().getId()))
                .map(g -> GatheringResponse.from(g, haversineKm(lat, lng, g.getLatitude(), g.getLongitude())))
                .filter(r -> r.getDistanceKm() <= request.getRadiusKm())
                .sorted(Comparator.comparingDouble(GatheringResponse::getDistanceKm))
                .collect(Collectors.toList());
    }

    public GatheringResponse getById(Long gatheringId) {
        return GatheringResponse.from(findGathering(gatheringId));
    }

    @Transactional
    public void join(Long userId, Long gatheringId) {
        Gathering gathering = findGathering(gatheringId);

        if (gathering.getStatus() != GatheringStatus.OPEN) {
            throw new BusinessException(ErrorCode.GATHERING_CLOSED);
        }

        var existing = participantRepository.findByGatheringIdAndUserId(gatheringId, userId);
        if (existing.isPresent()) {
            GatheringParticipant p = existing.get();
            if (p.getStatus() == ParticipantStatus.APPROVED) throw new BusinessException(ErrorCode.ALREADY_JOINED);
            if (p.getStatus() == ParticipantStatus.PENDING) throw new BusinessException(ErrorCode.ALREADY_PENDING);
        }

        Long hostId = gathering.getHost().getId();
        if (userBlockService.getExcludedUserIds(userId).contains(hostId)) {
            throw new BusinessException(ErrorCode.BLOCKED_USER);
        }

        long approvedCount = participantRepository.countByGatheringIdAndStatus(gatheringId, ParticipantStatus.APPROVED);
        if (approvedCount >= gathering.getMaxParticipants()) {
            throw new BusinessException(ErrorCode.GATHERING_FULL);
        }

        User joiner = findUser(userId);

        if (existing.isPresent()) {
            // REJECTED → 상태만 PENDING으로 초기화 (delete+create 시 유니크 제약 위반 방지)
            existing.get().resetToPending();
        } else {
            participantRepository.save(GatheringParticipant.builder()
                    .gathering(gathering)
                    .user(joiner)
                    .status(ParticipantStatus.PENDING)
                    .build());
        }

        fcmService.sendToUser(
                hostId,
                "새 참가 신청",
                joiner.getNickname() + "님이 '" + gathering.getTitle() + "'에 참가를 신청했습니다.");
    }

    @Transactional
    public void approve(Long hostId, Long gatheringId, Long targetUserId) {
        Gathering gathering = findGathering(gatheringId);
        if (!gathering.isHost(hostId)) {
            throw new BusinessException(ErrorCode.NOT_GATHERING_HOST);
        }

        GatheringParticipant participant = participantRepository
                .findByGatheringIdAndUserId(gatheringId, targetUserId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PARTICIPANT_NOT_FOUND));

        if (participant.getStatus() != ParticipantStatus.PENDING) {
            throw new BusinessException(ErrorCode.INVALID_INPUT);
        }

        long approvedCount = participantRepository.countByGatheringIdAndStatus(gatheringId, ParticipantStatus.APPROVED);
        if (approvedCount >= gathering.getMaxParticipants()) {
            throw new BusinessException(ErrorCode.GATHERING_FULL);
        }

        participant.approve();

        if (approvedCount + 1 >= gathering.getMaxParticipants()) {
            gathering.close();
        }

        fcmService.sendToUser(
                targetUserId,
                "참가 승인",
                "'" + gathering.getTitle() + "' 모임 참가가 승인되었습니다!");
    }

    @Transactional
    public void reject(Long hostId, Long gatheringId, Long targetUserId) {
        Gathering gathering = findGathering(gatheringId);
        if (!gathering.isHost(hostId)) {
            throw new BusinessException(ErrorCode.NOT_GATHERING_HOST);
        }

        GatheringParticipant participant = participantRepository
                .findByGatheringIdAndUserId(gatheringId, targetUserId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PARTICIPANT_NOT_FOUND));

        if (participant.getStatus() != ParticipantStatus.PENDING) {
            throw new BusinessException(ErrorCode.INVALID_INPUT);
        }

        participant.reject();

        fcmService.sendToUser(
                targetUserId,
                "참가 거절",
                "'" + gathering.getTitle() + "' 모임 참가 신청이 거절되었습니다.");
    }

    public List<ParticipantResponse> getPendingParticipants(Long hostId, Long gatheringId) {
        Gathering gathering = findGathering(gatheringId);
        if (!gathering.isHost(hostId)) {
            throw new BusinessException(ErrorCode.NOT_GATHERING_HOST);
        }
        return participantRepository.findByGatheringIdAndStatusWithUser(gatheringId, ParticipantStatus.PENDING)
                .stream()
                .map(p -> ParticipantResponse.from(p, hostId))
                .toList();
    }

    public String getMyParticipationStatus(Long userId, Long gatheringId) {
        return participantRepository.findByGatheringIdAndUserId(gatheringId, userId)
                .map(p -> p.getStatus().name())
                .orElse("NONE");
    }

    @Transactional
    public void leave(Long userId, Long gatheringId) {
        Gathering gathering = findGathering(gatheringId);

        if (gathering.isHost(userId)) {
            throw new BusinessException(ErrorCode.HOST_CANNOT_LEAVE);
        }

        GatheringParticipant participant = participantRepository
                .findByGatheringIdAndUserId(gatheringId, userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_JOINED));

        boolean wasApproved = participant.getStatus() == ParticipantStatus.APPROVED;
        participantRepository.delete(participant);

        if (wasApproved && gathering.getStatus() == GatheringStatus.CLOSED) {
            gathering.reopen();
        }
    }

    @Transactional
    public void cancel(Long userId, Long gatheringId) {
        Gathering gathering = findGathering(gatheringId);
        if (!gathering.isHost(userId)) {
            throw new BusinessException(ErrorCode.NOT_GATHERING_HOST);
        }
        gathering.cancel();
    }

    @Transactional
    public void complete(Long userId, Long gatheringId) {
        Gathering gathering = findGathering(gatheringId);
        if (!gathering.isHost(userId)) {
            throw new BusinessException(ErrorCode.NOT_GATHERING_HOST);
        }
        if (gathering.getStatus() == GatheringStatus.CANCELLED
                || gathering.getStatus() == GatheringStatus.COMPLETED) {
            throw new BusinessException(ErrorCode.GATHERING_CANNOT_UPDATE);
        }
        gathering.complete();
    }

    @Transactional
    public GatheringResponse update(Long userId, Long gatheringId, GatheringUpdateRequest request) {
        Gathering gathering = findGathering(gatheringId);
        if (!gathering.isHost(userId)) {
            throw new BusinessException(ErrorCode.NOT_GATHERING_HOST);
        }
        if (gathering.getStatus() == GatheringStatus.CANCELLED
                || gathering.getStatus() == GatheringStatus.COMPLETED) {
            throw new BusinessException(ErrorCode.GATHERING_CANNOT_UPDATE);
        }
        if (request.getMaxParticipants() != null) {
            long approvedCount = participantRepository.countByGatheringIdAndStatus(gatheringId, ParticipantStatus.APPROVED);
            if (request.getMaxParticipants() < approvedCount) {
                throw new BusinessException(ErrorCode.INVALID_MAX_PARTICIPANTS);
            }
        }
        gathering.update(
                request.getTitle(), request.getDescription(), request.getRestaurantName(),
                request.getAddress(), request.getCategory(), request.getMaxParticipants(), request.getMealTime());
        return GatheringResponse.from(gathering);
    }

    public List<ParticipantResponse> getParticipants(Long gatheringId) {
        Gathering gathering = findGathering(gatheringId);
        Long hostId = gathering.getHost().getId();
        return participantRepository.findByGatheringIdAndStatusWithUser(gatheringId, ParticipantStatus.APPROVED)
                .stream()
                .map(p -> ParticipantResponse.from(p, hostId))
                .toList();
    }

    public List<GatheringResponse> getMyHosted(Long userId) {
        return gatheringRepository.findByHostId(userId).stream()
                .map(GatheringResponse::from)
                .collect(Collectors.toList());
    }

    public List<GatheringResponse> getMyJoined(Long userId) {
        return gatheringRepository.findJoinedByUserId(userId, ParticipantStatus.APPROVED).stream()
                .map(GatheringResponse::from)
                .collect(Collectors.toList());
    }

    private Gathering findGathering(Long id) {
        return gatheringRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.GATHERING_NOT_FOUND));
    }

    private User findUser(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
    }

    private double haversineKm(double lat1, double lng1, double lat2, double lng2) {
        final double R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
