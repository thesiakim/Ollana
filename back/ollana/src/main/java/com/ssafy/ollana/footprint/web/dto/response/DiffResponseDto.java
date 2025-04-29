package com.ssafy.ollana.footprint.web.dto.response;

import com.ssafy.ollana.mountain.web.dto.GrowthStatus;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class DiffResponseDto {
    private GrowthStatus growthStatus;
    private String heartRateDiff;
    private String timeDiff;
}
