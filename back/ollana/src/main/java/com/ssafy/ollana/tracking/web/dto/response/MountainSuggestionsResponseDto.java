package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class MountainSuggestionsResponseDto {
    private List<MountainResponseDto> mountains;

    public static MountainSuggestionsResponseDto from(List<Mountain> mountains) {
        List<MountainResponseDto> dtos = mountains.stream()
                                                  .map(MountainResponseDto::from)
                                                  .toList();
        return MountainSuggestionsResponseDto.builder()
                                             .mountains(dtos)
                                             .build();
    }
}
