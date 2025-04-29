package com.ssafy.ollana.user.entity;

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
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column
    private String password;

    @Column(unique = true, nullable = false)
    private String nickname;

    @Column(nullable = false)
    private String birth;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Gender gender;

    @Column(nullable = false)
    @ColumnDefault("0.0")
    private double totalDistance;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Grade grade;

    @Column(nullable = false)
    @ColumnDefault("0")
    private int exp;

    @Column
    private String profileImage;

    // 디폴트 false
    @Column(nullable = false)
    private boolean isSurvey;

    // 디폴트 false
    @Column(nullable = false)
    private boolean isSocial;

    // 디폴트 true
    @Column(nullable = false)
    private boolean isAgree;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

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
