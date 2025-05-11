package com.ssafy.ollana.mountain.service;

import com.ssafy.ollana.mountain.web.dto.response.MountainDetailResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainListResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainMapResponseDto;

import java.util.List;

public interface MountainService {
    void saveMountainImg();
    List<MountainMapResponseDto> getMountains();
    List<MountainListResponseDto> getMountainList();
    MountainDetailResponseDto getMountainDetail(int mountainId);
}
