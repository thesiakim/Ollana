package com.ssafy.ollana.mountain.persistent.repository;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MountainRepository extends JpaRepository<Mountain, Integer>, MountainCustomRepository {
    Optional<Mountain> findByMntnCode(String mntnCode);
}
