package com.ssafy.ollana.mountain.service;

import com.ssafy.ollana.mountain.web.dto.response.MountainMapResponseDto;

import java.util.List;

public interface MountainService {
    void saveMountainImg();
    List<MountainMapResponseDto> getMountains();
}
