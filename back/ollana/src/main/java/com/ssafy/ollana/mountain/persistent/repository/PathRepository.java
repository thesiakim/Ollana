package com.ssafy.ollana.mountain.persistent.repository;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import io.lettuce.core.dynamic.annotation.Param;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.Point;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface PathRepository extends JpaRepository<Path, Integer> {

    List<Path> findByMountainId(Integer mountainId);

    @Query(value = """
    SELECT p
    FROM Path p
    ORDER BY ST_Distance(
        p.route,
        ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)
    )
    ASC
    """)
    List<Path> findNearestRoute(@Param("lat") double lat, @Param("lng") double lng, Pageable pageable);

    List<Path> findByPathNameIn(List<String> names);

    @Modifying
    @Transactional
    @Query("DELETE FROM Path p WHERE p.pathName LIKE '무등산 등산로%'")
    void deleteByPathNameStartingWith(String prefix);

    /**
     * 여러 경로를 하나의 LineString으로 병합
     * ST_LineMerge: 선들을 연결하여 하나의 선으로 만듦
     * ST_Collect: 여러 지오메트리를 하나의 컬렉션으로 모음
     */
    @Query(value = "SELECT ST_LineMerge(ST_Collect(p.route)) " +
            "FROM path p " +
            "WHERE p.path_name IN :pathNames",
            nativeQuery = true)
    LineString mergeRoutes(@Param("pathNames") List<String> pathNames);

    /**
     * LineString의 중심점 계산
     * ST_Centroid: 지오메트리의 중심점을 계산
     */
    @Query(value = "SELECT ST_Centroid(:lineString)",
            nativeQuery = true)
    Point calculateCenterPoint(@Param("lineString") LineString lineString);

    /**
     * 경로 이름으로 단일 경로 조회
     */
    Path findByPathName(String pathName);



}
