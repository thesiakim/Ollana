package com.ssafy.ollana.security.jwt;

import com.ssafy.ollana.auth.service.TokenService;
import com.ssafy.ollana.security.CustomUserDetails;
import com.ssafy.ollana.user.service.CustomUserDetailsService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

// 로그인 및 JWT 생성하여 헤더에 추가
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final CustomUserDetailsService customUserDetailsService;
    private final TokenService tokenService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {

        // 요청 헤더에서 access token 추출
        String accessToken = getAccessTokenFromRequest(request);

        if (accessToken != null && !tokenService.isBlacklisted(accessToken)) {

            // 토큰 유효성 검사
            if (jwtUtil.validateToken(accessToken)) {
                setAuthentication(accessToken);

            // 토큰 만료 여부 확인
            } else if (jwtUtil.isTokenExpired(accessToken)) {
                // 만료 되었으면 refresh token 통해서 access token 새로 발금
                String refreshToken = getRefreshTokenFromCookie(request);

                if (refreshToken != null && jwtUtil.validateToken(refreshToken)) {
                    String userEmail = jwtUtil.getUserEmailFromToken(refreshToken);

                    // redis에 있는 refresh token과 일치하는지 확인
                    if (tokenService.validateRefreshToken(userEmail, refreshToken)) {
                        // 일치한다면 access token 재발급
                        String newAccessToken = jwtUtil.createAccessToken(userEmail);

                        // 재발급한 access token을 응답 헤더에 넣어주기
                        response.setHeader("Authorization", "Bearer " + newAccessToken);

                        // SecurityContext 갱신
                        setAuthentication(newAccessToken);
                    }
                }
            }
        }

        filterChain.doFilter(request, response);
    }

    // 요청 헤더에서 access token 추출
    private String getAccessTokenFromRequest(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return null;
    }

    // 요청 쿠키에서 refresh token 추출
    private String getRefreshTokenFromCookie(HttpServletRequest request) {
        if (request.getCookies() == null) {
            return null;
        }

        for (Cookie cookie : request.getCookies()) {
            if (cookie.getName().equals("refreshToken")) {
                return cookie.getValue();
            }
        }

        return null;
    }

    private void setAuthentication(String accessToken) {
        String email = jwtUtil.getUserEmailFromToken(accessToken);
        CustomUserDetails userDetails = customUserDetailsService.loadUserByUsername(email);
        UsernamePasswordAuthenticationToken authenticationToken = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());

        SecurityContextHolder.getContext().setAuthentication(authenticationToken);
    }
}
