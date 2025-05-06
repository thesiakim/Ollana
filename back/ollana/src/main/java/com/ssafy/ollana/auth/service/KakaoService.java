package com.ssafy.ollana.auth.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class KakaoService {

    @Value("${spring.kakao.auth.client}")
    private String client;

    @Value("${spring.kakao.auth.redirect}")
    private String redirect;

    // 카카오 인가 코드로 토큰 발급 요청
    private String getAccessToken(String code) {

    }
}
