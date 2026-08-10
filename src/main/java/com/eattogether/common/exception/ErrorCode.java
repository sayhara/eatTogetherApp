package com.eattogether.common.exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum ErrorCode {

    // Common
    INVALID_INPUT(HttpStatus.BAD_REQUEST, "잘못된 입력입니다."),
    UNAUTHORIZED(HttpStatus.UNAUTHORIZED, "인증이 필요합니다."),
    FORBIDDEN(HttpStatus.FORBIDDEN, "접근 권한이 없습니다."),
    NOT_FOUND(HttpStatus.NOT_FOUND, "리소스를 찾을 수 없습니다."),
    INTERNAL_SERVER_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "서버 오류가 발생했습니다."),

    // Auth
    INVALID_TOKEN(HttpStatus.UNAUTHORIZED, "유효하지 않은 토큰입니다."),
    EXPIRED_TOKEN(HttpStatus.UNAUTHORIZED, "만료된 토큰입니다."),
    INVALID_REFRESH_TOKEN(HttpStatus.UNAUTHORIZED, "유효하지 않은 리프레시 토큰입니다."),
    INVALID_LINK_TOKEN(HttpStatus.BAD_REQUEST, "유효하지 않거나 만료된 연동 요청입니다."),

    // User
    USER_NOT_FOUND(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."),
    DUPLICATE_NICKNAME(HttpStatus.CONFLICT, "이미 사용 중인 닉네임입니다."),

    // Gathering
    GATHERING_NOT_FOUND(HttpStatus.NOT_FOUND, "모임을 찾을 수 없습니다."),
    GATHERING_FULL(HttpStatus.CONFLICT, "모임 정원이 가득 찼습니다."),
    ALREADY_JOINED(HttpStatus.CONFLICT, "이미 참가한 모임입니다."),
    ALREADY_PENDING(HttpStatus.CONFLICT, "이미 참가 신청한 모임입니다."),
    NOT_JOINED(HttpStatus.BAD_REQUEST, "참가하지 않은 모임입니다."),
    PARTICIPANT_NOT_FOUND(HttpStatus.NOT_FOUND, "참가 신청을 찾을 수 없습니다."),
    NOT_GATHERING_HOST(HttpStatus.FORBIDDEN, "모임 주최자가 아닙니다."),
    GATHERING_CLOSED(HttpStatus.BAD_REQUEST, "마감된 모임입니다."),
    HOST_CANNOT_LEAVE(HttpStatus.BAD_REQUEST, "주최자는 모임에서 나갈 수 없습니다."),
    GATHERING_CANNOT_UPDATE(HttpStatus.BAD_REQUEST, "취소되거나 완료된 모임은 수정할 수 없습니다."),
    INVALID_MAX_PARTICIPANTS(HttpStatus.BAD_REQUEST, "현재 참가자 수보다 적게 설정할 수 없습니다."),

    // Review
    GATHERING_NOT_COMPLETED(HttpStatus.BAD_REQUEST, "완료된 모임에만 리뷰를 작성할 수 있습니다."),
    CANNOT_REVIEW_YOURSELF(HttpStatus.BAD_REQUEST, "자기 자신을 리뷰할 수 없습니다."),
    REVIEWEE_NOT_PARTICIPANT(HttpStatus.BAD_REQUEST, "리뷰 대상자가 해당 모임의 참가자가 아닙니다."),
    ALREADY_REVIEWED(HttpStatus.CONFLICT, "이미 리뷰를 작성했습니다."),

    // Report
    CANNOT_REPORT_YOURSELF(HttpStatus.BAD_REQUEST, "자기 자신을 신고할 수 없습니다."),
    ALREADY_REPORTED(HttpStatus.CONFLICT, "이미 신고한 대상입니다."),

    // Block
    CANNOT_BLOCK_YOURSELF(HttpStatus.BAD_REQUEST, "자기 자신을 차단할 수 없습니다."),
    ALREADY_BLOCKED(HttpStatus.CONFLICT, "이미 차단한 사용자입니다."),
    NOT_BLOCKED(HttpStatus.BAD_REQUEST, "차단하지 않은 사용자입니다."),
    BLOCKED_USER(HttpStatus.FORBIDDEN, "차단 관계로 인해 이 작업을 수행할 수 없습니다."),

    // Rate Limit
    RATE_LIMIT_EXCEEDED(HttpStatus.TOO_MANY_REQUESTS, "요청 횟수가 초과되었습니다. 잠시 후 다시 시도해주세요.");

    private final HttpStatus status;
    private final String message;
}
