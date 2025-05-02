import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import './sign_up_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // 추가됨: 일관된 입력 테두리 스타일링
  OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderSide: BorderSide(color: color),
      borderRadius: BorderRadius.circular(4),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // TODO: 실제 회원가입 로직(API 요청) 추가
    await Future.delayed(const Duration(seconds: 1));

    // 가입 후 자동 로그인 처리
    context.read<AppState>().toggleLogin();
    setState(() => _isLoading = false);
    Navigator.of(context).pop(); // 회원가입 화면 닫기
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 추가됨: 회원가입 제목
              Center(
                child: const Text(
                  '계정 생성',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: _inputBorder(Colors.grey),
                  enabledBorder: _inputBorder(Colors.grey),
                  focusedBorder: _inputBorder(primaryColor),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해 주세요.';
                  }
                  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+\$');
                  if (!regex.hasMatch(value)) {
                    return '유효한 이메일을 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: _inputBorder(Colors.grey),
                  enabledBorder: _inputBorder(Colors.grey),
                  focusedBorder: _inputBorder(primaryColor),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해 주세요.';
                  }
                  if (value.length < 6) {
                    return '6자 이상 비밀번호를 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: _inputBorder(Colors.grey),
                  enabledBorder: _inputBorder(Colors.grey),
                  focusedBorder: _inputBorder(primaryColor),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호 확인을 입력해 주세요.';
                  }
                  if (value != _passwordController.text) {
                    return '비밀번호가 일치하지 않습니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text('회원가입'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
