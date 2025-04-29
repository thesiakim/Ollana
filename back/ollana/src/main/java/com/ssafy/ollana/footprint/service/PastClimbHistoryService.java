package com.ssafy.ollana.footprint.service;

import com.ssafy.ollana.footprint.persistent.repository.PastClimbHistoryRepository;
import com.ssafy.ollana.footprint.web.dto.response.PastClimbHistoryResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PastClimbHistoryService {

    private final PastClimbHistoryRepository pastClimbHistoryRepository;

    /*
     * 나 vs 나 전체 기록 조회
     */
    public PastClimbHistoryResponseDto getPastClimbHistory(Integer userId, Integer footprintId) {
    }
}
