package com.ssafy.ollana.footprint.web.controller;

import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.footprint.service.PastClimbHistoryService;
import com.ssafy.ollana.footprint.web.dto.response.PastClimbHistoryResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/footprint")
public class PastClimbHistoryController {

    private final PastClimbHistoryService pastClimbHistoryService;

    /*
     * 나 vs 나 전체 기록 조회
     */
    @GetMapping("/{footprintId}")
    public ResponseEntity<Response<PastClimbHistoryResponseDto>> getPastClimbHistory(
            @AuthenticationPrincipal Integer userId,
            @PathVariable Integer footprintId) {
        PastClimbHistoryResponseDto response = pastClimbHistoryService.getPastClimbHistory(userId, footprintId);
        return ResponseEntity.ok(Response.success(response));
    }


}
