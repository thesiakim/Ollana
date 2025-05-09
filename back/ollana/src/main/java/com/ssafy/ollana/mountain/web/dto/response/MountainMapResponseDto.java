package com.ssafy.ollana.mountain.web.dto.response;

import com.ssafy.ollana.mountain.web.dto.MountainImageDto;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class MountainMapResponseDto {
    private String name;
    private double latitude;
    private double longitude;
    private String location;
    private String description;
    private double altitude;
    private String level;

    private List<MountainImageDto> mountainImage;
}
