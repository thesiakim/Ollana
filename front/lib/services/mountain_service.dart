// mountain_service.dart: 산과 등산로 데이터 서비스
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mountain.dart';
import '../models/hiking_route.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// 산 및 등산로 데이터를 묶어 반환하는 모델
class MountainWithRoutes {
  final Mountain mountain;
  final List<HikingRoute> routes;

  MountainWithRoutes({
    required this.mountain,
    required this.routes,
  });
}

/// JSON 파싱을 백그라운드로 처리하는 헬퍼 함수 (getNearby용)
Future<MountainWithRoutes> _parseNearby(String body) async {
  final Map<String, dynamic> jsonData = jsonDecode(body);
  if (jsonData['status'] != true || jsonData['data'] == null) {
    throw FormatException('Nearby API: 예상치 못한 응답 구조');
  }
  final data = jsonData['data'] as Map<String, dynamic>;
  final mountain = Mountain.fromJson(data['mountain']);
  final List paths = data['paths'] as List<dynamic>;
  final routes = paths
      .map((e) => HikingRoute.fromJson(e as Map<String, dynamic>))
      .toList();
  return MountainWithRoutes(mountain: mountain, routes: routes);
}

/// JSON 파싱을 백그라운드로 처리하는 헬퍼 함수 (getAll용)
Future<MountainWithRoutes> _parseAll(String body) async {
  final Map<String, dynamic> jsonData = jsonDecode(body);
  if (jsonData['status'] != true || jsonData['data'] == null) {
    throw FormatException('All API: 예상치 못한 응답 구조');
  }
  final data = jsonData['data'] as Map<String, dynamic>;
  final mountain = Mountain.fromJson(data['mountain']);
  final List paths = data['paths'] as List<dynamic>;
  final routes = paths
      .map((e) => HikingRoute.fromJson(e as Map<String, dynamic>))
      .toList();
  return MountainWithRoutes(mountain: mountain, routes: routes);
}

class MountainService {
  final String _baseUrl = dotenv.get('BASE_URL');
  final http.Client _client;

  MountainService({http.Client? client}) : _client = client ?? http.Client();

