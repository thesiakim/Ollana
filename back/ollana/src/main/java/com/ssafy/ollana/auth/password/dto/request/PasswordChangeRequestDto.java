package com.ssafy.ollana.auth.password.dto.request;

import lombok.Getter;

@Getter
public class PasswordChangeRequestDto {
    private String token;
    private String newPassword;
}
