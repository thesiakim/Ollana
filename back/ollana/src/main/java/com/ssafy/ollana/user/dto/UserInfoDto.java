package com.ssafy.ollana.user.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserInfoDto {
    private String email;
    private String nickname;
    private int exp;
    private String grade;
    private double totalDistance;
    private String profileImageUrl;
    private boolean isTempPassword;
}
