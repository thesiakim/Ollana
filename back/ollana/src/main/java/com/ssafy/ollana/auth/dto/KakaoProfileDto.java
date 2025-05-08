package com.ssafy.ollana.auth.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
public class KakaoProfileDto {

    @JsonProperty("kakao_account")
    private KakaoAccount kakaoAccount;

    @Getter
    @NoArgsConstructor
    public static class KakaoAccount {
        private String email;
        private Profile profile;

        @Getter
        @NoArgsConstructor
        public static class Profile {
            private String nickname;

            @JsonProperty("profile_image_url")
            private String profileImageUrl;

            @JsonProperty("is_default_image")
            private boolean isDefaultImage;

            @Override
            public String toString() {
                return "Profile{" +
                        "nickname='" + nickname + '\'' +
                        ", profileImageUrl='" + profileImageUrl + '\'' +
                        ", isDefaultImage=" + isDefaultImage +
                        '}';
            }
        }

        @Override
        public String toString() {
            return "KakaoAccount{" +
                    "email='" + email + '\'' +
                    ", profile=" + profile +
                    '}';
        }
    }

    @Override
    public String toString() {
        return "KakaoProfileDto{" +
                ", kakaoAccount=" + kakaoAccount +
                '}';
    }
}
