package com.ssafy.ollana.footprint.service;

import com.ssafy.ollana.mountain.web.dto.GrowthStatus;

public class HikingHistoryUtils {

    public static GrowthStatus determineStatus(int timeDiff, int hrDiff) {
        if (timeDiff < 0 || hrDiff < 0) return GrowthStatus.IMPROVING;
        return GrowthStatus.REGRESSING;
    }

    public static String formatSigned(int value) {
        return (value >= 0 ? "+" : "") + value;
    }
}
