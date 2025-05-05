package com.ssafy.ollana.auth.service;

import com.ssafy.ollana.security.jwt.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class TokenService {

    private final RedisTemplate<String, String> redisTemplate;
    private final JwtUtil jwtUtil;

    // redis에 리프레시 토큰 저장
    public void saveRefreshToken(String userEmail, String refreshToken) {
        // 키 형식: "RT:{userEmail}"
        String key = "RT:" + userEmail;
        long expiration = jwtUtil.getRefreshTokenExpiration() / 1000; // redis는 초 단위로 만료 시간 설정
        redisTemplate.opsForValue().set(key, refreshToken, expiration, TimeUnit.SECONDS);
    }

    // user의 리프레시 토큰 조회
    public String getRefreshToken(String userEmail) {
        String key = "RT:" + userEmail;
        String token = redisTemplate.opsForValue().get(key);
        return token;
    }

    // 로그아웃 시 user의 리프레시 토큰 삭제
    public void deleteRefreshToken(String userEmail) {
        String key = "RT:" + userEmail;
        redisTemplate.delete(key);
    }

    // 리프레시 토큰이 redis에 저장된 토큰과 일치하는지 검사
    public boolean validateRefreshToken(String userEmail, String refreshToken) {
        String storedToken = getRefreshToken(userEmail);
        boolean isValid = storedToken != null && storedToken.equals(refreshToken);
        return isValid;
    }

    // password reset token을 redis에 저장
    public void savePasswordResetToken( String userEmail, String passwordResetToken) {
        String key = "PRT:" + userEmail;
        long expiration = jwtUtil.getPasswordResetTokenExpiration() / 1000;
        redisTemplate.opsForValue().set(key, passwordResetToken, expiration, TimeUnit.SECONDS);
    }

    // user의 password reset token 조회
    public String getPasswordResetToken(String userEmail) {
        String key = "PRT:" + userEmail;
        return redisTemplate.opsForValue().get(key);
    }

    // user의 password reset token 삭제
    public void deletePasswordResetToken(String userEmail) {
        String key = "PRT:" + userEmail;
        redisTemplate.delete(key);
    }
}
