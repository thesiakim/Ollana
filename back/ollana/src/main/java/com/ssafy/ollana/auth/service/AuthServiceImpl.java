package com.ssafy.ollana.auth.service;

import com.ssafy.ollana.auth.dto.KakaoProfileDto;
import com.ssafy.ollana.auth.dto.KakaoTokenDto;
import com.ssafy.ollana.auth.dto.TempUserDto;
import com.ssafy.ollana.auth.dto.request.KakaoSignupRequestDto;
import com.ssafy.ollana.auth.dto.request.LoginRequestDto;
import com.ssafy.ollana.auth.dto.request.SignupRequestDto;
import com.ssafy.ollana.auth.dto.response.DeepLinkResponseDto;
import com.ssafy.ollana.auth.dto.response.LoginResponseDto;
import com.ssafy.ollana.auth.exception.AdditionalInfoRequiredException;
import com.ssafy.ollana.auth.exception.AuthenticationException;
import com.ssafy.ollana.user.exception.NicknameAlreadyExistsException;
import com.ssafy.ollana.common.s3.service.S3Service;
import com.ssafy.ollana.security.jwt.JwtUtil;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.entity.Gender;
import com.ssafy.ollana.user.exception.EmailAlreadyExistsException;
import com.ssafy.ollana.user.repository.UserRepository;
import com.ssafy.ollana.user.service.UserService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
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
            throw new EmailAlreadyExistsException();
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
        log.info("new user: userId={}", user.getId());
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

        log.info("user login: userId={}", user.getId());
        return generateAuthTokensAndResponse(user, response);
    }

//    @Override
//    @Transactional(readOnly = true)
//    public LoginResponseDto kakaoLogin(String accessCode, HttpServletResponse response) {
//        // kakao 에 access token 요청
//        KakaoTokenDto kakaoTokenDto = kakaoService.getAccessToken(accessCode);
//        // kakao 에 사용자 정보 요청
//        KakaoProfileDto kakaoProfileDto = kakaoService.getKakaoProfile(kakaoTokenDto);
//
//        // user 가입 여부 확인
//        Optional<User> userOpt = userRepository.findByEmail(kakaoProfileDto.getKakaoAccount().getEmail());
//
//        // 이미 가입된 유저 -> 로그인
//        if (userOpt.isPresent()) {
//            User user = userOpt.get();
//            return generateAuthTokensAndResponse(user, response);
//        } else {
//            // 가입 X -> 카카오 정보를 넣은 dto 생성 -> 추가 정보 입력 (프론트) -> 유저 생성(/auth/oauth/kakao/complete)
//            // 필수 동의 항목 (이메일, 닉네임)
//            TempUserDto.TempUserDtoBuilder builder = TempUserDto.builder()
//                    .email(kakaoProfileDto.getKakaoAccount().getEmail())
//                    .nickname(kakaoProfileDto.getKakaoAccount().getProfile().getNickname())
//                    .kakaoId(kakaoProfileDto.getKakaoId())
//                    .socialLogin(true);
//
//            // 선택 동의 (프로필 이미지)
//            // 동의 O
//            if (!kakaoProfileDto.getKakaoAccount().isProfileImageNeedsAgreement()) {
//                // 기본 프로필 이미지 => ollana 기본 프로필 이미지 제공
//                if (kakaoProfileDto.getKakaoAccount().getProfile().isDefaultImage()) {
//                    builder.profileImage(s3Service.getDefaultProfileImageUrl());
//                } else {
//                    builder.profileImage(kakaoProfileDto.getKakaoAccount().getProfile().getProfileImageUrl());
//                }
//            } else {
//                // 동의 X => ollana 기본 프로필 이미지 제공
//                builder.profileImage(s3Service.getDefaultProfileImageUrl());
//            }
//
//            TempUserDto tempUser = builder.build();
//
//            throw new AdditionalInfoRequiredException(tempUser);
//        }
//    }

