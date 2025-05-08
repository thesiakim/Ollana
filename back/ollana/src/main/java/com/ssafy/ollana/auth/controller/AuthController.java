package com.ssafy.ollana.auth.controller;

import com.ssafy.ollana.auth.dto.request.*;
import com.ssafy.ollana.auth.dto.response.AccessTokenResponseDto;
import com.ssafy.ollana.auth.service.MailService;
import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.auth.dto.response.LoginResponseDto;
import com.ssafy.ollana.auth.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final MailService mailService;

    @PostMapping("/signup")
    public ResponseEntity<Response<Void>> signup(
            @Valid @RequestPart("userData") SignupRequestDto request,
            @RequestPart(value = "profileImage", required = false) MultipartFile profileImage) {
        authService.signup(request, profileImage);
        return ResponseEntity.ok(Response.success());
    }

    @PostMapping("/email/send")
    public ResponseEntity<Response<Void>> sendEmail(@RequestBody EmailSendRequestDto request) {
        mailService.sendMail(request);
        return ResponseEntity.ok(Response.success());
    }

    @PostMapping("/email/verify")
    public ResponseEntity<Response<Void>> verifyEmail(@RequestBody EmailVerifyRequestDto request) {
        mailService.verifyCode(request);
        return ResponseEntity.ok(Response.success());
    }

    @PostMapping("/login")
    public ResponseEntity<Response<LoginResponseDto>> login(@RequestBody LoginRequestDto request, HttpServletResponse response) {
        LoginResponseDto loginResponse = authService.login(request, response);
        return ResponseEntity.ok(Response.success(loginResponse));
    }

    @PostMapping("/logout")
    public ResponseEntity<Response<Void>> logout(HttpServletRequest request, HttpServletResponse response) {
        authService.logout(request, response);
        return ResponseEntity.ok(Response.success());
    }

    // 이미 회원 -> 로그인
    // 회원 X -> 회원가입 (카카오 데이터까지 저장한 채로 response)
    @GetMapping("/oauth/kakao")
    public ResponseEntity<Response<LoginResponseDto>> kakaoLogin(@RequestParam("code") String accessCode, HttpServletResponse response) {
        LoginResponseDto loginResponse = authService.kakaoLogin(accessCode, response);
        return ResponseEntity.ok(Response.success(loginResponse));
    }

    // 추가 정보를 request로 받아서 카카오 회원가입 마무리
    // user 저장 후 로그인까지
    @PostMapping("/oauth/kakao/complete")
    public ResponseEntity<Response<LoginResponseDto>> completeKakaoSignup(@RequestBody KakaoSignupRequestDto request, HttpServletResponse response) {
        LoginResponseDto loginResponseDto = authService.saveKakaoUserAndLogin(request, response);
        return ResponseEntity.ok(Response.success(loginResponseDto));
    }

    // 리프레시 토큰으로 새로운 액세스 토큰 생성
    @PostMapping("/refresh")
    public ResponseEntity<Response<AccessTokenResponseDto>> refreshToken(HttpServletRequest request) {
        AccessTokenResponseDto response = authService.refreshToken(request);
        return ResponseEntity.ok(Response.success(response));
    }
}
