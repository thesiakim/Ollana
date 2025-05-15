package com.ssafy.ollana.auth.controller;

import com.ssafy.ollana.auth.dto.TempUserDto;
import com.ssafy.ollana.auth.dto.request.*;
import com.ssafy.ollana.auth.dto.response.AccessTokenResponseDto;
import com.ssafy.ollana.auth.dto.response.DeepLinkResponseDto;
import com.ssafy.ollana.auth.exception.InvalidTempTokenException;
import com.ssafy.ollana.auth.service.MailService;
import com.ssafy.ollana.auth.service.TokenService;
import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.auth.dto.response.LoginResponseDto;
import com.ssafy.ollana.auth.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final MailService mailService;
    private final TokenService tokenService;

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

    // 카카오 인증 후 딥링크 리다이렉트
    @GetMapping("/oauth/kakao")
    public void kakaoLogin(@RequestParam("code") String accessCode, HttpServletResponse response) {
        try {
            // 카카오 로그인 처리 및 딥링크 생성
            DeepLinkResponseDto deepLinkResponse = authService.processKakaoLogin(accessCode, response);

            // 딥링크로 리다이렉트
            response.sendRedirect(deepLinkResponse.getDeepLink());
            log.info("카카오 딥링크 리다이렉트");
        } catch (IOException e) {
            log.error("딥링크 리다이렉트 중 오류 발생", e);
            try {
                String errorLink = "ollana://auth/oauth/kakao/error?message=" + URLEncoder.encode("인증 처리 중 오류 발생", StandardCharsets.UTF_8);
                response.sendRedirect(errorLink);
            } catch (IOException ex) {
                log.error("에러 리다이렉트 중 추가 오류 발생", ex);
            }
        }
    }

    @GetMapping("/oauth/kakao/login")
    public ResponseEntity<Response<LoginResponseDto>> getLoginResponse(@RequestParam("token") String token) {
        // 토큰으로 로그인 정보 조회
        LoginResponseDto loginResponse = tokenService.getKakaoLoginResponse(token);
        return ResponseEntity.ok(Response.success(loginResponse));
    }

    // 임시 토큰으로 임시 사용자 정보 조회
    @GetMapping("/oauth/kakao/temp-user")
    public ResponseEntity<Response<TempUserDto>> getTempUser(@RequestParam("token") String token) {
        try {
            TempUserDto tempUserResponse = tokenService.getTempUserByToken(token);
            return ResponseEntity.ok(Response.success(tempUserResponse));
        } catch (InvalidTempTokenException e) {
            log.error("유효하지 않은 임시 토큰");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Response.fail("유효하지 않은 임시 토큰입니다.", e.getErrorCode()));
        }
    }

    // 카카오 회원가입 완료
    @PostMapping("/oauth/kakao/complete")
    public ResponseEntity<Response<LoginResponseDto>> completeKakaoSignup(@RequestBody KakaoSignupRequestDto request,
                                                                          HttpServletResponse response) {
        LoginResponseDto loginResponse = authService.saveKakaoUserAndLogin(request, response);
        tokenService.deleteTempUserByToken(request.getTempToken());
        return ResponseEntity.ok(Response.success(loginResponse));
    }






/*    // 이미 회원 -> 로그인
    // 회원 X -> 회원가입 (카카오 데이터까지 저장한 채로 response)
    @GetMapping("/oauth/kakao")
    public ResponseEntity<Response<LoginResponseDto>> kakaoLogin(@RequestParam("code") String accessCode, HttpServletResponse response) {
        LoginResponseDto loginResponse = authService.kakaoLogin(accessCode, response);
        String deepLink = "ollana://auth/oauth/kakao";
        return ResponseEntity.ok(Response.success(loginResponse));
    }

    // 추가 정보를 request로 받아서 카카오 회원가입 마무리
    // user 저장 후 로그인까지
    @PostMapping("/oauth/kakao/complete")
    public ResponseEntity<Response<LoginResponseDto>> completeKakaoSignup(@RequestBody KakaoSignupRequestDto request, HttpServletResponse response) {
        LoginResponseDto loginResponseDto = authService.saveKakaoUserAndLogin(request, response);
        return ResponseEntity.ok(Response.success(loginResponseDto));
    }*/
}
