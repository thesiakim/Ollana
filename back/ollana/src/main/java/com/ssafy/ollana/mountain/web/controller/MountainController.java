package com.ssafy.ollana.mountain.web.controller;

import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.mountain.service.MountainService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/mountain")
@RequiredArgsConstructor
public class MountainController {

    private final MountainService mountainService;

    @GetMapping("/save-image")
    public ResponseEntity<Response<Void>> saveMountainImg() {
        mountainService.saveMountainImg();
        return ResponseEntity.ok(Response.success());
    }
}
