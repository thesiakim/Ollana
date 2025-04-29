package com.ssafy.ollana.user.dto.record;

import lombok.Getter;

import java.time.LocalDateTime;
import java.util.Date;

@Getter
public class LatestRecordDto {
    private Date climbDate;
    private LocalDateTime climbTime;
    private double climbDistance;
}
