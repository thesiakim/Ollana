package com.ssafy.ollana.footprint.persistent.repository;

import com.querydsl.jpa.impl.JPAQueryFactory;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import static com.ssafy.ollana.footprint.persistent.entity.QHikingHistory.hikingHistory;

@Repository
@RequiredArgsConstructor
public class HikingHistoryRepositoryImpl implements HikingHistoryRepositoryCustom {
    private final JPAQueryFactory queryFactory;

    @Override
    public List<HikingHistory> findHistories(Integer footprintId, Integer pathId, LocalDateTime start, LocalDateTime end) {
        return queryFactory
                        .selectFrom(hikingHistory)
                        .where(
                                hikingHistory.footprint.id.eq(footprintId),
                                hikingHistory.path.id.eq(pathId),
                                hikingHistory.createdAt.between(start, end)
                        )
                        .orderBy(hikingHistory.createdAt.asc())
                        .fetch();

    }
}
