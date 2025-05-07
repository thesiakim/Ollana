package com.ssafy.ollana.footprint.persistent.entity;

import com.ssafy.ollana.common.BaseEntity;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Entity
@Table(
		name = "hiking_history",
		indexes = {
				@Index(name = "idx_history_footprint_path", columnList = "footprint_id, path_id")
		}
)
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class HikingHistory extends BaseEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "hiking_history_id")
	private Integer id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "path_id")
	private Path path;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "footprint_id")
	private Footprint footprint;

	private int hikingTime;
	private double averageHeartRate;
	private int maxHeartRate;
}
