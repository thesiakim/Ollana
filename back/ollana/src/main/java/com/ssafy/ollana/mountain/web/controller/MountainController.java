package com.ssafy.ollana.mountain.web.controller;

import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.mountain.service.MountainService;
import com.ssafy.ollana.mountain.web.dto.response.MountainDetailResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainListResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainMapResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/mountain")
@RequiredArgsConstructor
public class MountainController {

    private final MountainService mountainService;

    @GetMapping("/map")
    public ResponseEntity<Response<List<MountainMapResponseDto>>> getMountains() {
        List<MountainMapResponseDto> response = mountainService.getMountains();
        return ResponseEntity.ok(Response.success(response));
    }

    @GetMapping("/list")
    public ResponseEntity<Response<List<MountainListResponseDto>>> getMountainList() {
        List<MountainListResponseDto> response = mountainService.getMountainList();
        return ResponseEntity.ok(Response.success(response));
    }

    @GetMapping("/detail/{mountain_id}")
    public ResponseEntity<Response<MountainDetailResponseDto>> getMountainDetail(@PathVariable("mountain_id") int mountainId) {
        MountainDetailResponseDto response = mountainService.getMountainDetail(mountainId);
        return ResponseEntity.ok(Response.success(response));
    }

    @GetMapping("/save-image")
    public ResponseEntity<Response<Void>> saveMountainImg() {
        mountainService.saveMountainImg();
        return ResponseEntity.ok(Response.success());
    }
}
