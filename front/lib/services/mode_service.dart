import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/me_vs_me.dart';

class ModeService {
  final String _baseUrl = dotenv.get('BASE_URL');
  final http.Client _client;

  ModeService({http.Client? client}) : _client = client ?? http.Client();

  /// 나 vs 나 모드를 위한 이전 기록 조회
  Future<MeVsMe?> getMeVsMeRecord(num mountainId, num pathId) async {
    final uri =
        Uri.parse('$_baseUrl/tracking/me/mountain/$mountainId/path/$pathId');

    try {
      final response = await _client.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body);

        if (jsonData['status'] == true && jsonData['data'] != null) {
          return MeVsMe.fromJson(jsonData['data']);
        } else {
          debugPrint('MeVsMe 데이터 없음: ${jsonData['message']}');
          return null;
        }
      } else {
        debugPrint('MeVsMe API 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('MeVsMe 기록 조회 오류: $e');
      return null;
    }
  }

  /// Client 자원 정리
  void dispose() {
    _client.close();
  }
}
