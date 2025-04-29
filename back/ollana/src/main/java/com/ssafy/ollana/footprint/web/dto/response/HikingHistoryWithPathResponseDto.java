package com.ssafy.ollana.footprint.web.dto.response;

import com.ssafy.ollana.mountain.web.dto.response.PathResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.TodayHikingResultResponseDto;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class HikingHistoryWithPathResponseDto {
    private PathResponseDto path;
    private DiffResponseDto result;
    private List<TodayHikingResultResponseDto> records;
}
