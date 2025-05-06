package com.ssafy.ollana.auth.password.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class PasswordResetTokenExpireException extends BusinessException {
    public PasswordResetTokenExpireException() {
        super("비밀번호 재설정 토큰이 만료되었습니다.", "P-001");
    }
}
