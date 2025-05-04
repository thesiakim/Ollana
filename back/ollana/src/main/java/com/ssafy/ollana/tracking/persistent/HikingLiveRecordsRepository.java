package com.ssafy.ollana.tracking.persistent;

import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HikingLiveRecordsRepository extends JpaRepository<HikingLiveRecords, Integer> {
    List<HikingLiveRecords> findByUserIdAndMountainIdAndPathIdOrderByTotalTimeAsc(
            Integer userId, Integer mountainId, Integer pathId
    );

}
