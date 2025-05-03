package com.ssafy.ollana.mountain.service;

import com.ssafy.ollana.mountain.exception.MountainNotFoundException;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.MountainImg;
import com.ssafy.ollana.mountain.persistent.repository.MountainImgRepository;
import com.ssafy.ollana.mountain.persistent.repository.MountainRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class MountainServiceImpl implements MountainService {

    @Value("${api.service-key}")
    private String serviceKey;

    private final MountainRepository mountainRepository;
    private final MountainImgRepository mountainImgRepository;

    @Override
    @Transactional
    public void saveMountainImg() {
        // 산 코드 리스트 가져오기
        List<String> mntnCodeList = mountainRepository.findAllMntnCode();
        for (String mntnCode : mntnCodeList) {
            try {
                // 외부 api 호출
                String url = "https://apis.data.go.kr/1400000/service/cultureInfoService2/mntInfoImgOpenAPI2" +
                        "?mntiListNo=" + mntnCode + "&ServiceKey=" + serviceKey;

                // HttpURLConnection
                URL apiUrl = new URL(url);
                HttpURLConnection connection = (HttpURLConnection) apiUrl.openConnection();
                connection.setRequestMethod("GET");

                int responseCode = connection.getResponseCode();

                // 응답 읽기
                BufferedReader in;
                if (responseCode >= 200 && responseCode < 300) {
                    in = new BufferedReader(new InputStreamReader(connection.getInputStream(), StandardCharsets.UTF_8));
                } else {
                    in = new BufferedReader(new InputStreamReader(connection.getErrorStream(), StandardCharsets.UTF_8));
                }

                String inputLine;
                StringBuilder content = new StringBuilder();
                while ((inputLine = in.readLine()) != null) {
                    content.append(inputLine);
                }
                in.close();
                connection.disconnect();

                String xml = content.toString();

                // XML 파싱 및 처리
                if (xml.contains("SERVICE_ERROR") || xml.contains("<errMsg>")) {
                    System.out.println("API 오류 발생: " + xml);
                    continue;
                }

                // XML 문자열 -> DOM 객체로 파싱
                DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
                factory.setNamespaceAware(false); // 네임스페이스 무시
                DocumentBuilder builder = factory.newDocumentBuilder();
                Document document = builder.parse(new InputSource(new StringReader(xml)));

                // <item> 태그 목록 가져오기
                NodeList itemList = document.getElementsByTagName("item");

                // 해당 산 가져오기
                Mountain mountain = mountainRepository.findByMntnCode(mntnCode)
                        .orElseThrow(() -> new MountainNotFoundException());

                int count = itemList.getLength();
                for (int i = 0; i < count; i++) {
                    Element item = (Element) itemList.item(i);

                    // imgfilename 가져오기
                    String imgfilename = item.getElementsByTagName("imgfilename").item(0).getTextContent();

                    // 이미지 url 생성 및 저장
                    String imgUrl = "www.forest.go.kr/images/data/down/mountain/" + imgfilename;

                    // 산 이미지 테이블 생성 및 저장
                    MountainImg mountainImg = MountainImg.builder()
                            .mountain(mountain)
                            .image(imgUrl)
                            .build();
                    mountainImgRepository.save(mountainImg);
                }

            } catch (Exception e) {
                log.error("산 이미지 저장 중 오류 발생: mntnCode={}, error={}", mntnCode, e.getMessage());
            }
        }
    }
}
