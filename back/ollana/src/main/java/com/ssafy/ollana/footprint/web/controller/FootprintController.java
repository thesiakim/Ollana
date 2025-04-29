package com.ssafy.ollana.footprint.web.controller;

import com.ssafy.ollana.common.util.Response;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import lombok.RequiredArgsConstructor;

@Controller
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/footprint")
public class FootprintController {

	/*
	 * 나의 발자취 조회
	 */
	@GetMapping("/test")
	public ResponseEntity<Response<Void>> throwBusinessException() {
		throw new TestException();
	}
}
