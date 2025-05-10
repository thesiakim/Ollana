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

    // redis 블랙리스트 저장
    public void blacklistAccessToken(String accessToken, long expirationMillis) {
        String key = "BL:" + accessToken;
        redisTemplate.opsForValue().set(key, "logout", expirationMillis, TimeUnit.MILLISECONDS);
    }

    // 블랙리스트에 있는지 확인
    public boolean isBlacklisted(String accessToken) {
        return redisTemplate.hasKey("BL:" + accessToken);
    }
}
