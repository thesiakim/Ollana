import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/me_vs_me.dart';
import '../models/friend.dart';

class ModeService {
  final String _baseUrl = dotenv.get('BASE_URL');
  final http.Client _client;

  ModeService({http.Client? client}) : _client = client ?? http.Client();

  /// 나 vs 나 모드를 위한 이전 기록 조회
  Future<MeVsMe?> getMeVsMeRecord(num mountainId, num pathId,
      [String? token]) async {
    final uri =
        Uri.parse('$_baseUrl/tracking/me/mountain/$mountainId/path/$pathId');

    try {
      final headers = {
        'Accept': 'application/json',
      };

      // 토큰이 있으면 인증 헤더 추가
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body);

        return MeVsMe.fromJson(jsonData['data']);
      } else {
        debugPrint('MeVsMe API 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('MeVsMe 기록 조회 오류: $e');
      return null;
    }
  }

  /// 친구 모드에서 친구 검색
  Future<List<Friend>> searchFriends(String query, String token,
      {required num mountainId, required num pathId}) async {
    final uri = Uri.parse(
        '$_baseUrl/tracking/friends?mountainId=$mountainId&pathId=$pathId&nickname=$query');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body);

        debugPrint('친구 검색 응답: $jsonData');

        if (jsonData['status'] == true && jsonData['data'] != null) {
          // users 배열을 처리
          if (jsonData['data'] is Map && jsonData['data']['users'] is List) {
            final List<dynamic> users =
                jsonData['data']['users'] as List<dynamic>;
            return users
                .map((item) => Friend.fromJson({
                      'id': item['userId'],
                      'nickname': item['nickname'],
                      'isPossible': item['isPossible'],
                    }))
                .toList();
          }
        }
      }

      debugPrint('친구 검색 결과 없음: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('친구 검색 오류: $e');
      return [];
    }
  }

  /// Client 자원 정리
  void dispose() {
    _client.close();
  }
}
