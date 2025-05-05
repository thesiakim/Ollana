package com.ssafy.ollana.tracking.web.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TrackingStartResponseDto {
    private Boolean isNearby;
    private MountainLocationResponseDto mountain;
    private PathForTrackingResponseDto path;
    private OpponentResponseDto opponent;

    @JsonProperty("isNearby")
    public boolean isNearby() {
        return isNearby;
    }
}
