package com.ssafy.ollana.security.auth.service;

import com.ssafy.ollana.security.auth.dto.request.LoginRequestDto;
import com.ssafy.ollana.security.auth.dto.request.SignupRequestDto;
import com.ssafy.ollana.security.jwt.JwtUtil;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.enums.Gender;
import com.ssafy.ollana.user.enums.Grade;
import com.ssafy.ollana.user.repository.UserRepository;
import com.ssafy.ollana.util.Response;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @Override
    public ResponseEntity<?> signup(SignupRequestDto request) {

        // 이메일 중복 검사
        if (userRepository.existsByEmail(request.getEmail())) {
            return ResponseEntity.badRequest().body(Response.fail("이미 가입한 이메일입니다.", 400));
        }

        // 비밀번호 암호화
        String encodedPassword = passwordEncoder.encode(request.getPassword());

        // User 객체 생성
        User user = User.builder()
                .email(request.getEmail())
                .password(encodedPassword)
                .nickname(request.getNickname())
                .birth(request.getBirth())
                .gender(Gender.valueOf(request.getGender()))
                .grade(Grade.SEED)
                .profileImage(request.getProfileImageUrl() != null ? request.getProfileImageUrl() : null)
                .build();

        userRepository.save(user);

        return ResponseEntity.ok(Response.success());
    }

    @Override
    public ResponseEntity<?> login(LoginRequestDto request) {
        // 이메일로 사용자 찾기
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("존재하지 않는 이메일입니다."));

        // 비밀번호 확인
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("잘못된 비밀번호 입니다.");
        }

        // JWT 토큰 생성
        String accessToken = jwtUtil.createAccessToken(user.getEmail());
        String refreshToken = jwtUtil.createRefreshToken(user.getEmail());

        return ResponseEntity.ok()
    }
}
