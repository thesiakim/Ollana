import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/user.dart';
import '../../services/my_page_service.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late Future<User> userFuture; // Future를 상태로 관리
  bool isHikingRecordShared = false;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>(); // initState에서 watch 대신 read 사용
    final userService = MyPageService();
    userFuture = userService.fetchUserDetails(appState.accessToken ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    final userService = MyPageService();
    final newFuture = userService.fetchUserDetails(appState.accessToken ?? '');
    if (userFuture != newFuture) {
      setState(() {
        userFuture = newFuture;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: userFuture,
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No user data available'));
            }

            final user = snapshot.data as User;

            return Column(
              children: [
                // 프로필 카드
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(user.imageUrl),
                          onBackgroundImageError: (_, __) => const AssetImage(
                              'lib/assets/images/alps.jpg'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.nickname,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
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

                const SizedBox(height: 16),

                // 등산 기록 정보 제공 여부 섹션
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '등산 기록 정보 제공 여부',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '켯이 등산 기록을 획득하면 알려드려요.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isHikingRecordShared,
                      onChanged: (value) {
                        setState(() {
                          isHikingRecordShared = value;
                        });
                      },
                      activeColor: Colors.teal,
                      activeTrackColor: Colors.teal.withOpacity(0.5),
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

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
            );
          },
        ),
      ),
    );
  }
}