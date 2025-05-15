import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class KakaoAuthService {
  String _getKakaoAuthUrl() {
    final clientId = dotenv.env['KAKAO_CLIENT_ID'] ?? '';
    final redirectUri = 'https://k12c104.p.ssafy.io/back-api/auth/oauth/kakao';
    final authUrl =
        'https://kauth.kakao.com/oauth/authorize?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&lang=ko';

    debugPrint('🔗 [KakaoAuth] URL: $authUrl');
    return authUrl;
  }


  Future<void> loginWithKakao(BuildContext context) async {
    try {
      final authUrl = _getKakaoAuthUrl();
      final uri = Uri.parse(authUrl);
      debugPrint('🔄 [KakaoAuth] URL 열기 시도: $uri');

      final canLaunch = await canLaunchUrl(uri);
      debugPrint('🔍 [KakaoAuth] canLaunchUrl: $canLaunch');

      if (canLaunch) {
        debugPrint('✅ [KakaoAuth] URL 열기 가능');
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // 외부 브라우저에서 실행
        );
        debugPrint('🚀 [KakaoAuth] URL 열림');
      } else {
        debugPrint('❌ [KakaoAuth] URL 열기 불가능');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('브라우저를 열 수 없습니다. 기본 브라우저가 설치되어 있는지 확인하세요.'),
          ),
        );
        throw '카카오 인증 URL을 열 수 없습니다.';
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [KakaoAuth] 오류: $e');
      debugPrint('📜 [KakaoAuth] 스택 트레이스: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인 중 오류가 발생했습니다: $e')),
      );
      rethrow;
    }
  }
}