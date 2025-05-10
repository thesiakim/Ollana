package com.ssafy.ollana.tracking.service;

import com.ssafy.ollana.footprint.persistent.entity.BattleHistory;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.entity.enums.BattleResult;
import com.ssafy.ollana.footprint.persistent.repository.BattleHistoryRepository;
import com.ssafy.ollana.footprint.persistent.repository.HikingHistoryRepository;
import com.ssafy.ollana.footprint.service.exception.NotFoundException;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.mountain.persistent.repository.MountainRepository;
import com.ssafy.ollana.mountain.persistent.repository.PathRepository;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
@RequiredArgsConstructor
@Slf4j
public class BattleResultEventHandler {

    private final UserRepository userRepository;
    private final MountainRepository mountainRepository;
    private final PathRepository pathRepository;
    private final HikingHistoryRepository hikingHistoryRepository;
    private final BattleHistoryRepository battleHistoryRepository;

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void handleBattleResult(BattleResultEvent event) {
        try {
            User user = userRepository.findById(event.userId()).orElseThrow();
            User opponent = userRepository.findById(event.opponentId()).orElseThrow();
            Mountain mountain = mountainRepository.findById(event.mountainId()).orElseThrow();
            Path path = pathRepository.findById(event.pathId()).orElseThrow();
            HikingHistory opponentHistory = hikingHistoryRepository.findById(event.recordId())
                    .orElseThrow(NotFoundException::new);

            int opponentTime = opponentHistory.getHikingTime();
            BattleResult result = BattleResult.S;

            if (event.finalTime() < opponentTime) result = BattleResult.W;
            else if (event.finalTime() > opponentTime) result = BattleResult.L;

            BattleHistory history = BattleHistory.builder()
                                                .mountain(mountain)
                                                .path(path)
                                                .user(user)
                                                .opponent(opponent)
                                                .result(result)
                                                .build();

            battleHistoryRepository.save(history);
            log.info("BattleHistory 저장 완료: {}", result);

        } catch (Exception e) {
            log.error("BattleHistory 저장 중 오류 발생", e);
        }
    }
}

