// hiking_route.dart: 등산로 모델 클래스
// 산의 등산로 정보를 저장하는 데이터 모델

class HikingRoute {
  final String id;
  final String mountainId;
  final String name;
  final double distance;
  final int estimatedTime; // 분 단위
  final String difficulty;
  final String description;
  final List<String> waypoints;
  final String mapImageUrl;
  final List<Map<String, double>> path; // 경로 좌표 정보

  HikingRoute({
    required this.id,
    required this.mountainId,
    required this.name,
    required this.distance,
    required this.estimatedTime,
    this.difficulty = '보통',
    this.description = '',
    this.waypoints = const [],
    this.mapImageUrl = '',
    this.path = const [], // 기본값으로 빈 리스트 설정
  });

  factory HikingRoute.fromJson(Map<String, dynamic> json) {
    return HikingRoute(
      id: json['id'] ?? '',
      mountainId: json['mountainId'] ?? '',
      name: json['name'] ?? '',
      distance: (json['distance'] is num) ? json['distance'].toDouble() : 0.0,
      estimatedTime: json['estimatedTime'] ?? 0,
      difficulty: json['difficulty'] ?? '보통',
      description: json['description'] ?? '',
      waypoints: List<String>.from(json['waypoints'] ?? []),
      mapImageUrl: json['mapImageUrl'] ?? '',
      path: List<Map<String, double>>.from(json['path'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mountainId': mountainId,
      'name': name,
      'distance': distance,
      'estimatedTime': estimatedTime,
      'difficulty': difficulty,
      'description': description,
      'waypoints': waypoints,
      'mapImageUrl': mapImageUrl,
      'path': path,
    };
  }
}
