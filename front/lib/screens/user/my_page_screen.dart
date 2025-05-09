// lib/screens/user/my_page_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // final user = appState.user;
    // final nickname = user?.nickname ?? '닉네임 없음';
    final nickname = 'test';
    // final email = user?.email ?? '이메일 없음';
    final email = 'test@test.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 프로필 카드
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  children: [
                    // 아바타: 기본 이미지 목데이터로 사용
                    CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            const AssetImage('lib/assets/images/alps.jpg')),
                    const SizedBox(width: 16),
                    // 닉네임 / 이메일
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nickname,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 수정하기 버튼
                    TextButton(
                      onPressed: () {
                        // TODO: 프로필 수정 화면으로 이동
                      },
                      child: const Text('수정하기'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            // 비밀번호 변경
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 비밀번호 변경 로직
              },
              icon: const Icon(Icons.lock_outline),
              label: const Text('비밀번호 변경하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),
            // 회원탈퇴
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 회원 탈퇴 로직
              },
              icon: const Text('🥲', style: TextStyle(fontSize: 24)),
              label: const Text('회원탈퇴하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
