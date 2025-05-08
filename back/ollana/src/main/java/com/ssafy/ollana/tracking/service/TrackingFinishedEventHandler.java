package com.ssafy.ollana.tracking.service;

import com.ssafy.ollana.footprint.persistent.entity.Footprint;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.repository.FootprintRepository;
import com.ssafy.ollana.footprint.persistent.repository.HikingHistoryRepository;
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
import org.springframework.transaction.event.TransactionalEventListener;

@Component
@RequiredArgsConstructor
@Slf4j
public class TrackingFinishedEventHandler {

    private final UserRepository userRepository;
    private final MountainRepository mountainRepository;
    private final PathRepository pathRepository;
    private final FootprintRepository footprintRepository;
    private final HikingHistoryRepository hikingHistoryRepository;

    @Async
    @TransactionalEventListener
    public void handle(TrackingFinishedEvent event) {
        try {
            User user = userRepository.findById(event.userId()).orElseThrow();
            Mountain mountain = mountainRepository.findById(event.mountainId()).orElseThrow();
            Path path = pathRepository.findById(event.pathId()).orElseThrow();

            Footprint footprint = footprintRepository.findByUserAndMountain(user, mountain)
                                                     .orElseGet(() -> footprintRepository.save(Footprint.builder()
                                                                                                    .user(user)
                                                                                                    .mountain(mountain)
                                                                                                    .build()));

            double avg = event.heartRates().stream().mapToInt(i -> i).average().orElse(0);
            int max = event.heartRates().stream().mapToInt(i -> i).max().orElse(0);

            HikingHistory history = HikingHistory.builder()
                                                 .footprint(footprint)
                                                 .path(path)
                                                 .hikingTime(event.finalTime())
                                                 .averageHeartRate(avg)
                                                 .maxHeartRate(max)
                                                 .build();

            hikingHistoryRepository.save(history);
        } catch (Exception e) {
            log.warn("HikingHistory 저장 실패: {}", e.getMessage(), e);
        }
    }
}

