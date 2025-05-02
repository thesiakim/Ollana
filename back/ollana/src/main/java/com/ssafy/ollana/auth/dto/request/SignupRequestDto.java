package com.ssafy.ollana.auth.dto.request;

import lombok.Getter;

@Getter
public class SignupRequestDto {
    private String email;
    private String password;
    private String nickname;
    private String birth;
    private String gender;
}
