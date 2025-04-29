package com.ssafy.ollana.user.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class DuplicateEmailException extends BusinessException {
    public DuplicateEmailException() {
        super("이미 가입한 이메일입니다.", "U-001");
    }
}
