package com.ssafy.ollana.footprint.web.controller;


import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.footprint.service.HikingHistoryService;
import com.ssafy.ollana.footprint.web.dto.response.HikingHistoryResponseDto;
import com.ssafy.ollana.security.CustomUserDetails;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/footprint")
@Slf4j
public class HikingHistoryController {

    private final HikingHistoryService hikingHistoryService;

    /*
     * 나 vs 나 전체 기록 조회
     */
    @GetMapping("/{footprintId}")
    public ResponseEntity<Response<HikingHistoryResponseDto>> getClimbHistory(
                                                @AuthenticationPrincipal CustomUserDetails userDetails,
                                                @PathVariable Integer footprintId,
                                                @PageableDefault(size = 9) Pageable pageable) {

        HikingHistoryResponseDto response = hikingHistoryService.getHikingHistory(userDetails.getUser().getId(), footprintId, pageable);
        return ResponseEntity.ok(Response.success(response));
    }
}
