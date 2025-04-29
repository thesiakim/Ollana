package com.ssafy.ollana.mountain.web.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class PathResponseDto {
    private Integer pathId;
    private String pathName;
}
