package com.ssafy.ollana.tracking.service;

import com.ssafy.ollana.tracking.web.dto.response.LatLngPointResponseDto;
import org.locationtech.jts.geom.LineString;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public class TrackingUtils {

    public static List<LatLngPointResponseDto> convertLineStringToLatLng(LineString lineString) {
        return Arrays.stream(lineString.getCoordinates())
                .map(LatLngPointResponseDto::from)
                .collect(Collectors.toList());
    }
}
