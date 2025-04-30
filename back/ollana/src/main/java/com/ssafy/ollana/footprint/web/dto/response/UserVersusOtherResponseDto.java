package com.ssafy.ollana.footprint.web.dto.response;

import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import com.ssafy.ollana.user.dto.UserBattleInfoDto;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class UserVersusOtherResponseDto {
    private MountainResponseDto mountain;
    private String result;
    private LocalDate date;
    private UserBattleInfoDto opponent;
}
