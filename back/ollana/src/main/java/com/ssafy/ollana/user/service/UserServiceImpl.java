package com.ssafy.ollana.user.service;

import com.ssafy.ollana.footprint.persistent.entity.Footprint;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.repository.FootprintRepository;
import com.ssafy.ollana.footprint.persistent.repository.HikingHistoryRepository;
import com.ssafy.ollana.mountain.persistent.entity.Level;
import com.ssafy.ollana.user.dto.LatestRecordDto;
import com.ssafy.ollana.user.dto.UserInfoDto;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@Slf4j
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final FootprintRepository footprintRepository;
    private final HikingHistoryRepository hikingHistoryRepository;

    public UserServiceImpl(UserRepository userRepository, FootprintRepository footprintRepository, HikingHistoryRepository hikingHistoryRepository) {
        this.userRepository = userRepository;
        this.footprintRepository = footprintRepository;
        this.hikingHistoryRepository = hikingHistoryRepository;

    }

    @Override
    @Transactional(readOnly = true)
    public UserInfoDto getUserInfo(User user) {
        return UserInfoDto.builder()
                .email(user.getEmail())
                .nickname(user.getNickname())
                .exp(user.getExp())
                .grade(String.valueOf(user.getGrade()))
                .totalDistance(user.getTotalDistance())
                .profileImageUrl(user.getProfileImage())
                .isTempPassword(user.isTempPassword())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public LatestRecordDto getLatestRecord(User user) {
        // 첫 페이지에 가장 최근 데이터 1개만 가져오기 위한 Pageable 설정
        Pageable pageable = PageRequest.of(0, 1, Sort.by(Sort.Direction.DESC, "createdAt"));

        // user의 가장 최근 Footprint 가져오기
        Page<Footprint> footprintPage = footprintRepository.findByUserId(user.getId(), pageable);

        if (footprintPage.isEmpty()) {
            return LatestRecordDto.builder()
                    .mountainName("")
                    .climbDate("")
                    .climbTime(0)
                    .climbDistance(0.0)
                    .build();
        }

        Footprint footprint = footprintPage.getContent().get(0);

        // hikingHistory 가져오기
        List<HikingHistory> hikingHistoryList = hikingHistoryRepository.findAllByFootprintIdOrderByCreatedAtAsc(footprint.getId());

        if (hikingHistoryList.isEmpty()) {
            return LatestRecordDto.builder()
                    .mountainName("")
                    .climbDate("")
                    .climbTime(0)
                    .climbDistance(0.0)
                    .build();
        }

        // 오름차순으로 가져왔기 때문에 가장 마지막 항목이 가장 최근 기록
        HikingHistory latestHistory = hikingHistoryList.get(hikingHistoryList.size() - 1);

        return LatestRecordDto.builder()
                .mountainName(footprint.getMountain().getMountainName())
                .climbDate(latestHistory.getCreatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE))
                .climbTime(latestHistory.getHikingTime())
                .climbDistance(latestHistory.getPath().getPathLength())
                .build();
    }

    // 등산 종료 후 거리와 경험치 갱신
    @Override
    public void updateUserInfoAfterTracking(User user, Double finalDistance, Level level) {
        // 거리 누적
        user.addTotalDistance(finalDistance);

        // 경험치 계산
        int expToAdd = switch (level) {
            case L -> 20;
            case M -> 40;
            case H -> 60;
        };
        user.addExp(expToAdd);

        log.info("User [{}] 거리와 경험치 갱신 완료. 추가 거리: {}, 추가 EXP: {}",
                user.getNickname(), finalDistance, expToAdd);
    }
}
