package com.ssafy.ollana.user.service;

import com.ssafy.ollana.user.dto.LatestRecordDto;
import com.ssafy.ollana.user.dto.UserInfoDto;
import com.ssafy.ollana.user.entity.User;
import org.springframework.stereotype.Service;

@Service
public class UserServiceImpl implements UserService {

    @Override
    public UserInfoDto getUserInfo(User user) {
        return UserInfoDto.builder()
                .email(user.getEmail())
                .nickname(user.getNickname())
                .exp(user.getExp())
                .grade(String.valueOf(user.getGrade()))
                .totalDistance(user.getTotalDistance())
                .build();
    }

    @Override
    public LatestRecordDto getLatestRecord(User user) {
        return LatestRecordDto.builder().build();
    }
}
