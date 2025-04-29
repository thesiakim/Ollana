package com.ssafy.ollana.security.auth.dto.response;

import lombok.Getter;

@Getter
public class LoginResponseDto {
    private String accessToken;
    private String refreshToken;
}
