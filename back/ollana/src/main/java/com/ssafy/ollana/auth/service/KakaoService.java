package com.ssafy.ollana.auth.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssafy.ollana.auth.dto.KakaoProfileDto;
import com.ssafy.ollana.auth.dto.KakaoTokenDto;
import com.ssafy.ollana.auth.exception.KakaoResponseParsingException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

@Service
public class KakaoService {

    @Value("${spring.kakao.auth.client}")
    private String client;

    @Value("${spring.kakao.auth.redirect}")
    private String redirect;

    private RestTemplate restTemplate;
    private ObjectMapper objectMapper;

    // 카카오 인가 코드로 토큰 받아오기
    public KakaoTokenDto getAccessToken(String accessCode) {
        // 헤더
        HttpHeaders headers = new HttpHeaders();
        headers.add("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8");

        // 바디
        MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("grant_type", "authorization_code");
        params.add("client_id", client);
        params.add("redirect_uri", redirect);
        params.add("code", accessCode);

        // 헤더, 바디 연결
        HttpEntity<MultiValueMap<String, String>> kakaoTokenRequest = new HttpEntity<>(params, headers);

        // request 통해서 response 받아오기
        ResponseEntity<String> response = restTemplate.exchange(
                "https://kauth.kakao.com/oauth/token",
                HttpMethod.POST,
                kakaoTokenRequest,
                String.class
        );

        // response -> dto
        KakaoTokenDto kakaoTokenDto = null;
        try {
            kakaoTokenDto = objectMapper.readValue(response.getBody(), KakaoTokenDto.class);
        } catch (JsonProcessingException e) {
            throw new KakaoResponseParsingException();
        }

        return kakaoTokenDto;
    }

    // 받아온 토큰으로 사용자 정보 받아오기
    public KakaoProfileDto getKakaoProfile(KakaoTokenDto kakaoTokenDto) {
        // 헤더
        HttpHeaders headers = new HttpHeaders();
        headers.add("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8");
        headers.add("Authorization", "Bearer " + kakaoTokenDto.getAccessToken());

        HttpEntity<MultiValueMap<String, String>> kakaoProfileRequest = new HttpEntity<>(headers);

        // request 통해서 response 받아오기
        ResponseEntity<String> response = restTemplate.exchange(
                "https://kapi.kakao.com/v2/user/me",
                HttpMethod.GET,
                kakaoProfileRequest,
                String.class
        );

        // response -> dto
        KakaoProfileDto kakaoProfileDto = null;
        try {
            kakaoProfileDto = objectMapper.readValue(response.getBody(), KakaoProfileDto.class);
        } catch (JsonProcessingException e) {
            throw new KakaoResponseParsingException();
        }

        return kakaoProfileDto;
    }
}
