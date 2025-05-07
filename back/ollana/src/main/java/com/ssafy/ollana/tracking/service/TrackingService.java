package com.ssafy.ollana.tracking.service;

import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.repository.HikingHistoryRepository;
import com.ssafy.ollana.footprint.service.exception.NotFoundException;
import com.ssafy.ollana.footprint.web.dto.response.TodayHikingResultResponseDto;
import com.ssafy.ollana.mountain.persistent.entity.Level;
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
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.*;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
@RequiredArgsConstructor
@Slf4j
public class TrackingService {
    private final MountainRepository mountainRepository;
    private final PathRepository pathRepository;
    private final UserRepository userRepository;
    private final HikingHistoryRepository hikingHistoryRepository;
    private final HikingLiveRecordsRepository hikingLiveRecordsRepository;
    private final EntityManager entityManager;



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
                                                    request.getLongtitude()
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


    @Transactional(readOnly = true)
    public PathForTrackingResponseDto findNearestPath(double lat, double lng) {
        Path nearest = pathRepository.findNearestRoute(lat, lng, PageRequest.of(0, 1)).get(0);
        return PathForTrackingResponseDto.from(nearest);
        /*Pageable second = PageRequest.of(1, 1);  // 두 번째 결과 한 개
        List<Path> paths = pathRepository.findNearestRoute(lat, lng, second);

        if (paths.isEmpty()) {
            throw new NotFoundException();
        }

        return PathForTrackingResponseDto.from(paths.get(0));*/
    }

    /*@Transactional
    public void moo() {
        mergePaths(
                List.of("무등산 등산로 31", "무등산 등산로 32", "무등산 등산로 29", "무등산 등산로 34", "무등산 등산로 37", "무등산 등산로 50"),
                "무등산국립공원도원마을~규봉코스", 6798.98, Level.M, "203"
        );

        mergePaths(
                List.of("무등산 등산로 7", "무등산 등산로 5", "무등산 등산로 4", "무등산 등산로 2", "무등산 등산로 14"),
                "무등산국립공원교리~만연사코스", 5984.65, Level.M, "159"
        );

        mergePaths(
                List.of("무등산 등산로 6", "무등산 등산로 17", "무등산 등산로 15", "무등산 등산로 43", "무등산 등산로 40",
                        "무등산 등산로 23", "무등산 등산로 21", "무등산 등산로 36", "무등산 등산로 14",
                        "무등산 등산로 79", "무등산 등산로 35", "무등산 등산로 78"),
                "무등산국립공원너릿재~옛길코스", 13621.63, Level.M, "408"
        );

        mergePaths(
                List.of("무등산 등산로 51"),
                "무등산국립공원당산나무코스", 3481.12, Level.M, "106"
        );

        // 기존 무등산 등산로 N 제거
        pathRepository.deleteByPathNameStartingWith("무등산 등산로");
    }*/


    @Transactional
    public void moo() {
        List<String> names = List.of(
                "무등산 등산로 101010",
                "무등산 등산로 7"
        );

        List<Path> paths = pathRepository.findByPathNameIn(names);

        if (paths.size() != names.size()) {
            throw new RuntimeException("지정한 모든 경로를 찾지 못했습니다.");
        }

        Map<String, Path> pathMap = paths.stream()
                .collect(Collectors.toMap(Path::getPathName, p -> p));

        LineString routeA = pathMap.get("무등산 등산로 101010").getRoute();
        LineString routeB = pathMap.get("무등산 등산로 7").getRoute();

        // 중간 연결 병합
        LineString mergedRoute = mergeByClosestCutAndAppend(routeA, routeB);

        Coordinate[] coords = mergedRoute.getCoordinates();
        Coordinate mid = coords[coords.length / 2];

        GeometryFactory factory = new GeometryFactory(new PrecisionModel(), 4326);
        Point centerPoint = factory.createPoint(mid);

        Path mergedPath = Path.builder()
                .pathName("무등산국립공원교리~만연사코스")
                .pathLength(5984.65) // 실제 값 반영 가능
                .pathTime("159")
                .level(Level.M)
                .mountain(paths.get(0).getMountain())
                .route(mergedRoute)
                .centerPoint(centerPoint)
                .build();

        pathRepository.save(mergedPath);
        System.out.println("✔ 수동 병합 완료. 좌표 수: " + coords.length);
    }



    private LineString mergeByClosestCutAndAppend(LineString routeA, LineString routeB) {
        GeometryFactory factory = new GeometryFactory(new PrecisionModel(), 4326);

        Coordinate[] coordsA = routeA.getCoordinates();
        Coordinate[] coordsB = routeB.getCoordinates();

        Coordinate startB = coordsB[0];

        // A 중에서 B의 시작점과 가장 가까운 점을 찾음
        int cutIndex = 0;
        double minDist = haversineDistanceKm(coordsA[0], startB);
        for (int i = 1; i < coordsA.length; i++) {
            double dist = haversineDistanceKm(coordsA[i], startB);
            if (dist < minDist) {
                minDist = dist;
                cutIndex = i;
            }
        }

        // A는 0 ~ cutIndex까지
        List<Coordinate> merged = new ArrayList<>();
        for (int i = 0; i <= cutIndex; i++) {
            merged.add(coordsA[i]);
        }

        // B의 방향 판단 후 이어 붙임
        double distToStart = haversineDistanceKm(coordsA[cutIndex], coordsB[0]);
        double distToEnd = haversineDistanceKm(coordsA[cutIndex], coordsB[coordsB.length - 1]);

        Coordinate[] adjustedB = (distToEnd < distToStart) ? reverse(coordsB) : coordsB;

        // 시작점 중복 제거 후 B 이어붙이기
        for (int i = 1; i < adjustedB.length; i++) {
            merged.add(adjustedB[i]);
        }

        return factory.createLineString(merged.toArray(new Coordinate[0]));
    }


    private Coordinate[] reverse(Coordinate[] coords) {
        Coordinate[] reversed = new Coordinate[coords.length];
        for (int i = 0; i < coords.length; i++) {
            reversed[i] = coords[coords.length - 1 - i];
        }
        return reversed;
    }

    private double haversineDistanceKm(Coordinate c1, Coordinate c2) {
        double R = 6371.0;
        double lat1 = Math.toRadians(c1.y);
        double lat2 = Math.toRadians(c2.y);
        double deltaLat = lat2 - lat1;
        double deltaLon = Math.toRadians(c2.x - c1.x);

        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
                + Math.cos(lat1) * Math.cos(lat2)
                * Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);
        return 2 * R * Math.asin(Math.sqrt(a));
    }


}
