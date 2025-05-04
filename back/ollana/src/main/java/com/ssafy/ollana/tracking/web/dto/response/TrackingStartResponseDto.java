package com.ssafy.ollana.tracking.web.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TrackingStartResponseDto {
    private MountainLocationResponseDto mountain;
    private PathForTrackingResponseDto path;
    private OpponentResponseDto opponent;
}
