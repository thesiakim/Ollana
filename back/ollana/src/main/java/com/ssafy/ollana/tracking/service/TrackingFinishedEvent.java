package com.ssafy.ollana.tracking.service;

import java.util.List;

public record TrackingFinishedEvent(
        Integer userId,
        Integer mountainId,
        Integer pathId,
        Integer finalTime,
        List<Integer> heartRates
) {}

