package com.ssafy.ollana.footprint.persistent.repository;

import com.ssafy.ollana.footprint.persistent.entity.PastClimbHistory;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PastClimbHistoryRepository extends JpaRepository<Integer, PastClimbHistory> {
}
