package com.ssafy.ollana.footprint.web.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class FootprintListResponseDto {
    private int currentPage;
    private int totalPages;
    private long totalElements;
    private boolean last;
    private double totalDistance;
    private List<FootprintResponseDto> mountains;
}
