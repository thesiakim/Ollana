package com.ssafy.ollana.security.auth.service;

import com.ssafy.ollana.security.auth.dto.request.LoginRequestDto;
import com.ssafy.ollana.security.auth.dto.request.SignupRequestDto;
import org.springframework.http.ResponseEntity;

public interface AuthService {
    ResponseEntity<?> signup(SignupRequestDto request);
    ResponseEntity<?> login(LoginRequestDto request);
}
