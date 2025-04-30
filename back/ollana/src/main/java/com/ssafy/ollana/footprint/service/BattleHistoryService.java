package com.ssafy.ollana.footprint.service;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.common.util.PaginateUtil;
import com.ssafy.ollana.footprint.persistent.entity.BattleHistory;
import com.ssafy.ollana.footprint.persistent.entity.enums.BattleType;
import com.ssafy.ollana.footprint.persistent.repository.BattleHistoryRepository;
import com.ssafy.ollana.footprint.web.dto.response.UserVersusOtherListResponseDto;
import com.ssafy.ollana.footprint.web.dto.response.UserVersusOtherResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import com.ssafy.ollana.user.dto.UserBattleInfoDto;
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
            case FRIEND -> page = battleHistoryRepository.findByUserIdAndType(userId, BattleType.FRIEND, pageable);
            case AI -> page = battleHistoryRepository.findByUserIdAndType(userId, BattleType.AI, pageable);
            default -> page = battleHistoryRepository.findByUserId(userId, pageable);
        }

        List<UserVersusOtherResponseDto> list = page.getContent().stream()
                .map(battle -> UserVersusOtherResponseDto.builder()
                        .mountain(MountainResponseDto.from(battle.getMountain()))
                        .result(battle.getResult().name())
                        .date(battle.getCreatedAt().toLocalDate())
                        .opponent(UserBattleInfoDto.builder()
                                .opponentId(battle.getOpponent().getId())
                                .nickname(battle.getOpponent().getNickname())
                                .profile(battle.getOpponent().getProfileImage())
                                .build())
                        .build())
                .toList();

        /*UserVersusOtherListResponseDto listDtos = UserVersusOtherListResponseDto.builder()
                .list(list)
                .build();*/

        Page<UserVersusOtherResponseDto> paginateResult = PaginateUtil.paginate(
                list, pageable.getPageNumber(), pageable.getPageSize());

        return new PageResponse<>("list", paginateResult);
    }
}
