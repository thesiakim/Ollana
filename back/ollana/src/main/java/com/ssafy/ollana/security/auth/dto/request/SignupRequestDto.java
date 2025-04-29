package com.ssafy.ollana.security.auth.dto.request;

import lombok.Getter;

@Getter
public class SignupRequestDto {
    private String email;
    private String password;
    private String nickname;
    private String birth;
    private String gender;
    private String profileImageUrl;
}
