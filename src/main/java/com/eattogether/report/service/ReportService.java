package com.eattogether.report.service;

import com.eattogether.common.exception.BusinessException;
import com.eattogether.common.exception.ErrorCode;
import com.eattogether.gathering.repository.GatheringRepository;
import com.eattogether.report.domain.Report;
import com.eattogether.report.domain.ReportType;
import com.eattogether.report.dto.ReportCreateRequest;
import com.eattogether.report.dto.ReportResponse;
import com.eattogether.report.repository.ReportRepository;
import com.eattogether.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReportService {

    private final ReportRepository reportRepository;
    private final UserRepository userRepository;
    private final GatheringRepository gatheringRepository;

    @Transactional
    public ReportResponse reportUser(Long reporterId, Long targetUserId, ReportCreateRequest request) {
        if (reporterId.equals(targetUserId)) {
            throw new BusinessException(ErrorCode.CANNOT_REPORT_YOURSELF);
        }
        if (!userRepository.existsById(targetUserId)) {
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
        if (reportRepository.existsByReporterIdAndTypeAndTargetId(reporterId, ReportType.USER, targetUserId)) {
            throw new BusinessException(ErrorCode.ALREADY_REPORTED);
        }

        Report report = reportRepository.save(Report.builder()
                .reporterId(reporterId)
                .type(ReportType.USER)
                .targetId(targetUserId)
                .reason(request.getReason())
                .description(request.getDescription())
                .build());

        return ReportResponse.from(report);
    }

    @Transactional
    public ReportResponse reportGathering(Long reporterId, Long gatheringId, ReportCreateRequest request) {
        if (!gatheringRepository.existsById(gatheringId)) {
            throw new BusinessException(ErrorCode.GATHERING_NOT_FOUND);
        }
        if (reportRepository.existsByReporterIdAndTypeAndTargetId(reporterId, ReportType.GATHERING, gatheringId)) {
            throw new BusinessException(ErrorCode.ALREADY_REPORTED);
        }

        Report report = reportRepository.save(Report.builder()
                .reporterId(reporterId)
                .type(ReportType.GATHERING)
                .targetId(gatheringId)
                .reason(request.getReason())
                .description(request.getDescription())
                .build());

        return ReportResponse.from(report);
    }
}
