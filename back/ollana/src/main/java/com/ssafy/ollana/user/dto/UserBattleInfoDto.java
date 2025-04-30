package com.ssafy.ollana.user.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserBattleInfoDto {
    private Integer opponentId;
    private String nickname;
    private String profile;
}
