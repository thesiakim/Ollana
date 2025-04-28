package com.ssafy.ollana.mountain.persistent.entity;

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
public class Mountain {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "mountain_id")
	private Long id;

	private String mountainName;
	private String mountainLoc;
	private double mountainHeight;

	@Column(columnDefinition = "TEXT", nullable = false)
	private String mountainDescription;

	@Enumerated(EnumType.STRING)
	private Level level;
	private double mountainLatitude;
	private double mountainLongitude;

	private String mountainBadge;
}
