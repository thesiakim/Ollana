package com.ssafy.ollana.footprint.persistent.repository;

import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;

import java.time.LocalDateTime;
import java.util.List;

public interface HikingHistoryRepositoryCustom {
    List<HikingHistory> findHistories(Integer footprintId, Integer pathId, LocalDateTime start, LocalDateTime end);
}
