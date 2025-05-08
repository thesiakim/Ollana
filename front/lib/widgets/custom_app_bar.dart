// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/user/login_screen.dart';
import '../../models/app_state.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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

            // 1) 백엔드 로그아웃 요청
            final token = context.read<AppState>().accessToken;
            final uri = Uri.parse('${dotenv.get('BASE_URL')}/auth/logout');
            final res = await http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({}),
            );

            // 2) 응답 처리
            debugPrint('Logout status: ${res.statusCode}');
            debugPrint('Logout body: ${res.body}');

            if (res.statusCode == 403) {
              // 1) 상태 초기화
              context.read<AppState>().clearAuth();

              // 2) 스낵바 띄우기
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('세션이 만료되었습니다. 다시 로그인해주세요.')),
              );

              // 3) 로그인 화면으로 이동 (기존 스택 모두 지우고)
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
              return;
            }

            if (res.statusCode == 200) {
              // 결과 맵 초기화
              Map<String, dynamic> result;
              if (res.body.isNotEmpty) {
                try {
                  result = jsonDecode(res.body) as Map<String, dynamic>;
                } catch (e) {
                  debugPrint('JSON 파싱 실패: $e');
                  // 빈 바디 또는 잘못된 JSON은 성공 처리
                  result = {'status': true};
                }
              } else {
                // 바디가 비어 있으면, 성공으로 간주
                result = {'status': true};
              }

              if (result['status'] == true) {
                // 클라이언트 인증 정보 초기화
                context.read<AppState>().clearAuth();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('로그아웃되었습니다.')),
                );
              } else {
                final msg = result['message'] ?? '로그아웃 실패';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              }
            } else {
              // 200 이외의 HTTP 상태 코드 처리
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('서버 에러: ${res.statusCode}')),
              );
            }
          },
          child: Text(
            isLoggedIn ? 'Logout' : 'Login',
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
