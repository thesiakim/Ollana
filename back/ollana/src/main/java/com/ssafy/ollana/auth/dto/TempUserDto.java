package com.ssafy.ollana.auth.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TempUserDto {
    private String email;
    private String nickname;
    private String profileImage;
    private Long kakaoId;
    private boolean isSocial;
}
