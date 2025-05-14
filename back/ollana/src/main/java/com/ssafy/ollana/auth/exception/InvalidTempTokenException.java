package com.ssafy.ollana.auth.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class InvalidTempTokenException extends BusinessException {
    public InvalidTempTokenException() {
        super("유효하지 않은 임시 토큰입니다.", "A-003");
    }
}
