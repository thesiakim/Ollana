package com.ssafy.ollana.user.dto;

import lombok.Getter;

@Getter
public class UserInfoDto {
    private String email;
    private String nickname;
    private int exp;
    private String grade;
    private double totalDistance;
}
