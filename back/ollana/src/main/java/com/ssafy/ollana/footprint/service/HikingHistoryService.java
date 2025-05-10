package com.ssafy.ollana.footprint.service;

import com.ssafy.ollana.common.util.PaginateUtil;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.entity.Footprint;
import com.ssafy.ollana.footprint.persistent.repository.HikingHistoryRepository;
import com.ssafy.ollana.footprint.service.exception.AccessDeniedException;
import com.ssafy.ollana.footprint.service.exception.NotFoundException;
import com.ssafy.ollana.footprint.web.dto.response.*;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.PathResponseDto;
import com.ssafy.ollana.footprint.web.dto.response.TodayHikingResultResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HikingHistoryService {

    private final HikingHistoryRepository hikingHistoryRepository;
    private final FootprintService footprintService;

    /*
     * 나 vs 나 전체 기록 조회
     */
    @Transactional(readOnly = true)
    public HikingHistoryResponseDto getHikingHistory(Integer userId, Integer footprintId, Pageable pageable) {
        Footprint footprint = footprintService.getFootprint(footprintId);
        if (!footprint.getUser().getId().equals(userId)) {
            throw new AccessDeniedException();
        }

        Mountain mountain = footprint.getMountain();

        // 전체 기록 조회 및 path 기준 그룹화
        List<HikingHistory> allHistories = hikingHistoryRepository.findAllByFootprintIdOrderByCreatedAtAsc(footprintId);
        Map<Path, List<HikingHistory>> grouped = allHistories.stream()
                .collect(Collectors.groupingBy(HikingHistory::getPath, LinkedHashMap::new, Collectors.toList()));

        // path 단위로 페이징
        List<Map.Entry<Path, List<HikingHistory>>> groupedList = new ArrayList<>(grouped.entrySet());
        int total = groupedList.size();
        int start = Math.min(pageable.getPageNumber() * pageable.getPageSize(), total);
        int end = Math.min(start + pageable.getPageSize(), total);

        List<HikingHistoryWithPathResponseDto> dtoList = groupedList.subList(start, end).stream()
                .map(entry -> {
                    Path path = entry.getKey();
                    List<HikingHistory> records = entry.getValue();

                    DiffResponseDto result = null;
                    if (records.size() >= 2) {
                        HikingHistory secondLatest = records.get(records.size() - 2);
                        HikingHistory latest = records.get(records.size() - 1);
                        int timeDiff = latest.getHikingTime() - secondLatest.getHikingTime();
                        int hrDiff = latest.getMaxHeartRate() - secondLatest.getMaxHeartRate();

                        result = DiffResponseDto.builder()
                                .growthStatus(HikingHistoryUtils.determineStatus(timeDiff))
                                .heartRateDiff(hrDiff)
                                .timeDiff(timeDiff)
                                .build();
                    }

                    List<TodayHikingResultResponseDto> recordDtos = records.stream()
                            .sorted(Comparator.comparing(HikingHistory::getCreatedAt).reversed()) // 최신순 정렬
                            .limit(5)
                            .map(TodayHikingResultResponseDto::from)
                            .sorted(Comparator.comparing(TodayHikingResultResponseDto::getDate)) // 날짜순
                            .toList();

                    return HikingHistoryWithPathResponseDto.builder()
                            .path(PathResponseDto.from(path))
                            .result(result)
                            .records(recordDtos)
                            .build();
                })
                .toList();

        Page<HikingHistoryWithPathResponseDto> page = new PageImpl<>(dtoList, pageable, total);
        return new HikingHistoryResponseDto(MountainResponseDto.from(mountain), page);
    }


    /*
     * 나 vs 나 이전 기록 조회 (그래프)
     */
    @Transactional(readOnly = true)
    public HikingRecordsForGraphResponseDto getHikingRecordsByPeriod(Integer userId, Integer footprintId,
                                                                     Integer pathId, LocalDate start, LocalDate end) {
        Footprint footprint = footprintService.getFootprint(footprintId);
        if (!footprint.getUser().getId().equals(userId)) {
            throw new AccessDeniedException();
        }
        // 기간 조회를 위해 시간 변환
        LocalDateTime startTime = start.atStartOfDay();
        LocalDateTime endTime = end.atTime(LocalTime.MAX);

        // 기록 조회
        List<HikingHistory> histories = hikingHistoryRepository.findHistories(
                footprintId, pathId, startTime, endTime
        );

        // 데이터 5개 초과 여부 판단
        boolean isExceed = histories.size() > 5;
        List<HikingHistory> limitedHistories = isExceed ? histories.subList(0, 5) : histories;

        List<TodayHikingResultResponseDto> records = limitedHistories.stream()
                                                            .map(TodayHikingResultResponseDto::from)
                                                            .collect(Collectors.toList());

        return HikingRecordsForGraphResponseDto.builder()
                                                .isExceed(isExceed)
                                                .records(records)
                                                .build();

    }

    /*
     * 특정 날짜를 지정하여 나 vs 나 기록 비교
     */
    @Transactional(readOnly = true)
    public HikingRecordsByPeriodResponseDto compareByRecordIds(Integer userId, List<Integer> ids) {
        if (ids.size() < 1 || ids.size() > 2) {
            throw new IllegalArgumentException("잘못된 요청입니다.");
        }

        // recordId로 HikingHistory 조회
        List<HikingHistory> histories = hikingHistoryRepository.findAllById(ids);

        if (histories.size() != ids.size()) {
            throw new NotFoundException();
        }

        // 유저 권한 확인
        for (HikingHistory history : histories) {
            if (!history.getFootprint().getUser().getId().equals(userId)) {
                throw new AccessDeniedException();
            }
        }

        // 날짜순 정렬
        histories.sort(Comparator.comparing(HikingHistory::getCreatedAt));

        List<TodayHikingResultResponseDto> recordDtos = histories.stream()
                                                                 .map(TodayHikingResultResponseDto::from)
                                                                 .toList();

        // 등산 기록 차이 계산
        DiffResponseDto result = null;
        if (recordDtos.size() == 2) {
            TodayHikingResultResponseDto d1 = recordDtos.get(0);
            TodayHikingResultResponseDto d2 = recordDtos.get(1);

            int timeDiff = d2.getTime() - d1.getTime();
            int hrDiff = d2.getMaxHeartRate() - d1.getMaxHeartRate();

            result = DiffResponseDto.builder()
                                    .growthStatus(HikingHistoryUtils.determineStatus(timeDiff))
                                    .heartRateDiff(hrDiff)
                                    .timeDiff(timeDiff)
                                    .build();
        }

        return HikingRecordsByPeriodResponseDto.builder()
                .records(recordDtos)
                .result(result)
                .build();
    }

}
