package com.ssafy.ollana.tracking.web.controller;

import com.ssafy.ollana.tracking.service.TrackingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/tracking")
public class TrackingController {

    private final TrackingService trackingService;

    @PostMapping("/import/mtn")
    public ResponseEntity<String> importMountainData() throws Exception {
        trackingService.saveAllMountainsFromApi();
        return ResponseEntity.ok("전체 Mountain 데이터 저장 완료");
    }

    @PostMapping("/import/path")
    public ResponseEntity<String> importPaths() {
        trackingService.savePathsFromSqlTable();
        return ResponseEntity.ok("Path 데이터 저장 완료");
    }


}
