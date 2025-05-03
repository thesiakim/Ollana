package com.ssafy.ollana.tracking.web.controller;

import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.tracking.service.TrackingService;
import com.ssafy.ollana.tracking.web.dto.response.NearestMountainResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/tracking")
public class TrackingController {

    private final TrackingService trackingService;

    /*
     * 사용자 위치 인식 후 가장 가까운 산 반환
     */
    @GetMapping("/mountains/nearby")
    public ResponseEntity<Response<NearestMountainResponseDto>> getNearestMountain(
                                                        @RequestParam double lat,
                                                        @RequestParam double lng) {
        NearestMountainResponseDto response = trackingService.findNearestMountain(lat, lng);
        return ResponseEntity.ok(Response.success(response));
    }


}