//    @Override
//    @Transactional
//    public LoginResponseDto saveKakaoUserAndLogin(KakaoSignupRequestDto request, HttpServletResponse response) {
//        User newUser = User.builder()
//                .email(request.getEmail())
//                .nickname(request.getNickname())
//                .birth(request.getBirth())
//                .gender(Gender.valueOf(request.getGender()))
//                .profileImage(request.getProfileImage())
//                .kakaoId(request.getKakaoId())
//                .isSocial(request.isSocial())
//                .build();
//        userRepository.save(newUser);
//        log.info("new user(kakao): userId={}", newUser.getId());
//
//        return generateAuthTokensAndResponse(newUser, response);
//    }

    @Override
    public void logout(HttpServletRequest request, HttpServletResponse response) {
        String refreshToken = tokenService.extractRefreshTokenFromCookie(request);

        if (refreshToken != null) {
            String userEmail = jwtUtil.getUserEmailFromToken(refreshToken);

            // redis에서 리프레시 토큰 삭제
            tokenService.deleteRefreshToken(userEmail);
        }

        // 액세스 토큰 블랙리스트에 추가
        String accessToken = tokenService.extractAccessTokenFromHeader(request);
        if (accessToken != null) {
            // 토큰 남은 유효시간
            long tokenRemainingTime = jwtUtil.getTokenRemainingTime(accessToken);

            if (tokenRemainingTime > 0) {
                // 남은 유효시간 만큼 저장
                tokenService.blacklistAccessToken(accessToken, tokenRemainingTime);
            }
        }

        // 리프레시 토큰 쿠키 삭제
        Cookie cookie = tokenService.createExpiredRefreshTokenCookie();
        response.addCookie(cookie); // 삭제용 쿠키를 응답에 추가
    }


    // 로그인
    private LoginResponseDto generateAuthTokensAndResponse(User user, HttpServletResponse response) {
        // JWT 토큰 생성
        String accessToken = jwtUtil.createAccessToken(user.getEmail(), user.getId());
        String refreshToken = jwtUtil.createRefreshToken(user.getEmail(), user.getId());

        System.out.println("accessToken = " + accessToken);
        System.out.println("refreshToken = " + refreshToken);

        // 리프레시 토큰 레디스 저장
        tokenService.saveRefreshToken(user.getEmail(), refreshToken);

        // refreshToken을 HTTP-only 쿠키로 설정
        Cookie refreshCookie = tokenService.createRefreshTokenCookie(refreshToken);
        response.addCookie(refreshCookie); // 쿠키를 응답에 추가

        LoginResponseDto loginResponse = LoginResponseDto.builder()
                .accessToken(accessToken)
                .user(userService.getUserInfo(user))
                .latestRecord(userService.getLatestRecord(user))
                .build();

        System.out.println("loginResponse.getAccessToken() = " + loginResponse.getAccessToken());

        return loginResponse;
    }



    // 회원가입 || 로그인 분기점
    @Override
    @Transactional(readOnly = true)
    public DeepLinkResponseDto processKakaoLogin(String accessCode, HttpServletResponse response) {
        try {
            // 카카오 로그인 시도
            kakaoLogin(accessCode, response);

            // 로그인 하면 앱으로 돌아가기
            return DeepLinkResponseDto.builder()
                    .deepLink("ollana://auth/oauth/kakao?status=login")
                    .isNewUser(false)
                    .build();

        // 회원이 아니면 추가 정보 입력 필요
        } catch (AdditionalInfoRequiredException e) {
            TempUserDto tempUser = e.getTempUser();
            String tempToken = kakaoService.generateKakaoTempToken(tempUser);

            return DeepLinkResponseDto.builder()
                    .deepLink("ollana://auth/oauth/kakao?status=signup&temp_token=" + tempToken)
                    .isNewUser(true)
                    .build();
        }
    }

    private LoginResponseDto kakaoLogin(String accessCode, HttpServletResponse response) {
        // kakao에 access token 요청
        KakaoTokenDto kakaoTokenDto = kakaoService.getAccessToken(accessCode);
        // kakao에 사용자 정보 요청
        KakaoProfileDto kakaoProfileDto = kakaoService.getKakaoProfile(kakaoTokenDto);

        // user 가입 여부 확인
        Optional<User> userOpt = userRepository.findByEmail(kakaoProfileDto.getKakaoAccount().getEmail());

        // 이미 가입된 유저 => 로그인
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            return generateAuthTokensAndResponse(user, response);
        } else {
            // 가입 X => 카카오 정보를 넣은 dto 생성 -> 추가 정보 입력 (프론트) -> 유저 생성(/auth/oauth/kakao/complete)
            // 필수 동의 항목 (이메일, 닉네임)
            TempUserDto.TempUserDtoBuilder builder = TempUserDto.builder()
                    .email(kakaoProfileDto.getKakaoAccount().getEmail())
                    .nickname(kakaoProfileDto.getKakaoAccount().getProfile().getNickname())
                    .kakaoId(kakaoProfileDto.getKakaoId())
                    .socialLogin(true);

            // 선택 동의 (프로필 이미지)
            // 동의 O
            if (!kakaoProfileDto.getKakaoAccount().isProfileImageNeedsAgreement()) {
                // kakao 기본 프로필 이미지 => ollana 기본 프로필 이미지 제공
                if (kakaoProfileDto.getKakaoAccount().getProfile().isDefaultImage()) {
                    builder.profileImage(s3Service.getDefaultProfileImageUrl());
                } else {
                    builder.profileImage(kakaoProfileDto.getKakaoAccount().getProfile().getProfileImageUrl());
                }
            } else {
                // 동의 X
                builder.profileImage(s3Service.getDefaultProfileImageUrl());
            }

            TempUserDto tempUser = builder.build();
            throw new AdditionalInfoRequiredException(tempUser);
        }
    }

    @Override
    @Transactional
    public LoginResponseDto saveKakaoUserAndLogin(KakaoSignupRequestDto request, HttpServletResponse response) {
        // 이메일 중복 검사
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new EmailAlreadyExistsException();
        }

        // 닉네임 중복 검사
        if (userRepository.existsByNickname(request.getNickname())) {
            throw new NicknameAlreadyExistsException();
        }

        User newUser = User.builder()
                .email(request.getEmail())
                .nickname(request.getNickname())
                .birth(request.getBirth())
                .gender(Gender.valueOf(request.getGender()))
                .profileImage(request.getProfileImage())
                .kakaoId(request.getKakaoId())
                .isSocial(request.isSocial())
                .build();

        userRepository.save(newUser);
        log.info("new user(kakao): userId={}", newUser.getId());

        // 회원가입 후 로그인 처리 및 응답 생성
        return generateAuthTokensAndResponse(newUser, response);
    }

}
