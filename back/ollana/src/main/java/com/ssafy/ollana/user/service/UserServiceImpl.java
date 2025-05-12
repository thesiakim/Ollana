package com.ssafy.ollana.user.service;

import com.ssafy.ollana.common.s3.service.S3Service;
import com.ssafy.ollana.footprint.persistent.entity.Footprint;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.repository.FootprintRepository;
import com.ssafy.ollana.footprint.persistent.repository.HikingHistoryRepository;
import com.ssafy.ollana.mountain.persistent.entity.Level;
import com.ssafy.ollana.security.CustomUserDetails;
import com.ssafy.ollana.user.dto.LatestRecordDto;
import com.ssafy.ollana.user.dto.request.MypageUpdateRequestDto;
import com.ssafy.ollana.user.dto.response.MypageResponseDto;
import com.ssafy.ollana.user.dto.UserInfoDto;
import com.ssafy.ollana.user.entity.User;
import lombok.extern.slf4j.Slf4j;
import com.ssafy.ollana.user.exception.NicknameAlreadyExistsException;
import com.ssafy.ollana.user.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@Slf4j
public class UserServiceImpl implements UserService {

    private final FootprintRepository footprintRepository;
    private final HikingHistoryRepository hikingHistoryRepository;
    private final UserRepository userRepository;
    private final S3Service s3Service;

    public UserServiceImpl(FootprintRepository footprintRepository, HikingHistoryRepository hikingHistoryRepository, UserRepository userRepository, S3Service s3Service) {
        this.footprintRepository = footprintRepository;
        this.hikingHistoryRepository = hikingHistoryRepository;

        this.userRepository = userRepository;
        this.s3Service = s3Service;
    }

    @Override
    @Transactional(readOnly = true)
    public MypageResponseDto getMypage(CustomUserDetails userDetails) {
        User user = userDetails.getUser();

        MypageResponseDto response = new MypageResponseDto(
                user.getNickname(),
                user.getEmail(),
                user.getProfileImage()
        );

        return response;
    }

    @Override
    @Transactional
    public MypageResponseDto updateMypage(CustomUserDetails userDetails, MypageUpdateRequestDto request, MultipartFile profileImage) {
        User user = userDetails.getUser();

        // 닉네임 업데이트
        if (request.getNickname() != null && !request.getNickname().isEmpty()) {
            // 닉네임 중복검사
            if (!request.getNickname().equals(user.getNickname()) && userRepository.existsByNickname(request.getNickname())) {
                throw new NicknameAlreadyExistsException();
            }

            user.setNickname(request.getNickname());
        }

        // 프로필 이미지 업데이트
        if (profileImage != null && !profileImage.isEmpty()) {
            // 새로운 프로필 이미지 S3 업로드
            String profileImageUrl = s3Service.uploadFile(profileImage, "profile");

            // 기본 이미지가 아니라면 S3에서 삭제
            String currentProfileImageUrl = user.getProfileImage();
            if (!currentProfileImageUrl.equals(s3Service.getDefaultProfileImageUrl())) {
                s3Service.deleteFile(currentProfileImageUrl);
            }

            user.setProfileImage(profileImageUrl);
        }

        userRepository.save(user);

        MypageResponseDto response = new MypageResponseDto(
                user.getNickname(),
                user.getEmail(),
                user.getProfileImage()
        );

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public UserInfoDto getUserInfo(User user) {
        return UserInfoDto.builder()
                .email(user.getEmail())
                .nickname(user.getNickname())
                .exp(user.getExp())
                .grade(String.valueOf(user.getGrade()))
                .totalDistance(user.getTotalDistance())
                .profileImageUrl(user.getProfileImage())
                .isTempPassword(user.isTempPassword())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public LatestRecordDto getLatestRecord(User user) {
        // 첫 페이지에 가장 최근 데이터 1개만 가져오기 위한 Pageable 설정
        Pageable pageable = PageRequest.of(0, 1, Sort.by(Sort.Direction.DESC, "createdAt"));

        // user의 가장 최근 Footprint 가져오기
        Page<Footprint> footprintPage = footprintRepository.findByUserId(user.getId(), pageable);

        if (footprintPage.isEmpty()) {
            return LatestRecordDto.builder()
                    .mountainName("")
                    .climbDate("")
                    .climbTime(0)
                    .climbDistance(0.0)
                    .build();
        }

        Footprint footprint = footprintPage.getContent().get(0);

        // hikingHistory 가져오기
        List<HikingHistory> hikingHistoryList = hikingHistoryRepository.findAllByFootprintIdOrderByCreatedAtAsc(footprint.getId());

        if (hikingHistoryList.isEmpty()) {
            return LatestRecordDto.builder()
                    .mountainName("")
                    .climbDate("")
                    .climbTime(0)
                    .climbDistance(0.0)
                    .build();
        }

        // 오름차순으로 가져왔기 때문에 가장 마지막 항목이 가장 최근 기록
        HikingHistory latestHistory = hikingHistoryList.get(hikingHistoryList.size() - 1);

        return LatestRecordDto.builder()
                .mountainName(footprint.getMountain().getMountainName())
                .climbDate(latestHistory.getCreatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE))
                .climbTime(latestHistory.getHikingTime())
                .climbDistance(latestHistory.getPath().getPathLength())
                .build();
    }

    // 등산 종료 후 거리와 경험치 갱신
    @Override
    public void updateUserInfoAfterTracking(User user, Double finalDistance, Level level) {
        // 거리 누적
        user.addTotalDistance(finalDistance);

        // 경험치 계산
        int expToAdd = switch (level) {
            case L -> 20;
            case M -> 40;
            case H -> 60;
        };
        user.addExp(expToAdd);

        log.info("User [{}] 거리와 경험치 갱신 완료. 추가 거리: {}, 추가 EXP: {}",
                user.getNickname(), finalDistance, expToAdd);
    }
}
