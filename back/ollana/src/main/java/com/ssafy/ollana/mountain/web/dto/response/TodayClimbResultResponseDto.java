package com.ssafy.ollana.mountain.web.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

/*
 * "date": "2025-04-04",
            "maxHeartRate": 178,
            "averageHeartRate": 101,
            "time": 105
 */
@Getter
@Builder
public class TodayClimbResultResponseDto {
    private LocalDate date;
    private int maxHeartRate;
    private double averageHeartRate;
    private int time;
}
