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
import com.ssafy.ollana.tracking.persistent.repository.HikingLiveRecordsRepository;
import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import com.ssafy.ollana.tracking.service.exception.NoNearbyMountainException;
import com.ssafy.ollana.tracking.web.dto.request.TrackingFinishRequestDto;
import com.ssafy.ollana.tracking.web.dto.request.TrackingStartRequestDto;
import com.ssafy.ollana.tracking.web.dto.response.*;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Coordinate;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class TrackingService {
    private final MountainRepository mountainRepository;
    private final PathRepository pathRepository;
    private final UserRepository userRepository;
    private final HikingHistoryRepository hikingHistoryRepository;
    private final HikingLiveRecordsRepository hikingLiveRecordsRepository;
    private final ApplicationEventPublisher eventPublisher;



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

        List<MountainSearchListResponseDto> results = mountains.stream()
                .map(mountain -> {
                    List<Path> paths = pathRepository.findByMountainId(mountain.getId());

                    return MountainSearchListResponseDto.builder()
                            .mountain(MountainAddressResponseDto.from(mountain))
                            .paths(paths.stream()
                                    .map(PathForTrackingResponseDto::from)
                                    .toList())
                            .build();
                })
                .toList();

        return MountainSearchResponseDto.from(results);
    }

    /*
     * 산 리스트 중 특정 산 선택 시 결과 반환
     */
    @Transactional(readOnly = true)
    public MountainSearchListResponseDto getMountainSelectResult(Integer mountainId) {
        Mountain mountain = mountainRepository.findById(mountainId)
                .orElseThrow(NotFoundException::new);

        List<Path> paths = pathRepository.findByMountainId(mountainId);

        return MountainSearchListResponseDto.builder()
                .mountain(MountainAddressResponseDto.from(mountain))
                .paths(paths.stream()
                        .map(PathForTrackingResponseDto::from)
                        .toList())
                .build();
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
    public TrackingStartResponseDto getTrackingStartInfo(TrackingStartRequestDto request) {
        Mountain mountain = mountainRepository.findById(request.getMountainId())
                .orElseThrow(NotFoundException::new);

        Path path = pathRepository.findById(request.getPathId())
                .orElseThrow(NotFoundException::new);

        // 선택한 산이 사용자 현 위치를 기준으로 반경 10km 이내에 존재하는지 검증
        boolean isNearby = mountainRepository.isMountainWithin10km(
                request.getMountainId(),
                request.getLatitude(),
                request.getLongitude()
        );

        OpponentResponseDto opponentDto = null;

        // 일반 모드일 때는 대결 상대 데이터를 조회하지 않음
        if (!"GENERAL".equals(request.getMode()) && request.getOpponentId() != null) {
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
                .isNearby(isNearby)
                .mountain(MountainLocationResponseDto.from(mountain))
                .path(PathForTrackingResponseDto.from(path))
                .opponent(opponentDto)
                .build();
    }

    /*
     * 트래킹 종료 요청
     */
    @Transactional
    public String manageTrackingFinish(Integer userId, TrackingFinishRequestDto request) {
        User user = userRepository.findById(userId)
                                  .orElseThrow(NotFoundException::new);
        Path path = pathRepository.findById(request.getPathId())
                                  .orElseThrow(NotFoundException::new);
        Mountain mountain = mountainRepository.findById(request.getMountainId())
                                              .orElseThrow(NotFoundException::new);

        // 거리 측정
        Coordinate end = path.getRoute().getEndPoint().getCoordinate();
        double endLat = end.y;
        double endLng = end.x;
        double userLat = request.getFinalLatitude();
        double userLng = request.getFinalLongitude();
        double distance = TrackingUtils.calculateDistance(endLat, endLng, userLat, userLng);

        if (distance > 300) {
            return "등반하시는 코스의 마지막 지점까지 도착하지 않았습니다";
        }

        // 기존 데이터가 존재할 경우 삭제
        hikingLiveRecordsRepository.deleteByUserAndMountainAndPath(user, mountain, path);

        // 데이터 저장
        List<HikingLiveRecords> entityList = TrackingUtils.toEntities(request.getRecords(), user, mountain, path);
        hikingLiveRecordsRepository.saveAll(entityList);

        // 비동기 이벤트 발행
        List<Integer> heartRates = request.getRecords().stream()
                                                       .map(BattleRecordsForTrackingResponseDto::getHeartRate)
                                                       .filter(Objects::nonNull)
                                                       .toList();

        TrackingFinishedEvent event = new TrackingFinishedEvent(
                userId, mountain.getId(), path.getId(), request.getFinalTime(), heartRates
        );
        eventPublisher.publishEvent(event);
        log.info("등산 기록 이벤트 발행");

        return "등산을 완료했습니다";
    }

}
