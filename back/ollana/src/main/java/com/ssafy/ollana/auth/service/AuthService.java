package com.ssafy.ollana.auth.service;

import com.ssafy.ollana.auth.dto.request.LoginRequestDto;
import com.ssafy.ollana.auth.dto.request.SignupRequestDto;
import com.ssafy.ollana.auth.dto.response.LoginResponseDto;

public interface AuthService {
    void signup(SignupRequestDto request);
    LoginResponseDto login(LoginRequestDto request);
}
