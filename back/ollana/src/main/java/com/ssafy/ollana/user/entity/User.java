package com.ssafy.ollana.user.entity;

import com.ssafy.ollana.common.BaseEntity;
import com.ssafy.ollana.user.enums.Gender;
import com.ssafy.ollana.user.enums.Grade;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnDefault;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@EntityListeners(AuditingEntityListener.class)
@Table(name = "users") // postgreSQL 예약어로 인해 users로 설정
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(unique = true, nullable = false, length = 50)
    private String email;

    @Column
    private String password;

    @Column(unique = true, nullable = false, length = 10)
    private String nickname;

    @Column(nullable = false, length = 10)
    private String birth;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Gender gender;

    @Column(nullable = false)
    @Builder.Default
    private double totalDistance = 0.0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private Grade grade = Grade.SEED;

    @Column(nullable = false)
    @Builder.Default
    private int exp = 0;

    @Column
    private String profileImage;

    @Column(nullable = false)
    private boolean isSurvey = false;

    @Column(nullable = false)
    @Builder.Default
    private boolean isSocial = false;

    @Column(nullable = false)
    @Builder.Default
    private boolean isAgree = true;

    // exp 증가 및 그에 따른 grade 업데이트
    public void addExp(int exp) {
        this.exp += exp;
        this.grade = Grade.getGrade(this.exp);
    }

    // 총 등산 거리 업데이트
    public void addTotalDistance(double distance) {
        this.totalDistance += distance;
    }
}
