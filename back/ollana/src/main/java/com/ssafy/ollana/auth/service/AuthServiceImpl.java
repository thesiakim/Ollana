package com.ssafy.ollana.auth.service;

import com.ssafy.ollana.auth.dto.request.LoginRequestDto;
import com.ssafy.ollana.auth.dto.request.SignupRequestDto;
import com.ssafy.ollana.auth.dto.response.LoginResponseDto;
import com.ssafy.ollana.security.jwt.JwtUtil;
import com.ssafy.ollana.user.dto.UserInfoDto;
import com.ssafy.ollana.user.dto.LatestRecordDto;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.enums.Gender;
import com.ssafy.ollana.user.exception.DuplicateEmailException;
import com.ssafy.ollana.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @Override
    public void signup(SignupRequestDto request) {

        // 이메일 중복 검사
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateEmailException();
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
                .profileImage(request.getProfileImageUrl() != null ? request.getProfileImageUrl() : null)
                .build();

        userRepository.save(user);
    }

    @Override
    public LoginResponseDto login(LoginRequestDto request) {
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

        // 사용자 정보
        UserInfoDto userInfo = UserInfoDto.builder()
                .email(user.getEmail())
                .nickname(user.getNickname())
                .exp(user.getExp())
                .grade(String.valueOf(user.getGrade()))
                .totalDistance(user.getTotalDistance())
                .build();

        // 최근 등산 기록
        LatestRecordDto latestRecord = LatestRecordDto.builder().build();

        LoginResponseDto response = LoginResponseDto.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .user(userInfo)
                .latestRecord(latestRecord)
                .build();

        return response;
    }
}
