package com.eattogether.report.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class ReportCreateRequest {

    @NotBlank(message = "신고 사유는 필수입니다.")
    @Size(max = 100, message = "신고 사유는 100자 이내여야 합니다.")
    private String reason;

    @Size(max = 500, message = "상세 설명은 500자 이내여야 합니다.")
    private String description;
}
