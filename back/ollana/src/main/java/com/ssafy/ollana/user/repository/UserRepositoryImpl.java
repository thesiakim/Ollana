package com.ssafy.ollana.user.repository;

import com.querydsl.core.Tuple;
import com.querydsl.core.types.Projections;
import com.querydsl.core.types.dsl.BooleanExpression;
import com.querydsl.core.types.dsl.Expressions;
import com.querydsl.jpa.JPAExpressions;
import com.querydsl.jpa.impl.JPAQueryFactory;
import com.ssafy.ollana.footprint.persistent.entity.QFootprint;
import com.ssafy.ollana.footprint.persistent.entity.QHikingHistory;
import com.ssafy.ollana.tracking.web.dto.response.FriendInfoResponseDto;
import lombok.RequiredArgsConstructor;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import static com.ssafy.ollana.footprint.persistent.entity.QFootprint.footprint;
import static com.ssafy.ollana.footprint.persistent.entity.QHikingHistory.hikingHistory;
import static com.ssafy.ollana.user.entity.QUser.user;

@RequiredArgsConstructor
public class UserRepositoryImpl implements UserRepositoryCustom {

    private final JPAQueryFactory queryFactory;

    @Override
    public List<FriendInfoResponseDto> searchFriends(String nickname, Integer mountainId, Integer pathId) {
        // 서브쿼리를 통해 사용자별 등산 기록 존재 여부 확인
        List<Tuple> results = queryFactory
                .select(
                        user.id,
                        user.nickname,
                        user.isAgree,
                        JPAExpressions
                                .selectOne()
                                .from(hikingHistory)
                                .join(hikingHistory.footprint, footprint)
                                .where(
                                        hikingHistory.path.id.eq(pathId),
                                        footprint.mountain.id.eq(mountainId),
                                        footprint.user.id.eq(user.id)
                                )
                                .exists()
                )
                .from(user)
                .where(user.nickname.containsIgnoreCase(nickname))
                .fetch();

        // 결과 변환
        return results.stream()
                .map(tuple -> {
                    Integer userId = tuple.get(0, Integer.class);
                    String userNickname = tuple.get(1, String.class);
                    Boolean isAgree = tuple.get(2, Boolean.class);
                    Boolean hasHikingRecord = tuple.get(3, Boolean.class);

                    Boolean finalResult = isAgree != null && isAgree && hasHikingRecord;
                    return new FriendInfoResponseDto(userId, userNickname, finalResult);
                })
                .collect(Collectors.toList());
    }
}
