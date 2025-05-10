package com.ssafy.ollana.auth.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TempUserDto {
    private String email;
    private String nickname;
    private String profileImage;
    @JsonProperty("isSocial")
    private boolean socialLogin;
}
