package com.ssafy.ollana.footprint.web.controller;

import com.ssafy.ollana.common.exception.BusinessException;

public class TestException extends BusinessException {
    public TestException() {
        super("test 예외", "T-001");
    }
}
