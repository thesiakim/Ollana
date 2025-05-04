package com.ssafy.ollana.tracking.web.controller;

import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.tracking.service.TrackingService;
import com.ssafy.ollana.tracking.web.dto.response.MountainSearchResponseDto;
import com.ssafy.ollana.tracking.web.dto.response.MountainSuggestionsResponseDto;
import com.ssafy.ollana.tracking.web.dto.response.NearestMountainResponseDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/back-api/tracking")
@Slf4j
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

    /*
     * 산 검색 시 자동완성
     */
    @GetMapping("/search")
    public ResponseEntity<Response<MountainSuggestionsResponseDto>> getMountainSuggestions(@RequestParam String mtn) {
        log.info("검색 단어 = {}", mtn);
        MountainSuggestionsResponseDto response = trackingService.getMountainSuggestions(mtn);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 산 검색 결과 반환
     */
    @GetMapping("/search/results")
    public ResponseEntity<Response<MountainSearchResponseDto>> getMountainSearchResults(@RequestParam String mtn) {
        MountainSearchResponseDto response = trackingService.getMountainSearchResults(mtn);
        return ResponseEntity.ok(Response.success(response));
    }



}
