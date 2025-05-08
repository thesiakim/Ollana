package com.ssafy.ollana.auth.exception;

import com.ssafy.ollana.auth.dto.TempUserDto;
import com.ssafy.ollana.common.exception.BusinessException;
import lombok.Getter;

@Getter
public class AdditionalInfoRequiredException extends BusinessException {

    private final TempUserDto tempUser;

    public AdditionalInfoRequiredException(TempUserDto tempUser) {
        super("추가 정보 입력이 필요합니다.", "K-001");
        this.tempUser = tempUser;
    }
}
