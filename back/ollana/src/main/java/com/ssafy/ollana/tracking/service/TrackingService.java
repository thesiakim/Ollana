package com.ssafy.ollana.tracking.service;

import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.repository.HikingHistoryRepository;
import com.ssafy.ollana.footprint.service.exception.NotFoundException;
import com.ssafy.ollana.footprint.web.dto.response.TodayHikingResultResponseDto;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.mountain.persistent.repository.MountainRepository;
import com.ssafy.ollana.mountain.persistent.repository.PathRepository;
import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import com.ssafy.ollana.tracking.service.exception.NoNearbyMountainException;
import com.ssafy.ollana.tracking.web.dto.response.MountainSearchResponseDto;
import com.ssafy.ollana.tracking.web.dto.response.MountainSuggestionsResponseDto;
import com.ssafy.ollana.tracking.web.dto.response.NearestMountainResponseDto;
import com.ssafy.ollana.tracking.web.dto.response.PathForTrackingResponseDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class TrackingService {
    private final MountainRepository mountainRepository;
    private final PathRepository pathRepository;
    private final HikingHistoryRepository hikingHistoryRepository;

    /*
     * 사용자 위치 인식 후 가장 가까운 산 반환
     */
    @Transactional(readOnly = true)
    public NearestMountainResponseDto findNearestMountain(double lat, double lng) {
        Mountain mountain = mountainRepository.findNearestMountain(lat, lng)
                                              .orElseThrow(NoNearbyMountainException::new);

        List<Path> paths = pathRepository.findByMountainId(mountain.getId());

        return NearestMountainResponseDto.builder()
                                         .mountain(MountainResponseDto.from(mountain))
                                         .paths(paths.stream()
                                                  .map(PathForTrackingResponseDto::from)
                                                  .toList())
                                         .build();
    }

    /*
     * 산 검색 시 자동완성
     */
    @Transactional(readOnly = true)
    public MountainSuggestionsResponseDto getMountainSuggestions(String mountainName) {
        List<Mountain> mountains = mountainRepository.findTop10ByMountainNameContaining(mountainName);
        return MountainSuggestionsResponseDto.from(mountains);
    }

    /*
     * 산 검색 결과 반환
     */
    @Transactional(readOnly = true)
    public MountainSearchResponseDto getMountainSearchResults(String mountainName) {
        List<Mountain> mountains = mountainRepository.findByMountainNameContaining(mountainName);

        List<NearestMountainResponseDto> results = mountains.stream()
                .map(mountain -> {
                    List<Path> paths = pathRepository.findByMountainId(mountain.getId());

                    return NearestMountainResponseDto.builder()
                                                     .mountain(MountainResponseDto.from(mountain))
                                                     .paths(paths.stream()
                                                            .map(PathForTrackingResponseDto::from)
                                                            .toList())
                                                     .build();
                })
                            .toList();

        return MountainSearchResponseDto.from(results);
    }

    /*
     * [나 VS 나] 모드 선택 시 가장 최근의 이전 정보 조회
     */
    @Transactional(readOnly = true)
    public TodayHikingResultResponseDto getHikingRecord(Integer userId, Integer mountainId, Integer pathId) {
        HikingHistory history = hikingHistoryRepository.findLatestRecord(userId, mountainId, pathId)
                                                       .orElseThrow(NotFoundException::new);

        return TodayHikingResultResponseDto.from(history);
    }

}
