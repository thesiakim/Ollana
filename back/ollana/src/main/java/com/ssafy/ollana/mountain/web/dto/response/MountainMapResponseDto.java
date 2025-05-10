package com.ssafy.ollana.mountain.web.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class MountainMapResponseDto {
    private String name;
    private double latitude;
    private double longitude;
    private double altitude;
    private String level;
    private String location;
    private String description;

    private List<String> mountainImage;
}
