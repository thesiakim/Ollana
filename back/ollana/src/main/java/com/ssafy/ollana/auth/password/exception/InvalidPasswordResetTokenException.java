package com.ssafy.ollana.auth.password.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class InvalidPasswordResetTokenException extends BusinessException {
    public InvalidPasswordResetTokenException() {
        super("비밀번호 재설정 토큰이 유효하지 않습니다.", "P-002");
    }
}
