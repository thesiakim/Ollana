// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jwt_decode/jwt_decode.dart'; // 🔥 JWT 디코딩 패키지

import '../../models/app_state.dart';
import './sign_up_screen.dart';
import './password_reset_screen.dart';
import './password_change_screen.dart'; // 🔥 비밀번호 변경 페이지 import
import '../home_screen.dart'; // 🔥 홈 화면 import
import '../../widgets/custom_app_bar.dart'; // 🔥 CustomAppBar import

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    debugPrint('🔄 [Login] 시작');
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ [Login] 유효성 검사 실패');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final baseUrl = dotenv.get('BASE_URL');
      final uri = Uri.parse('$baseUrl/auth/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );
      final bodyString = utf8.decode(response.bodyBytes);
      final data = jsonDecode(bodyString);

      if (response.statusCode == 200 && data['status'] == true) {
        final accessToken = data['data']['accessToken'];
        final profileImageUrl = data['data']['user']['profileImageUrl'];
        final nickname = data['data']['user']['nickname'];
        final social = data['data']['user']['social'] as bool;
        final payloadA = Jwt.parseJwt(accessToken);
        final expA = payloadA['exp'] as int;
        final expiryA = DateTime.fromMillisecondsSinceEpoch(expA * 1000);
        await context.read<AppState>().setToken(
              accessToken,
              profileImageUrl: profileImageUrl,
              nickname: nickname,
              social: social,
            );

        // 🔥 tempPassword 검사
        final user = data['data']['user'];
        final isTemp = (user['tempPassword'] as bool?) ?? false;
        if (isTemp) {
          // 1) 확인용 모달창 띄우기
          final shouldChange = await showDialog<bool>(
            context: context,
            barrierDismissible: false, // 바깥 터치로 닫히지 않게
            builder: (ctx) => AlertDialog(
              title: const Text('임시 비밀번호 안내'),
              content: const Text('현재 임시비밀번호 발급을 받으셨습니다.\n'
                  '비밀번호 변경 페이지로 이동하시겠습니까?'),
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

          // 2) 확인을 눌렀을 때만 이동
          if (shouldChange == true) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PasswordChangeScreen(
                  accessToken: accessToken,
                ),
              ),
            );
          }
          return; // 모달 후엔 함수 종료
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        setState(() => _errorMsg = data['message'] ?? '로그인에 실패했습니다.');
      }
    } catch (e) {
      debugPrint('❌ [Login] 오류 발생: $e');
      setState(() => _errorMsg = '네트워크 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, Color color) {
    return InputDecoration(
      labelText: label,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          '로그인',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMsg != null) ...[
                Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email', primaryColor),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v?.contains('@') ?? false) ? null : '유효한 이메일을 입력해 주세요.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration('Password', primaryColor),
                obscureText: true,
                validator: (v) => (v != null && v.length >= 6)
                    ? null
                    : '6자 이상 비밀번호를 입력해 주세요.',
              ),
              const SizedBox(height: 8),

              // 회원가입과 비밀번호 찾기를 가깝게 배치
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: const Text('회원가입', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PasswordResetScreen()),
                      );
                    },
                    child:
                        const Text('비밀번호 찾기', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 로그인 버튼 (전체 너비)
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromWidth(double.infinity),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white))
                      : const Text(
                          '로그인',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 카카오톡 시작하기 버튼
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 카카오톡 로그인 기능 구현
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('카카오톡으로 시작하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromWidth(double.infinity),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
