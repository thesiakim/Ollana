package com.ssafy.ollana.mountain.web.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class MountainResponseDto {
    private Integer mountainId;
    private String mountainName;
}
