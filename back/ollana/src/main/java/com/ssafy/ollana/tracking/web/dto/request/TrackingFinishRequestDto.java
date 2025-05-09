package com.ssafy.ollana.tracking.web.dto.request;

import com.ssafy.ollana.tracking.web.dto.response.BattleRecordsForTrackingResponseDto;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class TrackingFinishRequestDto {
    private Integer mountainId;
    private Integer pathId;
    private boolean isSave;
    private Integer opponentDataId;
    private Double finalLatitude;
    private Double finalLongitude;
    private Integer finalTime;
    private List<BattleRecordsForTrackingResponseDto> records;
}
