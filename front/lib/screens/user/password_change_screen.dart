// lib/screens/user/password_change_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';

class PasswordChangeScreen extends StatefulWidget {
  /// 로그인 후 임시 비밀번호 사용자일 때 API 호출을 위해 토큰을 넘겨받습니다.
  final String accessToken;
  const PasswordChangeScreen({
    Key? key,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _newPwdCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _changePassword() async {
    final newPassword = _newPwdCtrl.text.trim();
    if (newPassword.isEmpty || newPassword.length < 6) {
      setState(() => _errorMsg = '6자 이상 새 비밀번호를 입력해 주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final token = context.read<AppState>().accessToken;
    final uri = Uri.parse('${dotenv.get('BASE_URL')}/auth/password/change');
    try {
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'newPassword': newPassword}),
      );
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
        );
        Navigator.of(context).pop();
      } else {
        setState(() => _errorMsg = data['message'] ?? '비밀번호 변경에 실패했습니다.');
      }
    } catch (e) {
      setState(() => _errorMsg = '네트워크 오류가 발생했습니다.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _newPwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 변경')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMsg != null) ...[
              Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _newPwdCtrl,
              decoration: const InputDecoration(
                labelText: '새 비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('비밀번호 변경'),
            ),
          ],
        ),
      ),
    );
  }
}
