package com.ssafy.ollana.auth.controller;

import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.auth.dto.request.LoginRequestDto;
import com.ssafy.ollana.auth.dto.request.SignupRequestDto;
import com.ssafy.ollana.auth.dto.response.LoginResponseDto;
import com.ssafy.ollana.auth.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/signup")
    public ResponseEntity<Response<Void>> signup(@RequestBody SignupRequestDto request) {
        authService.signup(request);
        return ResponseEntity.ok(Response.success());
    }

    @PostMapping("/login")
    public ResponseEntity<Response<LoginResponseDto>> login(@RequestBody LoginRequestDto request) {
        LoginResponseDto response = authService.login(request);
        return ResponseEntity.ok(Response.success(response));
    }
}
