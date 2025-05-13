import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/user.dart';
import '../../services/my_page_service.dart';
import 'edit_profile_screen.dart';
import 'password_change_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late Future<User> userFuture;
  bool? _isAgree; // 스위치 상태를 로컬로 관리

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
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
        _isAgree = null; // 토큰 변경 시 스위치 상태 초기화
      });
    }
  }

  Future<void> _handleWithdraw() async {
    final appState = context.read<AppState>();
    final userService = MyPageService();
    final social = appState.social ?? false;

    if (!social) {
      final passwordController = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('회원 탈퇴하기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('확인'),
            ),
          ],
        ),
      );

      if (result != true) return;

      try {
        await userService.withdrawUser(
          appState.accessToken ?? '',
          social,
          password: passwordController.text,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('탈퇴 실패: $e')),
        );
        return;
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('회원 탈퇴'),
          content: const Text('정말로 회원 탈퇴하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('확인'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        await userService.withdrawUser(
          appState.accessToken ?? '',
          social,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('탈퇴 실패: $e')),
        );
        return;
      }
    }

    await appState.clearAuth();
    Navigator.of(context).pushReplacementNamed('/login');
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
            if (snapshot.connectionState == ConnectionState.waiting && _isAgree == null) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No user data available'));
            }

            final user = snapshot.data as User;
            // 스위치 상태 초기화 (최초 로딩 시)
            _isAgree ??= user.agree;

            return Column(
              children: [
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
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(user.imageUrl),
                          onBackgroundImageError: (_, __) =>
                              const AssetImage('lib/assets/images/alps.jpg'),
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
                          onPressed: () async {
                            final updatedUser = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                  nickname: user.nickname,
                                  imageUrl: user.imageUrl,
                                ),
                              ),
                            );
                            if (updatedUser != null) {
                              setState(() {
                                userFuture = Future.value(updatedUser);
                                _isAgree = updatedUser.agree; // 스위치 상태 동기화
                              });
                            }
                          },
                          child: const Text('수정하기'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '등산기록 제공 동의',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '친구가 대결할 수 있도록 해주세요!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAgree!, // 로컬 상태 사용
                      onChanged: (value) async {
                        // 즉시 로컬 상태 업데이트
                        setState(() {
                          _isAgree = value;
                        });

                        final appState = context.read<AppState>();
                        final userService = MyPageService();

                        try {
                          final updatedUser = await userService.updateUserAgreement(
                            appState.accessToken ?? '',
                            value,
                          );
                          setState(() {
                            userFuture = Future.value(updatedUser);
                            _isAgree = updatedUser.agree; // 서버 응답으로 동기화
                          });
                        } catch (e) {
                          // 오류 시 원래 값으로 복원
                          setState(() {
                            _isAgree = user.agree;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('설정 변경 실패: $e')),
                          );
                        }
                      },
                      activeColor: const Color(0xFF52A486),
                      activeTrackColor: const Color(0xFF52A486).withOpacity(0.5),
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PasswordChangeScreen(
                          accessToken:
                              context.read<AppState>().accessToken ?? '',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('비밀번호 변경하기'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFF52A486),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _handleWithdraw,
                  icon: const Text('🥲', style: TextStyle(fontSize: 24)),
                  label: const Text('회원 탈퇴하기'),
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