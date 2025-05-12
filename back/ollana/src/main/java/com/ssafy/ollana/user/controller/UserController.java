package com.ssafy.ollana.user.controller;

import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.security.CustomUserDetails;
import com.ssafy.ollana.user.dto.MypageResponseDto;
import com.ssafy.ollana.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/mypage")
    public ResponseEntity<Response<MypageResponseDto>> getMypage(@AuthenticationPrincipal CustomUserDetails userDetails) {
        MypageResponseDto response = userService.getMypage(userDetails);
        return ResponseEntity.ok(Response.success(response));
    }
}
