package com.ssafy.ollana.auth.service;

import com.ssafy.ollana.security.jwt.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class TokenService {

    private final RedisTemplate<String, String> redisTemplate;
    private final JwtUtil jwtUtil;

    // 토큰 저장 (redis)
    // redis에 리프레시 토큰 저장
    public void saveRefreshToken(String userEmail, String refreshToken) {
        String key = "RT:" + userEmail; // 키 형식: "RT:{userEmail}"
        long expiration = jwtUtil.getRefreshTokenExpiration() / 1000; // redis는 초 단위로 만료 시간 설정
        redisTemplate.opsForValue().set(key, refreshToken, expiration, TimeUnit.SECONDS);

        log.info("Refresh token saved: {}", userEmail);
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

        log.info("Refresh token deleted: {}", userEmail);
    }

    // 리프레시 토큰이 redis에 저장된 토큰과 일치하는지 검사
    public boolean validateRefreshToken(String userEmail, String refreshToken) {
        String storedToken = getRefreshToken(userEmail);
        boolean isValid = storedToken != null && storedToken.equals(refreshToken);

        if (!isValid) {
            log.info("Refresh token validation failed: {}", userEmail);
        }

        return isValid;
    }

    // 토큰 블랙리스트 관리
    // access token을 redis 블랙리스트에 추가
    public void blacklistAccessToken(String accessToken, long expirationMillis) {
        String key = "BL:" + accessToken;
        redisTemplate.opsForValue().set(key, "logout", expirationMillis, TimeUnit.MILLISECONDS);

        log.info("Access token added to blacklist");
    }

    // 블랙리스트에 있는지 확인
    public boolean isBlacklisted(String accessToken) {
        return redisTemplate.hasKey("BL:" + accessToken);
    }

    // 토큰 추출
}
