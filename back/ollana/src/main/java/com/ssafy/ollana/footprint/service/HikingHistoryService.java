package com.ssafy.ollana.footprint.service;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.common.util.PaginateUtil;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.entity.Footprint;
import com.ssafy.ollana.footprint.persistent.repository.HikingHistoryRepository;
import com.ssafy.ollana.footprint.service.exception.AccessDeniedException;
import com.ssafy.ollana.footprint.web.dto.response.HikingHistoryResponseDto;
import com.ssafy.ollana.footprint.web.dto.response.HikingHistoryWithPathResponseDto;
import com.ssafy.ollana.footprint.web.dto.response.DiffResponseDto;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.PathResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.TodayHikingResultResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

        // 조회한 산의 등산기록 조회
        List<HikingHistory> histories = hikingHistoryRepository.findAllByFootprintIdOrderByCreatedAtAsc(footprintId);

        // 각 등산로 데이터 그룹화
        Map<Path, List<HikingHistory>> pathGroupMap = histories.stream()
                .collect(Collectors.groupingBy(HikingHistory::getPath, LinkedHashMap::new, Collectors.toList()));

        // 가장 최근 두 개의 데이터 비교 (한 번만 등산한 경우 null)
        List<HikingHistoryWithPathResponseDto> allPathDtos = pathGroupMap.entrySet().stream()
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

                    // 그래프화를 위해 가장 최근 5개의 데이터 조회
                    List<TodayHikingResultResponseDto> recordDtos = records.stream()
                            .sorted(Comparator.comparing(HikingHistory::getCreatedAt).reversed()) // 최신순 정렬
                            .limit(5)       // 그래프 가독성을 위해 최근 5개의 데이터만 반환
                            .map(TodayHikingResultResponseDto::from)
                            .sorted(Comparator.comparing(TodayHikingResultResponseDto::getDate))  // 다시 날짜순 정렬 (그래프용)
                            .collect(Collectors.toList());

                    return HikingHistoryWithPathResponseDto.builder()
                            .path(PathResponseDto.from(path))
                            .result(result)
                            .records(recordDtos)
                            .build();
                })
                .toList();

        Page<HikingHistoryWithPathResponseDto> paginated = PaginateUtil.paginate(
                allPathDtos, pageable.getPageNumber(), pageable.getPageSize());

        return new HikingHistoryResponseDto(MountainResponseDto.from(mountain), paginated);
    }

}
