package com.ssafy.ollana.user.persistent.entity;

import com.ssafy.ollana.common.BaseEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Entity
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User extends BaseEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "user_id")
	private Long id;

	private String email;
	private String nickname;
	private String password;
	private String birth;

	@Enumerated(EnumType.STRING)
	private Gender gender;

	private double totalDistance;
	private String grade;
	private int point;
	private String image;
	private boolean isSurvey;
	private boolean isSocial;
	private boolean isAgree;
}
