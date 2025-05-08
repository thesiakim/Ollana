package com.ssafy.ollana.auth.service;

import com.ssafy.ollana.auth.dto.KakaoProfileDto;
import com.ssafy.ollana.auth.dto.KakaoTokenDto;
import com.ssafy.ollana.auth.dto.TempUserDto;
import com.ssafy.ollana.auth.dto.request.KakaoSignupRequestDto;
import com.ssafy.ollana.auth.dto.request.LoginRequestDto;
import com.ssafy.ollana.auth.dto.request.SignupRequestDto;
import com.ssafy.ollana.auth.dto.response.AccessTokenResponseDto;
import com.ssafy.ollana.auth.dto.response.LoginResponseDto;
import com.ssafy.ollana.auth.exception.AdditionalInfoRequiredException;
import com.ssafy.ollana.auth.exception.AuthenticationException;
import com.ssafy.ollana.user.exception.NicknameAlreadyExistsException;
import com.ssafy.ollana.auth.exception.RefreshTokenException;
import com.ssafy.ollana.common.s3.service.S3Service;
import com.ssafy.ollana.security.jwt.JwtUtil;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.entity.Gender;
import com.ssafy.ollana.user.exception.DuplicateEmailException;
import com.ssafy.ollana.user.repository.UserRepository;
import com.ssafy.ollana.user.service.UserService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final UserService userService;
    private final TokenService tokenService;
    private final S3Service s3Service;
    private final KakaoService kakaoService;

    @Override
    @Transactional
    public void signup(SignupRequestDto request, MultipartFile profileImage) {

        // 이메일 중복 검사
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateEmailException();
        }

        // 닉네임 중복 검사
        if (userRepository.existsByNickname(request.getNickname())) {
            throw new NicknameAlreadyExistsException();
        }

        // 비밀번호 암호화
        String encodedPassword = passwordEncoder.encode(request.getPassword());

        // 프로필 이미지
        String profileImageUrl = null;
        if (profileImage != null && !profileImage.isEmpty()) {
            // S3 이미지 업로드
            profileImageUrl = s3Service.uploadFile(profileImage, "profile");
        } else {
            profileImageUrl = s3Service.getDefaultProfileImageUrl();
        }

        // User 객체 생성
        User user = User.builder()
                .email(request.getEmail())
                .password(encodedPassword)
                .nickname(request.getNickname())
                .birth(request.getBirth())
                .gender(Gender.valueOf(request.getGender()))
                .profileImage(profileImageUrl)
                .build();

        userRepository.save(user);
    }

    @Override
    public LoginResponseDto login(LoginRequestDto request, HttpServletResponse response) {
        // 이메일로 사용자 찾기
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> AuthenticationException.userNotFound());

        // 비밀번호 일치 확인
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw AuthenticationException.passwordMismatch();
        }

        return generateAuthTokensAndResponse(user, response);
    }

    @Override
    @Transactional(readOnly = true)
    public LoginResponseDto kakaoLogin(String accessCode, HttpServletResponse response) {
        // kakao 에 access token 요청
        KakaoTokenDto kakaoTokenDto = kakaoService.getAccessToken(accessCode);
        // kakao 에 사용자 정보 요청
        KakaoProfileDto kakaoProfileDto = kakaoService.getKakaoProfile(kakaoTokenDto);

        // user 가입 여부 확인
        Optional<User> userOpt = userRepository.findByEmail(kakaoProfileDto.getKakaoAccount().getEmail());

        // 이미 가입된 유저 -> 로그인
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            return generateAuthTokensAndResponse(user, response);
        } else {
            // 가입 X -> 카카오 정보를 넣은 dto 생성 -> 추가 정보 입력 (프론트) -> 유저 생성(/auth/oauth/kakao/complete)
            TempUserDto tempUser = TempUserDto.builder()
                    .email(kakaoProfileDto.getKakaoAccount().getEmail())
                    .nickname(kakaoProfileDto.getKakaoAccount().getProfile().getNickname())
                    .profileImage(kakaoProfileDto.getKakaoAccount().getProfile().isDefaultImage()
                            ? s3Service.getDefaultProfileImageUrl()
                            : kakaoProfileDto.getKakaoAccount().getProfile().getProfileImageUrl())
                    .socialLogin(true)
                    .build();

            throw new AdditionalInfoRequiredException(tempUser);
        }
    }

    @Override
    @Transactional
    public LoginResponseDto saveKakaoUserAndLogin(KakaoSignupRequestDto request, HttpServletResponse response) {
        User newUser = User.builder()
                .email(request.getEmail())
                .nickname(request.getNickname())
                .birth(request.getBirth())
                .gender(Gender.valueOf(request.getGender()))
                .profileImage(request.getProfileImage())
                .isSocial(request.isSocial())
                .build();
        userRepository.save(newUser);

        return generateAuthTokensAndResponse(newUser, response);
    }

    @Override
    public void logout(HttpServletRequest request, HttpServletResponse response) {
        String refreshToken = extractRefreshTokenFromCookie(request);

        if (refreshToken != null) {
            String userEmail = jwtUtil.getUserEmailFromToken(refreshToken);

            // redis에서 리프레시 토큰 삭제
            tokenService.deleteRefreshToken(userEmail);
        }

        // 리프레시 토큰 쿠키 삭제
        Cookie cookie = new Cookie("refreshToken", "");
        cookie.setHttpOnly(true);
        cookie.setSecure(true);
        cookie.setPath("/");
        cookie.setMaxAge(0);        // 즉시 만료
        response.addCookie(cookie); // 삭제용 쿠키를 응답에 추가
    }

    @Override
    public AccessTokenResponseDto refreshToken(HttpServletRequest request) {
        String refreshToken = extractRefreshTokenFromCookie(request);

        if (refreshToken == null) {
            throw RefreshTokenException.notFound();
        }

        // 토큰 유효성 검사
        if (!jwtUtil.validateToken(refreshToken)) {
            throw RefreshTokenException.invalid();
        }

        // 토큰에서 userEmail 추출
        String userEmail = jwtUtil.getUserEmailFromToken(refreshToken);

        // redis에 저장된 리프레시 토큰과 비교
        if (!tokenService.validateRefreshToken(userEmail, refreshToken)) {
            throw RefreshTokenException.mismatch();
        }

        // 새로운 액세스 토큰 발급
        String newAccessToken = jwtUtil.createAccessToken(userEmail);

        AccessTokenResponseDto response = AccessTokenResponseDto.builder()
                .accessToken(newAccessToken)
                .build();

        return response;
    }


    // 쿠키에서 리프레시 토큰 추출
    private String extractRefreshTokenFromCookie(HttpServletRequest request) {
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if (cookie.getName().equals("refreshToken")) {
                    return cookie.getValue();
                }
            }
        }
        return null;
    }

    // 헤더에서 액세스 토큰 추출
    private String extractAccessTokenFromHeader(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return null;
    }

    // 로그인
    private LoginResponseDto generateAuthTokensAndResponse(User user, HttpServletResponse response) {
        // JWT 토큰 생성
        String accessToken = jwtUtil.createAccessToken(user.getEmail());
        String refreshToken = jwtUtil.createRefreshToken(user.getEmail());

        // 리프레시 토큰 레디스 저장
        tokenService.saveRefreshToken(user.getEmail(), refreshToken);

        // refreshToken을 HTTP-only 쿠키로 설정
        Cookie refreshCookie = new Cookie("refreshToken", refreshToken);
        refreshCookie.setHttpOnly(true);  // JavaScript에서 접근 불가
        refreshCookie.setSecure(true);    // HTTPS에서만 전송
        refreshCookie.setPath("/");       // 모든 경로에서 접근 가능
        refreshCookie.setMaxAge((int) (jwtUtil.getRefreshTokenExpiration() / 1000)); // 초 단위로 변환
        response.addCookie(refreshCookie); // 쿠키를 응답에 추가

        LoginResponseDto loginResponse = LoginResponseDto.builder()
                .accessToken(accessToken)
                .user(userService.getUserInfo(user))
                .latestRecord(userService.getLatestRecord(user))
                .build();

        return loginResponse;
    }
}
