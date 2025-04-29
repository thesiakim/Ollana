package com.ssafy.ollana.footprint.web.dto.response;

import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.PathResponseDto;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class PastClimbHistoryResponseDto {
    private MountainResponseDto mountain;
    private List<ClimbHistoryWithPathResponseDto> paths;
}
