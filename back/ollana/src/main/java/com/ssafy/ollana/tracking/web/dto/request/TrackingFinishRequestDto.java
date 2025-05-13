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
    private Integer opponentId;
    private Integer recordId;
    private boolean isSave;
    private Double finalLatitude;
    private Double finalLongitude;
    private Integer finalTime;
    private Double finalDistance;
    private List<BattleRecordsForTrackingResponseDto> records;
}