  /// 주변 산 및 등산로 조회
  Future<MountainWithRoutes> getNearbyMountains(
      double latitude, double longitude) async {
    final uri = Uri.parse(
        '$_baseUrl/tracking/mountains/nearby?lat=$latitude&lng=$longitude');
    try {
      final response = await _client.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        return compute(_parseNearby, body);
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw Exception('클라이언트 오류 ${response.statusCode}');
      } else {
        throw Exception('서버 오류 ${response.statusCode}');
      }
    } on FormatException catch (e) {
      throw Exception('Nearby JSON 오류: $e');
    } catch (e) {
      throw Exception('주변 산 데이터 불러오기 실패: $e');
    }
  }

  /// 전체 산 및 등산로 조회
  Future<MountainWithRoutes> getMountainRoutes() async {
    final uri = Uri.parse('$_baseUrl/tracking/mountains');
    try {
      final response = await _client.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        return compute(_parseAll, body);
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw Exception('클라이언트 오류 ${response.statusCode}');
      } else {
        throw Exception('서버 오류 ${response.statusCode}');
      }
    } on FormatException catch (e) {
      throw Exception('All JSON 오류: $e');
    } catch (e) {
      throw Exception('산 및 등산로 데이터 불러오기 실패: $e');
    }
  }

  /// 산 이름으로 검색
  Future<List<Mountain>> searchMountains(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final uri = Uri.parse('$_baseUrl/tracking/search?mtn=$query');
    try {
      final response = await _client.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body);

        if (jsonData['status'] == true && jsonData['data'] != null) {
          // 데이터 형식 체크
          if (jsonData['data'] is List) {
            // 리스트 형태일 경우
            final List<dynamic> data = jsonData['data'] as List<dynamic>;
            return data.map((item) => Mountain.fromJson(item)).toList();
          } else if (jsonData['data'] is Map) {
            // 맵 형태일 경우, 맵의 값들을 리스트로 변환
            final Map<String, dynamic> data =
                jsonData['data'] as Map<String, dynamic>;

            // 맵에 'mountains' 키가 있는 경우
            if (data.containsKey('mountains') && data['mountains'] is List) {
              final List<dynamic> mountains =
                  data['mountains'] as List<dynamic>;
              return mountains.map((item) => Mountain.fromJson(item)).toList();
            }
            // 결과가 하나만 있거나 배열이 아닌 객체 형태로 온 경우
            else if (data.containsKey('mountain')) {
              final mountainData = data['mountain'];
              if (mountainData != null) {
                return [Mountain.fromJson(mountainData)];
              }
            }

            // 다른 형태의 맵 처리
            try {
              // 맵의 각 값을 개별 산으로 처리
              List<Mountain> mountains = [];
              data.forEach((key, value) {
                if (value is Map<String, dynamic>) {
                  try {
                    mountains.add(Mountain.fromJson(value));
                  } catch (e) {
                    debugPrint('산 객체 변환 오류: $e');
                  }
                }
              });
              return mountains;
            } catch (e) {
              debugPrint('맵 처리 오류: $e');
              return [];
            }
          }
        }

        debugPrint('검색 결과 없음 또는 형식 불일치');
        return [];
      } else {
        debugPrint('검색 API 응답 코드: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('산 검색 오류: $e');
      return [];
    }
  }

  /// Client 자원 정리
  void dispose() {
    _client.close();
  }

  /// 선택한 산의 상세 정보 및 등산로 조회
  Future<MountainWithRoutes> getMountainByName(String mountainName) async {
    if (mountainName.isEmpty) {
      throw Exception('산 이름이 비어있습니다');
    }

    final uri =
        Uri.parse('$_baseUrl/tracking/search/results?mtn=$mountainName');
    try {
      final response = await _client.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);

        // API 응답 구조 디버깅 (직접 파싱)
        final jsonData = jsonDecode(body);
        debugPrint('API 응답 구조: ${jsonData.runtimeType}');
        debugPrint('API 응답 내용: $jsonData');

        if (jsonData == null) {
          throw FormatException('API 응답이 null입니다');
        }

        if (jsonData['status'] != true) {
          throw FormatException('API 상태가 true가 아닙니다: ${jsonData['status']}');
        }

        if (jsonData['data'] == null) {
          throw FormatException('API 데이터가 null입니다');
        }

        // 데이터 구조 검사
        final data = jsonData['data']['results'][0];
        debugPrint('data 내용: $data');

        // if (data is! Map<String, dynamic>) {
        //   throw FormatException('data가 Map 형식이 아닙니다: ${data.runtimeType}');
        // }

        // Mountain 객체 생성
        Mountain mountain;
        if (data['mountain'] == null) {
          debugPrint('mountain 데이터가 null입니다');
          mountain = Mountain(
            id: 'temp_id_for_$mountainName', // 임시 ID 부여
            name: mountainName,
            location: '',
            height: 0.0,
          );
        } else {
          try {
            mountain = Mountain.fromJson(data['mountain']);
          } catch (e) {
            debugPrint('Mountain 객체 생성 오류: $e');
            mountain = Mountain(
              id: 'temp_id_for_$mountainName', // 임시 ID 부여
              name: mountainName,
              location: '',
              height: 0.0,
            );
          }
        }

        // 등산로 정보 처리
        List<HikingRoute> routes = [];
        if (data['paths'] != null && data['paths'] is List) {
          try {
            final pathsList = data['paths'] as List;
            for (var pathData in pathsList) {
              if (pathData != null && pathData is Map<String, dynamic>) {
                try {
                  final route = HikingRoute.fromJson(pathData);
                  routes.add(route);
                } catch (routeError) {
                  debugPrint('등산로 변환 오류: $routeError');
                }
              } else {
                debugPrint('등산로 데이터가 null이거나 Map이 아닙니다: $pathData');
              }
            }
          } catch (pathError) {
            debugPrint('등산로 목록 처리 오류: $pathError');
          }
        } else {
          debugPrint('paths 데이터가 null이거나 List가 아닙니다: ${data['paths']}');
        }

        return MountainWithRoutes(mountain: mountain, routes: routes);
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw Exception('클라이언트 오류 ${response.statusCode}');
      } else {
        throw Exception('서버 오류 ${response.statusCode}');
      }
    } on FormatException catch (e) {
      debugPrint('Nearby JSON 오류: $e');
      // 오류 발생 시 기본 객체 반환
      return MountainWithRoutes(
        mountain: Mountain(
          id: 'temp_id_for_$mountainName', // 임시 ID 부여
          name: mountainName,
          location: '',
          height: 0.0,
        ),
        routes: [],
      );
    } catch (e) {
      debugPrint('주변 산 데이터 불러오기 실패: $e');
      // 오류 발생 시 기본 객체 반환
      return MountainWithRoutes(
        mountain: Mountain(
          id: 'temp_id_for_$mountainName', // 임시 ID 부여
          name: mountainName,
          location: '',
          height: 0.0,
        ),
        routes: [],
      );
    }
  }
}
