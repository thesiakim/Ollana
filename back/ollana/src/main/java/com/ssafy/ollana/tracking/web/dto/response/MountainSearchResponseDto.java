package com.ssafy.ollana.tracking.web.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class MountainSearchResponseDto {
    private List<NearestMountainResponseDto> results;

    public static MountainSearchResponseDto from(List<NearestMountainResponseDto> results) {
        return MountainSearchResponseDto.builder()
                                        .results(results)
                                        .build();
    }
}
