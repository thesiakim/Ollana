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
import com.ssafy.ollana.tracking.persistent.HikingLiveRecordsRepository;
import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import com.ssafy.ollana.tracking.service.exception.NoNearbyMountainException;
import com.ssafy.ollana.tracking.web.dto.request.TrackingStartRequestDto;
import com.ssafy.ollana.tracking.web.dto.response.*;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.repository.UserRepository;
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
    private final UserRepository userRepository;
    private final HikingHistoryRepository hikingHistoryRepository;
    private final HikingLiveRecordsRepository hikingLiveRecordsRepository;

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

    /*
     * [나 VS 친구] 모드 선택 시 친구 정보 조회
     */
    @Transactional(readOnly = true)
    public FriendListResponseDto getFriendsInfo(Integer mountainId, Integer pathId, String nickname) {
        List<FriendInfoResponseDto> friends = userRepository.searchFriends(nickname, mountainId, pathId);

        return FriendListResponseDto.builder()
                .users(friends)
                .build();
    }

    /*
     * 트래킹 시작 요청
     */
    @Transactional(readOnly = true)
    public TrackingStartResponseDto getTrackingStartInfo(Integer userId, TrackingStartRequestDto request) {
        Mountain mountain = mountainRepository.findById(request.getMountainId())
                                              .orElseThrow(NotFoundException::new);

        Path path = pathRepository.findById(request.getPathId())
                                  .orElseThrow(NotFoundException::new);

        OpponentResponseDto opponentDto = null;

        // 일반 모드일 때는 대결 상대 데이터를 조회하지 않음
        if (!request.getMode().equals("GENERAL")) {
            User opponent = userRepository.findById(request.getOpponentId())
                                          .orElseThrow(NotFoundException::new);

        List<HikingLiveRecords> records = hikingLiveRecordsRepository
                .findByUserIdAndMountainIdAndPathIdOrderByTotalTimeAsc(
                        request.getOpponentId(),
                        request.getMountainId(),
                        request.getPathId()
                );
            opponentDto = OpponentResponseDto.from(opponent, records);
        }

        return TrackingStartResponseDto.builder()
                .mountain(MountainLocationResponseDto.from(mountain))
                .path(PathForTrackingResponseDto.from(path))
                .opponent(opponentDto)
                .build();
    }
}
