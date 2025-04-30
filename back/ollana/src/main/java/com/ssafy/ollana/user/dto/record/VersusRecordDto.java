package com.ssafy.ollana.user.dto.record;

import lombok.Getter;

import java.time.LocalDateTime;
import java.util.Date;

@Getter
public class VersusRecordDto {
    private Date climbDate;
    private LocalDateTime climbTime;
    private int averageHeartRate;
    private int maxHeartRate;
}
