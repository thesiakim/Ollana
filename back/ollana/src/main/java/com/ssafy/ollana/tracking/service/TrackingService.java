package com.ssafy.ollana.tracking.service;

import com.ssafy.ollana.mountain.persistent.entity.Level;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.mountain.persistent.repository.MountainRepository;
import com.ssafy.ollana.mountain.persistent.repository.PathRepository;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.*;
import org.locationtech.jts.io.WKBReader;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class TrackingService {
    private final MountainRepository mountainRepository;
    private final PathRepository pathRepository;
    private final EntityManager em;
    private final Map<String, Integer> unnamedCounter = new HashMap<>();

    @Transactional
    public void saveAllMountainsFromApi() throws Exception {
        log.info("시작");
        int pageNo = 1;
        int numOfRows = 100;

        String serviceKey = "gDgRUvnVeO8L6EUzIKI2B6ipxWk%2FjUek2svmvI8JUhPcjVGyODzqiYCrC0qIi%2FjSySM26ywiIL%2Fj%2BEg53vsf9w%3D%3D";

        while (true) {
            log.info("pageNo={}", pageNo);

            String urlStr = String.format(
                    "https://apis.data.go.kr/B553662/top100FamtListBasiInfoService/getTop100FamtListBasiInfoList?serviceKey=%s&pageNo=%d&numOfRows=%d",
                    serviceKey, pageNo, numOfRows
            );

            URL url = new URL(urlStr);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");

            DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
            DocumentBuilder db = dbf.newDocumentBuilder();
            Document doc = db.parse(conn.getInputStream());
            doc.getDocumentElement().normalize();

            NodeList nodeList = doc.getElementsByTagName("item");

            // nodeList 길이가 0이면 종료
            if (nodeList.getLength() == 0) break;

            for (int i = 0; i < nodeList.getLength(); i++) {
                Element e = (Element) nodeList.item(i);

                String mntnCode = getTagValue("mtnCd", e);
                if (mntnCode == null || mntnCode.isBlank()) continue;

                // 이미 저장된 산은 skip
                if (mountainRepository.findByMntnCode(mntnCode).isPresent()) continue;

                Mountain mountain = Mountain.builder()
                        .mntnCode(mntnCode)
                        .mountainName(getTagValue("frtrlNm", e))
                        .mountainLoc(getTagValue("addrNm", e))
                        .mountainLatitude(parseDouble(getTagValue("lat", e)))
                        .mountainLongitude(parseDouble(getTagValue("lot", e)))
                        .mountainHeight(parseDouble(getTagValue("aslAltide", e)))
                        .mountainDescription(null)
                        .level(null)
                        .mountainBadge(null)
                        .build();

                mountainRepository.save(mountain);
                log.info("저장");
            }

            pageNo++; // 다음 페이지로
        }
    }

    private String getTagValue(String tag, Element e) {
        NodeList nList = e.getElementsByTagName(tag);
        if (nList.getLength() > 0 && nList.item(0).getFirstChild() != null) {
            return nList.item(0).getFirstChild().getNodeValue();
        } else {
            return null;
        }
    }

    private Double parseDouble(String value) {
        try {
            return Double.parseDouble(value);
        } catch (Exception e) {
            return null;
        }
    }





    @Transactional
    public void savePathsFromSqlTable() {
        String sql = """
            SELECT 
              mntn_code,
              mntn_nm,
              pmntn_nm,
              pmntn_lt,
              pmntn_dffl,
              pmntn_uppl,
              ST_Y(ST_Transform(ST_Centroid(wkb_geometry), 4326)) AS lat,
              ST_X(ST_Transform(ST_Centroid(wkb_geometry), 4326)) AS lon,
              ST_AsBinary(ST_LineMerge(ST_Transform(wkb_geometry, 4326))) AS route_geom
            FROM ollanatest
        """;


        List<Object[]> results = em.createNativeQuery(sql).getResultList();
        GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);
        WKBReader wkbReader = new WKBReader(geometryFactory);

        for (Object[] row : results) {
            String mntnCode = (String) row[0];
            String mntnName = (String) row[1];
            String pmntnName = (String) row[2];
            Double pathLengthKm = row[3] != null ? ((Number) row[3]).doubleValue() : null;
            String difficulty = (String) row[4];
            Integer pathTimeMinutes = row[5] != null ? ((Number) row[5]).intValue() : null;
            Double lat = row[6] != null ? ((Number) row[6]).doubleValue() : null;
            Double lon = row[7] != null ? ((Number) row[7]).doubleValue() : null;
            byte[] routeBytes = (byte[]) row[8];

            if (mntnCode == null || mntnName == null || lat == null || lon == null || routeBytes == null) {
                log.warn("필수 정보 누락 → 건너뜀: {}", mntnCode);
                continue;
            }

            Optional<Mountain> optionalMountain = mountainRepository.findByMntnCode(mntnCode);
            if (optionalMountain.isEmpty()) {
                log.warn("Mountain 매칭 실패: {}", mntnCode);
                continue;
            }

            Mountain mountain = optionalMountain.get();

            // 등산로 이름 처리
            String pathName = pmntnName;
            if (pathName == null || pathName.isBlank()) {
                int count = unnamedCounter.getOrDefault(mntnName, 0) + 1;
                unnamedCounter.put(mntnName, count);
                pathName = mntnName + " 등산로 " + count;
            }

            if (pathRepository.existsByMountainAndPathName(mountain, pathName)) {
                log.info("이미 존재: {} / {}", mountain.getMountainName(), pathName);
                continue;
            }

            // 중심점 생성
            Point centerPoint = geometryFactory.createPoint(new Coordinate(lon, lat));

            // 경로(LineString) 생성
            LineString route;
            try {
                Geometry geom = wkbReader.read(routeBytes);
                if (!(geom instanceof LineString)) {
                    log.warn("LineString 아님: {}", geom.getGeometryType());
                    continue;
                }
                route = (LineString) geom;
            } catch (Exception e) {
                    log.error("WKB LineString 파싱 실패", e);
                continue;
            }

            Path path = Path.builder()
                    .mountain(mountain)
                    .pathName(pathName)
                    .pathLength(pathLengthKm != null ? pathLengthKm * 1000 : null) // m로 변환
                    .centerPoint(centerPoint)
                    .route(route)
                    .level(convertLevel(difficulty))
                    .pathTime(pathTimeMinutes != null ? String.valueOf(pathTimeMinutes) : null)
                    .build();

            pathRepository.save(path);
            log.info("저장 완료: {} / {}", mountain.getMountainName(), pathName);
        }
    }


    private Level convertLevel(String value) {
        if (value == null) return null;
        return switch (value.trim()) {
            case "쉬움" -> Level.L;
            case "중간" -> Level.M;
            case "어려" -> Level.H;
            default -> null;
        };
    }
}
