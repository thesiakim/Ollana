package com.ssafy.ollana.tracking.service;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.repository.HikingHistoryRepository;
import com.ssafy.ollana.footprint.service.exception.NotFoundException;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.mountain.persistent.repository.MountainRepository;
import com.ssafy.ollana.mountain.persistent.repository.PathRepository;
import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import com.ssafy.ollana.tracking.persistent.repository.HikingLiveRecordsRepository;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class HikingRecordsConsumer {

    private final HikingLiveRecordsRepository hikingLiveRecordsRepository;
    private final UserRepository userRepository;
    private final MountainRepository mountainRepository;
    private final PathRepository pathRepository;
    private final HikingHistoryRepository hikingHistoryRepository;

    @RabbitListener(queues = "hiking-records-queue")
    @Transactional
    public void consumeHikingRecords(List<HikingLiveRecordsDTO> dtoList) {
        log.info("Received {} HikingLiveRecordsDTO from queue", dtoList.size());

        List<HikingLiveRecords> entityList = dtoList.stream()
                .map(dto -> {
                    User user = userRepository.findById(dto.getUserId()).orElseThrow(NotFoundException::new);
                    Mountain mountain = mountainRepository.findById(dto.getMountainId()).orElseThrow(NotFoundException::new);
                    Path path = pathRepository.findById(dto.getPathId()).orElseThrow(NotFoundException::new);
                    HikingHistory history = hikingHistoryRepository.findById(dto.getHikingHistoryId()).orElseThrow(NotFoundException::new);

                    return HikingLiveRecords.builder()
                            .id(dto.getId())
                            .user(user)
                            .mountain(mountain)
                            .path(path)
                            .hikingHistory(history)
                            .totalTime(dto.getTotalTime())
                            .totalDistance(dto.getTotalDistance())
                            .latitude(dto.getLatitude())
                            .longitude(dto.getLongitude())
                            .heartRate(dto.getHeartRate())
                            .build();
                })
                .collect(Collectors.toList());

        int batchSize = 100;
        try {
            for (int i = 0; i < entityList.size(); i += batchSize) {
                List<HikingLiveRecords> batch = entityList.subList(i, Math.min(i + batchSize, entityList.size()));
                hikingLiveRecordsRepository.saveAll(batch);
                hikingLiveRecordsRepository.flush();
                log.info("Saved batch of {} HikingLiveRecords", batch.size());
            }
        } catch (Exception e) {
            log.error("Failed to save HikingLiveRecords: {}", e.getMessage());
            throw e; // DLQ로 전송
        }
    }
}