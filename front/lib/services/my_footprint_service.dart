import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/footprint_response.dart';

class MyFootprintService {
  final String _baseUrl = dotenv.get('BASE_URL');
  final http.Client _client;

  MyFootprintService({http.Client? client}) : _client = client ?? http.Client();

  Future<FootprintResponse> getFootprints(String token, {int page = 0}) async {
    final uri = Uri.parse('$_baseUrl/footprint?page=$page');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    debugPrint('uri = $uri');
    debugPrint('headers = $headers');

    final res = await _client.get(uri, headers: headers);
    debugPrint('발자취 API 응답 코드: ${res.statusCode}');
    debugPrint('발자취 API 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final jsonData = json.decode(utf8.decode(res.bodyBytes));
      return FootprintResponse.fromJson(jsonData);
    } else {
      throw Exception("발자취 API 호출 실패: ${res.statusCode}");
    }
}
}
