package com.ssafy.ollana.auth.password.service;

import com.ssafy.ollana.auth.password.dto.request.PasswordChangeRequestDto;
import com.ssafy.ollana.auth.password.dto.request.PasswordResetRequestDto;
import com.ssafy.ollana.auth.password.exception.InvalidPasswordResetTokenException;
import com.ssafy.ollana.auth.service.MailService;
import com.ssafy.ollana.auth.service.TokenService;
import com.ssafy.ollana.security.jwt.JwtUtil;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.exception.UserNotFoundException;
import com.ssafy.ollana.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PasswordService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final TokenService tokenService;
    private final MailService mailService;
    private final PasswordEncoder passwordEncoder;

    public void sendPasswordEmail(PasswordResetRequestDto request) {
        String email = request.getEmail();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException());

        // 이메일 존재 여부 확인
        if (!userRepository.existsByEmail(email)) {
            throw new UserNotFoundException();
        }

        // 비밀번호 재설정 토큰 생성
        String passwordResetToken = jwtUtil.createPasswordResetToken(String.valueOf(user.getId()));

        // redis에 토큰 저장
        tokenService.savePasswordResetToken(email, passwordResetToken);

        // 비밀번호 재설정 메일 발송
        mailService.sendPasswordResetMail(email, passwordResetToken);
    }

    @Transactional
    public void passwordChange(PasswordChangeRequestDto request) {
        // 토큰 검증
        if (!jwtUtil.validatePasswordResetToken(request.getToken())) {
            throw new InvalidPasswordResetTokenException();
        }

        // 토큰에서 user_id 추출 (subject에 user id를 넣어둬서 user id가 리턴됨)
        String userId = jwtUtil.getUserEmailFromToken(request.getToken());

        // user 존재 여부 확인
        User user = userRepository.findById(Integer.valueOf(userId))
                .orElseThrow(() -> new UserNotFoundException());

        // 새로운 비밀번호 설정
        String encodePassword = passwordEncoder.encode(request.getNewPassword());

        user.setPassword(encodePassword);
        userRepository.save(user);
    }
}
