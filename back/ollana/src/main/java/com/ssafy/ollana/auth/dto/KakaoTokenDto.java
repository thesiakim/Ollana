package com.ssafy.ollana.auth.dto;

import lombok.Getter;

@Getter
public class KakaoTokenDto {
    private String accessToken;
    private String tokenType;
    private String refreshToken;
    private int expiresIn;
    private String scope;
    private int refreshTokenExpiresIn;
}
