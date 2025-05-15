import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/app_state.dart';
import '../screens/home_screen.dart';
import '../screens/user/additional_info_screen.dart';
import '../main.dart'; // navigatorKey 가져오기 위해 import

class DeepLinkHandler {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> startListening() async { // context 제거
    try {
      final initialLink = await _appLinks.getInitialLink();
      debugPrint('✅ 초기 링크 (String): $initialLink');

      if (initialLink != null) {
        debugPrint('✅ 초기 URI: $initialLink');
        _handleUri(initialLink);
      }
    } catch (e) {
      debugPrint('❌ 초기 딥링크 처리 실패: $e');
    }

    // 실시간 URI 스트림 처리
    _sub = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('📡 실시간 URI 수신: $uri');
      _handleUri(uri);
    }, onError: (err) {
      debugPrint('❌ 딥링크 스트림 오류: $err');
    });
  }

  Future<void> _handleUri(Uri uri) async { // async가 반드시 포함되어야 함
    final status = uri.queryParameters['status'];
    final tempToken = uri.queryParameters['temp_token'];

    // navigatorKey.currentState가 준비될 때까지 대기
    await Future.delayed(Duration.zero, () async { // Future.delayed 콜백도 async로 선언
      if (navigatorKey.currentState == null) {
        debugPrint('❌ navigatorKey.currentState가 null입니다. 나중에 다시 시도합니다.');
        return;
      }

      if (status == 'login') {
        debugPrint('✅ 딥링크 status=login → 홈으로 이동');
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else if (status == 'signup' && tempToken != null) {
        debugPrint('✅ 딥링크 status=signup → tempToken=$tempToken');

        final baseUrl = dotenv.get('BASE_URL');
        final apiUri =
            Uri.parse('$baseUrl/auth/oauth/kakao/temp-user?token=$tempToken');

        try {
          final res = await http.get(apiUri); // await 사용
          final body = utf8.decode(res.bodyBytes);
          debugPrint('📡 API 응답: $body');
          final data = jsonDecode(body);
          final tempdata = data['data'];
          debugPrint('temp data : $tempdata');

          if (res.statusCode == 200 && data['status'] == true) {
            final tempUser = data['data'];
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => AdditionalInfoScreen(
                  email: tempUser['email'],
                  nickname: tempUser['nickname'],
                  profileImage: tempUser['profileImage'],
                  isSocial: tempUser['isSocial'],
                  kakaoId: tempUser['kakaoId'],
                  tempToken: tempToken,
                ),
              ),
            );
          } else {
            debugPrint('❌ 임시 유저 정보 불러오기 실패: $body');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ API 호출 오류: $e');
          debugPrint('📜 스택 트레이스: $stackTrace');
        }
      } else {
        debugPrint('⚠️ 처리할 수 없는 딥링크 URI: $uri');
      }
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}