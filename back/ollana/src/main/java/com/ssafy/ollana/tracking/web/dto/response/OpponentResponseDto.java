package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import com.ssafy.ollana.user.entity.User;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class OpponentResponseDto {
    private Integer opponentId;
    private String nickname;
    private List<BattleRecordsForTrackingResponseDto> records;

    public static OpponentResponseDto from(User opponent, List<HikingLiveRecords> records) {
        return OpponentResponseDto.builder()
                .opponentId(opponent.getId())
                .nickname(opponent.getNickname())
                .records(records.stream()
                        .map(BattleRecordsForTrackingResponseDto::from)
                        .toList())
                .build();
    }


}
