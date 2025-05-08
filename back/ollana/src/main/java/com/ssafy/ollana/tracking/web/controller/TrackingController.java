package com.ssafy.ollana.tracking.web.controller;

import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.footprint.web.dto.response.TodayHikingResultResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.PathResponseDto;
import com.ssafy.ollana.security.CustomUserDetails;
import com.ssafy.ollana.tracking.service.TrackingService;
import com.ssafy.ollana.tracking.web.dto.request.TrackingFinishRequestDto;
import com.ssafy.ollana.tracking.web.dto.request.TrackingStartRequestDto;
import com.ssafy.ollana.tracking.web.dto.response.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/tracking")
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
    @GetMapping("/search/list")
    public ResponseEntity<Response<MountainSearchResponseDto>> getMountainSearchResults(@RequestParam String mtn) {
        MountainSearchResponseDto response = trackingService.getMountainSearchResults(mtn);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 산 리스트 중 특정 산 선택 시 결과 반환
     */
    @GetMapping("/search/mountain/{mountainId}")
    public ResponseEntity<Response<MountainSearchListResponseDto>> getMountainSelectResult(@PathVariable Integer mountainId) {
        MountainSearchListResponseDto response = trackingService.getMountainSelectResult(mountainId);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * [나 VS 나] 모드 선택 시 이전 정보 조회
     */
    @GetMapping("/me/mountain/{mountainId}/path/{pathId}")
    public ResponseEntity<Response<TodayHikingResultResponseDto>> getHikingRecord(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                                  @PathVariable Integer mountainId,
                                                                                  @PathVariable Integer pathId) {
        TodayHikingResultResponseDto response = trackingService.getHikingRecord(userDetails.getUser().getId(), mountainId, pathId);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * [나 VS 친구] 모드 선택 시 친구 정보 조회
     */
    @GetMapping("/friends")
    public ResponseEntity<Response<FriendListResponseDto>> getFriendsInfo(@RequestParam Integer mountainId,
                                                                          @RequestParam Integer pathId,
                                                                          @RequestParam String nickname) {
        FriendListResponseDto response = trackingService.getFriendsInfo(mountainId, pathId, nickname);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 트래킹 시작 요청
     */
    @GetMapping("/start")
    public ResponseEntity<Response<TrackingStartResponseDto>> getTrackingStartInfo(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                                   @RequestBody TrackingStartRequestDto request) {
        TrackingStartResponseDto response = trackingService.getTrackingStartInfo(userDetails.getUser().getId(), request);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 트래킹 종료 요청
     */
    @PostMapping("/finish")
    public ResponseEntity<Response<String>> manageTrackingFinish(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                 @RequestBody TrackingFinishRequestDto request) {
        String message = trackingService.manageTrackingFinish(userDetails.getUser().getId(), request);
        return ResponseEntity.ok(Response.success(message));
    }
}
