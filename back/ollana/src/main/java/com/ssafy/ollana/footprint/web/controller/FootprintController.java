package com.ssafy.ollana.footprint.web.controller;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.footprint.service.FootprintService;
import com.ssafy.ollana.footprint.web.dto.response.FootprintResponseDto;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import lombok.RequiredArgsConstructor;


@RestController
@RequiredArgsConstructor
@RequestMapping("/api/footprint")
public class FootprintController {

    private final FootprintService footprintService;

    /*
     * 나의 발자취 조회
     */
    @GetMapping
    public ResponseEntity<Response<PageResponse<FootprintResponseDto>>> getMyFootprints(
            @AuthenticationPrincipal Integer userId,
            @PageableDefault(size = 9) Pageable pageable) {

        PageResponse<FootprintResponseDto> response = footprintService.getMyFootprints(userId, pageable);
        return ResponseEntity.ok(Response.success(response));
    }


}
