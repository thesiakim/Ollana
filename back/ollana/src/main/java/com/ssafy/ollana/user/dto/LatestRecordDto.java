package com.ssafy.ollana.user.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.Date;

@Getter
@Builder
public class LatestRecordDto {
    private String mountainName;
    private Date climbDate;
    private LocalDateTime climbTime;
    private double climbDistance;
}
