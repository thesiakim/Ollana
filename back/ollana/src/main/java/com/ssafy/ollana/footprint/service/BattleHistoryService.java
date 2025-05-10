package com.ssafy.ollana.footprint.service;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.common.util.PaginateUtil;
import com.ssafy.ollana.footprint.persistent.entity.BattleHistory;
import com.ssafy.ollana.footprint.persistent.entity.enums.BattleType;
import com.ssafy.ollana.footprint.persistent.repository.BattleHistoryRepository;
import com.ssafy.ollana.footprint.web.dto.response.UserVersusOtherResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BattleHistoryService {

    private final BattleHistoryRepository battleHistoryRepository;

    /*
     * 나 vs 친구, 나 vs AI 기록 조회
     */
    @Transactional(readOnly = true)
    public PageResponse<UserVersusOtherResponseDto> getHikingBattleRecords(Integer userId, BattleType type, Pageable pageable) {
        Page<BattleHistory> page;

        switch (type) {
            case FRIEND -> page = battleHistoryRepository.findByUserIdAndBattleType(userId, BattleType.FRIEND, pageable);
            case AI -> page = battleHistoryRepository.findByUserIdAndBattleType(userId, BattleType.AI, pageable);
            default -> page = battleHistoryRepository.findByUserId(userId, pageable);
        }

        Page<UserVersusOtherResponseDto> dtoPage = page.map(UserVersusOtherResponseDto::from);
        return new PageResponse<>("list", dtoPage);
    }

}
