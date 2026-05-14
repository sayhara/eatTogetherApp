package com.eattogether.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class UserUpdateRequest {

    @NotBlank(message = "닉네임은 필수입니다.")
    @Size(min = 2, max = 12, message = "닉네임은 2~12자 사이여야 합니다.")
    private String nickname;
}
