package com.ssafy.ollana.mountain.web.controller;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.mountain.service.MountainService;
import com.ssafy.ollana.mountain.web.dto.response.MountainDetailResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainListResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainMapResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
    public ResponseEntity<Response<PageResponse<MountainListResponseDto>>> getMountainList(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        PageResponse<MountainListResponseDto> response = mountainService.getMountainList(page, size);
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
