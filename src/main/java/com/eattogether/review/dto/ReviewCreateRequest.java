package com.eattogether.review.dto;

import jakarta.validation.constraints.*;
import lombok.Getter;

@Getter
public class ReviewCreateRequest {

    @NotNull(message = "리뷰 대상자 ID는 필수입니다.")
    private Long revieweeId;

    @NotNull(message = "별점은 필수입니다.")
    @Min(value = 1, message = "별점은 최소 1점입니다.")
    @Max(value = 5, message = "별점은 최대 5점입니다.")
    private Integer rating;

    @Size(max = 200, message = "코멘트는 200자 이내여야 합니다.")
    private String comment;
}
