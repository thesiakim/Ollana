package com.ssafy.ollana.mountain.persistent.repository;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;

import java.util.Optional;

public interface MountainCustomRepository {
    Optional<Mountain> findNearestMountain(double lat, double lng);
}
