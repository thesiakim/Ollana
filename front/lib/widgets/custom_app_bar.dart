// lib/widgets/custom_app_bar.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final String _title = 'Ollana';
  int _bounceIndex = -1; // 🔥 현재 튀는 글자 인덱스

  @override
  void initState() {
    super.initState();
    _startBounceLoop(); // 🔥 글자별 바운스 시작
  }

  void _startBounceLoop() {
    // 비동기 루프: 글자 하나씩 튀고, 한 바퀴 돌면 5초 대기
    Future(() async {
      while (mounted) {
        for (int i = 0; i < _title.length; i++) {
          if (!mounted) return;
          setState(() => _bounceIndex = i); // 🔥 i번째 글자 튀기기
          await Future.delayed(const Duration(milliseconds: 400));
        }
        if (!mounted) return;
        setState(() => _bounceIndex = -1); // 🔥 리셋(모두 내려옴)
        await Future.delayed(const Duration(seconds: 5));
      }
    });
  }

  Future<void> _handleLogout() async {
    final scaffold = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final appState = context.read<AppState>();
    final token = appState.accessToken;
    final baseUrl = dotenv.get('BASE_URL');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final res = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );

    if (!mounted) return;

    if (res.statusCode == 403) {
      appState.clearAuth();
      scaffold.showSnackBar(
          const SnackBar(content: Text('세션이 만료되었습니다. 다시 로그인해주세요.')));
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    if (res.statusCode == 200) {
      try {
        final result = jsonDecode(res.body) as Map<String, dynamic>;
        if (result['status'] == true) {
          appState.clearAuth();
          scaffold.showSnackBar(const SnackBar(content: Text('로그아웃되었습니다.')));
        } else {
          scaffold.showSnackBar(
              SnackBar(content: Text(result['message'] ?? '로그아웃 실패')));
        }
      } catch (_) {
        appState.clearAuth();
        scaffold.showSnackBar(const SnackBar(content: Text('로그아웃되었습니다.')));
      }
    } else {
      scaffold
          .showSnackBar(SnackBar(content: Text('서버 에러: ${res.statusCode}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AppState>().isLoggedIn;

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      centerTitle: true,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_title.length, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(
                0, _bounceIndex == i ? -8 : 0, 0), // 🔥 튀는 효과
            child: Text(
              _title[i],
              style: const TextStyle(
                fontFamily: 'GmarketSans',
                fontWeight: FontWeight.w500,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (!isLoggedIn) {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            } else {
              _handleLogout();
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: 'GmarketSans',
              fontWeight: FontWeight.w500,
            ),
          ),
          child: Text(isLoggedIn ? '로그아웃' : '로그인'),
        ),
      ],
    );
  }
}
