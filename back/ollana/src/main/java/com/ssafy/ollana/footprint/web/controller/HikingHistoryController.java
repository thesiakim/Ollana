package com.ssafy.ollana.footprint.web.controller;


import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.footprint.service.HikingHistoryService;
import com.ssafy.ollana.footprint.web.dto.response.HikingHistoryResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/footprint")
public class HikingHistoryController {

    private final HikingHistoryService hikingHistoryService;

    /*
     * 나 vs 나 전체 기록 조회
     */
    @GetMapping("/{footprintId}")
    public ResponseEntity<Response<HikingHistoryResponseDto>> getClimbHistory(
                                                //@AuthenticationPrincipal Integer userId,
                                                @RequestParam Integer userId,
                                                @PathVariable Integer footprintId,
                                                @PageableDefault(size = 9) Pageable pageable) {
        HikingHistoryResponseDto response = hikingHistoryService.getHikingHistory(userId, footprintId, pageable);
        return ResponseEntity.ok(Response.success(response));
    }
}
