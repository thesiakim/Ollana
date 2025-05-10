// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/user/login_screen.dart';
import '../../models/app_state.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  Future<void> _handleLogout() async {
    // 비동기 작업 전에 필요한 값 캡처
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final appState = context.read<AppState>();
    final token = appState.accessToken;
    final baseUrl = dotenv.get('BASE_URL');

    // 로그아웃 확인 모달
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    // 요청 보내기
    final uri = Uri.parse('$baseUrl/auth/logout');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );

    // 응답 처리
    debugPrint('Logout status: ${res.statusCode}');
    debugPrint('Logout body: ${res.body}');

    // 위젯이 여전히 마운트되어 있는지 확인
    if (!mounted) return;

    // 403 상태코드 처리
    if (res.statusCode == 403) {
      // 앱 상태 초기화
      appState.clearAuth();

      // 스낵바 표시
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('세션이 만료되었습니다. 다시 로그인해주세요.')),
      );

      // 로그인 화면으로 이동
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    // 200 상태코드 처리
    if (res.statusCode == 200) {
      Map<String, dynamic> result;

      if (res.body.isNotEmpty) {
        try {
          result = jsonDecode(res.body) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('JSON 파싱 실패: $e');
          result = {'status': true};
        }
      } else {
        result = {'status': true};
      }

      if (!mounted) return;

      if (result['status'] == true) {
        // 인증 정보 초기화
        appState.clearAuth();

        // 성공 메시지 표시
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('로그아웃되었습니다.')),
        );
      } else {
        // 실패 메시지 표시
        final msg = result['message'] ?? '로그아웃 실패';
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } else {
      if (!mounted) return;
      // 기타 HTTP 에러 처리
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('서버 에러: ${res.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AppState>().isLoggedIn;

    return AppBar(
      title: const Text('Ollana'),
      actions: [
        TextButton(
          onPressed: () async {
            if (!isLoggedIn) {
              // 로그인 화면으로 이동
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              return;
            }

            await _handleLogout();
          },
          child: Text(
            isLoggedIn ? '로그아웃' : '로그인',
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
