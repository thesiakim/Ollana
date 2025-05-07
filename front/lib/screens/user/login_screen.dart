// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/app_state.dart';
import './sign_up_screen.dart';

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
    debugPrint('⏳ [Login] 네트워크 요청 중...');

    try {
      final baseUrl = dotenv.get('BASE_URL');
      final uri = Uri.parse('$baseUrl/auth/login');
      debugPrint('🛠️ [Login] 요청 URL: $uri');
      debugPrint('✉️ [Login] 전달 데이터: email=${_emailController.text.trim()}');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );
      debugPrint('✅ [Login] 요청 전송 완료');
      debugPrint('🔎 [Login] 응답 코드: ${response.statusCode}');

      // UTF-8로 정확히 디코딩
      final bodyString = utf8.decode(response.bodyBytes);
      debugPrint('📦 [Login] 응답 바디 문자열: $bodyString');
      final data = jsonDecode(bodyString);
      debugPrint('💾 [Login] 파싱된 데이터: $data');

      if (response.statusCode == 200 && data['status'] == true) {
        final accessToken = data['data']['accessToken'];
        debugPrint('🔑 [Login] 토큰 얻음: $accessToken');

        context.read<AppState>().setToken(accessToken);
        debugPrint('🗝️ [Login] 토큰 저장 완료');

        context.read<AppState>().toggleLogin();
        debugPrint('👤 [Login] 로그인 상태 변경 완료');

        Navigator.of(context).pop();
        debugPrint('↩️ [Login] 화면 닫기');
      } else {
        final message = data['message'] ?? '로그인에 실패했습니다.';
        debugPrint('⚠️ [Login] 로그인 실패 메시지: $message');
        setState(() {
          _errorMsg = message;
        });
      }
    } catch (e) {
      debugPrint('🚨 [Login] 예외 발생: $e');
      setState(() {
        _errorMsg = '네트워크 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('🔚 [Login] 완료');
      }
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
      appBar: AppBar(title: const Text('로그인'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        )
                      : const Text('로그인'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: const Text('회원가입'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
