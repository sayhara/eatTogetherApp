package com.eattogether.report.dto;

import com.eattogether.report.domain.Report;
import com.eattogether.report.domain.ReportStatus;
import com.eattogether.report.domain.ReportType;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class ReportResponse {
    private Long id;
    private Long reporterId;
    private ReportType type;
    private Long targetId;
    private String reason;
    private String description;
    private ReportStatus status;
    private LocalDateTime createdAt;

    public static ReportResponse from(Report report) {
        return ReportResponse.builder()
                .id(report.getId())
                .reporterId(report.getReporterId())
                .type(report.getType())
                .targetId(report.getTargetId())
                .reason(report.getReason())
                .description(report.getDescription())
                .status(report.getStatus())
                .createdAt(report.getCreatedAt())
                .build();
    }
}
