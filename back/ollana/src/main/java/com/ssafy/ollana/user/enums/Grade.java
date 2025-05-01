package com.ssafy.ollana.user.enums;

public enum Grade {
    SEED(0),
    SPROUT(100),
    TREE(500),
    FRUIT(1000),
    MOUNTAIN(2000);

    // 다음 grade로 가기 위한 요구 경험치
    private final int requiredExp;

    Grade(int requiredExp) {
        this.requiredExp = requiredExp;
    }

    public int getRequiredExp() {
        return this.requiredExp;
    }

    // 경험치에 따른 grade 반환
    public static Grade getGrade(int exp) {
        Grade userGrade = SEED;

        for (Grade grade : values()) {
            if (exp >= grade.getRequiredExp()) {
                userGrade = grade;
            } else {
                break;
            }
        }

        return userGrade;
    }
}
