package com.ssafy.ollana.user.service;

import com.ssafy.ollana.mountain.persistent.entity.Level;
import com.ssafy.ollana.user.dto.LatestRecordDto;
import com.ssafy.ollana.user.dto.UserInfoDto;
import com.ssafy.ollana.user.entity.User;

public interface UserService {
    // Auth에서 필요한 메서드
    UserInfoDto getUserInfo(User user);
    LatestRecordDto getLatestRecord(User user);
    void updateUserInfoAfterTracking(User user, Double finalDistance, Level level);
}
