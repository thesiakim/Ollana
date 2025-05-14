package com.ssafy.ollana.auth.service;

import com.ssafy.ollana.security.jwt.JwtUtil;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
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

        int userId = jwtUtil.getUserIdFromToken(refreshToken);
        log.info("Refresh token saved: userId={}", userId);
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

        if (!isValid) {
            int userId = jwtUtil.getUserIdFromToken(refreshToken);
            log.info("Refresh token validation failed: userId={}", userId);
        }

        return isValid;
    }

    // 토큰 블랙리스트 관리
    // 액세스 토큰을 redis 블랙리스트에 추가
    public void blacklistAccessToken(String accessToken, long expirationMillis) {
        String key = "BL:" + accessToken;
        redisTemplate.opsForValue().set(key, "logout", expirationMillis, TimeUnit.MILLISECONDS);
    }

    // 블랙리스트에 있는지 확인
    public boolean isBlacklisted(String accessToken) {
        return redisTemplate.hasKey("BL:" + accessToken);
    }

    // 토큰 추출
    // 헤더에서 액세스 토큰 추출
    public String extractAccessTokenFromHeader(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return null;
    }

    // 쿠키에서 리프레시 토큰 추출
    public String extractRefreshTokenFromCookie(HttpServletRequest request) {
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

    // 리프레시 토큰을 HTTP-only 쿠키로 설정
    public Cookie createRefreshTokenCookie(String refreshToken) {
        Cookie refreshCookie = new Cookie("refreshToken", refreshToken);
        refreshCookie.setHttpOnly(true);  // JavaScript에서 접근 불가
        refreshCookie.setSecure(true);    // HTTPS에서만 전송
        refreshCookie.setPath("/");       // 모든 경로에서 접근 가능
        refreshCookie.setMaxAge((int) (jwtUtil.getRefreshTokenExpiration() / 1000)); // 초 단위로 변환
        return refreshCookie;
    }

    // 만료된 리프레시 토큰 쿠키 생성 (로그아웃)
    public Cookie createExpiredRefreshTokenCookie() {
        Cookie refreshCookie = new Cookie("refreshToken", "");
        refreshCookie.setHttpOnly(true);
        refreshCookie.setSecure(true);
        refreshCookie.setPath("/");
        refreshCookie.setMaxAge(0); // 즉시 만료
        return refreshCookie;
    }
}
