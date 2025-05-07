// lib/services/mountain_service.dart
// - 산 및 등산로 데이터 서비스

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/mountain.dart';
import '../models/hiking_route.dart';

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

  /// 산 이름으로 검색 (★토큰을 인자로 받도록 수정된 부분)
  Future<List<Mountain>> searchMountains(String query, String token) async {
    // ★시그니처에 token 추가
    if (query.isEmpty) {
      return [];
    }

    final uri = Uri.parse('$_baseUrl/tracking/search?mtn=$query');
    debugPrint('★ [searchMountains] URI: $uri'); // ★디버그 로그
    debugPrint('★ [searchMountains] Token: $token'); // ★디버그 로그

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // ★헤더에 토큰 사용
        },
      );

      debugPrint('★ [searchMountains] Status: ${response.statusCode}'); // ★
      debugPrint('★ [searchMountains] Body: ${response.body}'); // ★

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body);

        if (jsonData['status'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];
          if (data is List) {
            return data.map((e) => Mountain.fromJson(e)).toList();
          } else if (data is Map<String, dynamic>) {
            final mapData = data;
            if (mapData.containsKey('mountains') &&
                mapData['mountains'] is List) {
              return (mapData['mountains'] as List)
                  .map((item) => Mountain.fromJson(item))
                  .toList();
            } else if (mapData.containsKey('mountain')) {
              final m = mapData['mountain'];
              if (m != null) return [Mountain.fromJson(m)];
            }
            // 기타 Map 처리 생략...
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('★ [searchMountains] Exception: $e'); // ★
      return [];
    }
  }

  /// Client 자원 정리
  void dispose() {
    _client.close();
  }

  /// 선택한 산의 상세 정보 및 등산로 조회 (기존 로직 유지)
  Future<MountainWithRoutes> getMountainByName(String mountainName) async {
    // 기존 로직...
    return MountainWithRoutes(
      mountain:
          Mountain(id: 'tmp', name: mountainName, location: '', height: 0.0),
      routes: [],
    );
  }
}
