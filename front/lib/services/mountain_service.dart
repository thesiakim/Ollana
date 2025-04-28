// mountain_service.dart: 산과 등산로 데이터 서비스
import '../models/mountain.dart';
import '../models/hiking_route.dart';

class MountainService {
  // API 엔드포인트 (실제 주소로 변경 필요)
  final String baseUrl = 'https://api.example.com';

  // 산 목록 가져오기
  Future<List<Mountain>> getMountains() async {
    try {
      // 실제 구현에서는 API 호출
      // final response = await _dio.get('$baseUrl/mountains');

      // 임시 데이터
      await Future.delayed(const Duration(seconds: 1));
      return [
        Mountain(
          id: 'm1',
          name: '북한산',
          location: '서울특별시',
          height: 836.5,
          difficulty: '중',
          description: '서울의 대표적인 산으로 다양한 등산로가 있습니다.',
          imageUrl: 'https://example.com/bukhansan.jpg',
        ),
        Mountain(
          id: 'm2',
          name: '설악산',
          location: '강원도 속초시',
          height: 1708.0,
          difficulty: '상',
          description: '한국에서 세 번째로 높은 산으로 아름다운 경관을 자랑합니다.',
          imageUrl: 'https://example.com/seoraksan.jpg',
        ),
        Mountain(
          id: 'm3',
          name: '지리산',
          location: '경상남도/전라남도',
          height: 1915.0,
          difficulty: '상',
          description: '한반도 남부의 최고봉으로 다양한 생태계를 보유하고 있습니다.',
          imageUrl: 'https://example.com/jirisan.jpg',
        ),
      ];
    } catch (e) {
      throw Exception('산 데이터를 불러오는데 실패했습니다: $e');
    }
  }

  // 특정 산의 등산로 가져오기
  Future<List<HikingRoute>> getRoutes(String mountainId) async {
    try {
      // 실제 구현에서는 API 호출
      // final response = await _dio.get('$baseUrl/mountains/$mountainId/routes');

      // 임시 데이터
      await Future.delayed(const Duration(seconds: 1));

      if (mountainId == 'm1') {
        // 북한산
        return [
          HikingRoute(
            id: 'r1',
            mountainId: mountainId,
            name: '백운대 코스',
            distance: 7.8,
            estimatedTime: 240,
            difficulty: '중',
            description: '북한산의 대표적인 코스로 백운대 정상까지 이어집니다.',
            waypoints: ['백운대입구', '용암문', '백운대'],
            mapImageUrl: 'https://example.com/bukhansan_baegundae.jpg',
          ),
          HikingRoute(
            id: 'r2',
            mountainId: mountainId,
            name: '인수봉 코스',
            distance: 5.2,
            estimatedTime: 180,
            difficulty: '상',
            description: '암벽 등반 구간이 포함된 도전적인 코스입니다.',
            waypoints: ['북한산성입구', '대동문', '인수봉'],
            mapImageUrl: 'https://example.com/bukhansan_insubong.jpg',
          ),
        ];
      } else if (mountainId == 'm2') {
        // 설악산
        return [
          HikingRoute(
            id: 'r3',
            mountainId: mountainId,
            name: '대청봉 코스',
            distance: 14.5,
            estimatedTime: 420,
            difficulty: '상',
            description: '설악산의 주봉인 대청봉까지 가는 장거리 코스입니다.',
            waypoints: ['소공원', '중청봉', '대청봉'],
            mapImageUrl: 'https://example.com/seoraksan_daecheongbong.jpg',
          ),
        ];
      } else {
        return [
          HikingRoute(
            id: 'r4',
            mountainId: mountainId,
            name: '기본 코스',
            distance: 8.0,
            estimatedTime: 240,
            difficulty: '중',
            description: '기본적인 등산로입니다.',
            waypoints: ['입구', '중간지점', '정상'],
            mapImageUrl: 'https://example.com/default_route.jpg',
          ),
        ];
      }
    } catch (e) {
      throw Exception('등산로 데이터를 불러오는데 실패했습니다: $e');
    }
  }
}
