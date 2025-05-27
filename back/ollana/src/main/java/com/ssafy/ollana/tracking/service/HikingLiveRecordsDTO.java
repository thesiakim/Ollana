package com.ssafy.ollana.tracking.service;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class HikingLiveRecordsDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    @JsonProperty("id")
    private Integer id;

    @JsonProperty("userId")
    private Integer userId;

    @JsonProperty("mountainId")
    private Integer mountainId;

    @JsonProperty("pathId")
    private Integer pathId;

    @JsonProperty("hikingHistoryId")
    private Integer hikingHistoryId;

    @JsonProperty("totalTime")
    private int totalTime;

    @JsonProperty("totalDistance")
    private double totalDistance;

    @JsonProperty("latitude")
    private Double latitude;

    @JsonProperty("longitude")
    private Double longitude;

    @JsonProperty("heartRate")
    private Integer heartRate;
}