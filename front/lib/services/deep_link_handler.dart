import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/app_state.dart';
import '../screens/home_screen.dart';
import '../screens/user/additional_info_screen.dart';

class DeepLinkHandler {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> startListening(BuildContext context) async {
    try {
      final initialLink = await _appLinks.getInitialLink(); // ✅ 수정된 부분
      debugPrint('✅ 초기 링크 (String): $initialLink');

      if (initialLink != null) {
        final uri = await _appLinks.getInitialLink();
        debugPrint('✅ 초기 URI: $uri');

        if (uri != null) {
          _handleUri(context, uri);
        }
      }
    } catch (e) {
      debugPrint('❌ 초기 딥링크 처리 실패: $e');
    }


    // ✅ 앱이 실행 중일 때 URI 스트림 처리
    _sub = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('📡 실시간 URI 수신: $uri');
      _handleUri(context, uri);
    }, onError: (err) {
      debugPrint('❌ 딥링크 스트림 오류: $err');
    });
  }

  Future<void> _handleUri(BuildContext context, Uri uri) async {
    final status = uri.queryParameters['status'];
    final tempToken = uri.queryParameters['temp_token'];

    if (status == 'login') {
      debugPrint('✅ 딥링크 status=login → 홈으로 이동');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (status == 'signup' && tempToken != null) {
      debugPrint('✅ 딥링크 status=signup → tempToken=$tempToken');

      final baseUrl = dotenv.get('BASE_URL');
      final apiUri =
          Uri.parse('$baseUrl/auth/oauth/kakao/temp-user?token=$tempToken');

      try {
        final res = await http.get(apiUri);
        final body = utf8.decode(res.bodyBytes);
        final data = jsonDecode(body);

        if (res.statusCode == 200 && data['status'] == true) {
          final tempUser = data['data'];
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdditionalInfoScreen(
                email: tempUser['email'],
                nickname: tempUser['nickname'],
                profileImage: tempUser['profileImage'],
                isSocial: tempUser['socialLogin'],
                tempToken: tempToken,
              ),
            ),
          );
        } else {
          debugPrint('❌ 임시 유저 정보 불러오기 실패: $body');
        }
      } catch (e) {
        debugPrint('❌ API 호출 오류: $e');
      }
    } else {
      debugPrint('⚠️ 처리할 수 없는 딥링크 URI: $uri');
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
