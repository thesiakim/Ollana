// lib/screens/sign_up_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  String _gender = 'M';
  File? _profileImage;
  bool _isLoading = false;
  String? _errorMsg;
  final _picker = ImagePicker();

  bool get _passwordsMatch =>
      _passwordCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty &&
      _passwordCtrl.text == _confirmCtrl.text;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nickCtrl.dispose();
    _birthCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _handleSignUp() async {
    // 키보드 내리기
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final baseUrl = dotenv.get('BASE_URL');
    final uri = Uri.parse('$baseUrl/auth/signup');
    final req = http.MultipartRequest('POST', uri);
// 1) userData JSON 파트를 files로 추가
    req.files.add(
      http.MultipartFile.fromString(
        'userData',
        jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
          'nickname': _nickCtrl.text.trim(),
          'birth': _birthCtrl.text.trim(),
          'gender': _gender,
        }),
        contentType: MediaType('application', 'json'),
      ),
    );

// 2) 프로필 이미지(선택)가 있으면 파일 파트로 추가
    if (_profileImage != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          'profileImage',
          _profileImage!.path,
          contentType: MediaType('image', _profileImage!.path.split('.').last),
        ),
      );
    }

    try {
      debugPrint('회원가입 실행');
      final streamed = await req.send();
      debugPrint('회원가입 요청 전송 완료');
      // 스트림에서 Response 객체 생성
      final resp = await http.Response.fromStream(streamed);
      debugPrint('회원가입 응답 수신 완료: ${resp.statusCode}');

      // 바이트를 utf8로 수동 디코딩
      final bodyString = utf8.decode(resp.bodyBytes);
      debugPrint('디코딩된 응답 문자열 → $bodyString');

      // JSON 파싱
      final data = jsonDecode(bodyString);
      debugPrint('회원가입 응답 데이터: $data');

      if (!mounted) return;

      if (resp.statusCode == 200 && data['status'] == true) {
        // 성공
        context.read<AppState>().toggleLogin();
        Navigator.of(context).pop();
      } else {
        final msg = data['message'] ?? '회원가입에 실패했습니다.';
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('회원가입 실패'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('오류'),
          content: Text('네트워크 오류가 발생했습니다.\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final borderColor = Colors.grey.shade400;

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 에러 메시지 표시
              if (_errorMsg != null) ...[
                Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],

              // Email
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary)),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v != null && v.contains('@')) ? null : '유효한 이메일을 입력해 주세요.',
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary)),
                ),
                obscureText: true,
                onChanged: (_) => setState(() {}), // 매칭 상태 갱신
                validator: (v) => (v != null &&
                        v.length >= 8 &&
                        RegExp(r'[^A-Za-z0-9]').hasMatch(v))
                    ? null
                    : '8자 이상 특수문자 포함 비밀번호를 입력해 주세요.',
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmCtrl,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary)),
                ),
                obscureText: true,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return '비밀번호 확인을 입력해 주세요.';
                  }
                  if (v != _passwordCtrl.text) {
                    return '비밀번호가 일치하지 않습니다.';
                  }
                  return null;
                },
              ),
              // 일치/불일치 메시지
              if (_confirmCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _passwordsMatch ? '비밀번호가 일치합니다.' : '비밀번호가 일치하지 않습니다.',
                    style: TextStyle(
                      color: _passwordsMatch ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Nickname (한글/영문/숫자 허용)
              TextFormField(
                controller: _nickCtrl,
                decoration: InputDecoration(
                  labelText: 'Nickname',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary)),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[가-힣a-zA-Z0-9]')),
                ],
                validator: (v) =>
                    (v != null && v.trim().isNotEmpty) ? null : '닉네임을 입력해 주세요.',
              ),
              const SizedBox(height: 16),

              // Birth
              TextFormField(
                controller: _birthCtrl,
                decoration: InputDecoration(
                  labelText: 'Birth (YYYYMMDD)',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary)),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v != null && RegExp(r'^\d{8}$').hasMatch(v))
                    ? null
                    : '생년월일 8자리 숫자로 입력해 주세요.',
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Male')),
                  DropdownMenuItem(value: 'F', child: Text('Female')),
                ],
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary)),
                ),
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 16),

              // Profile Image Picker
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('프로필 사진 선택'),
                  ),
                  const SizedBox(width: 12),
                  if (_profileImage != null)
                    const Icon(Icons.check, color: Colors.green),
                ],
              ),
              const SizedBox(height: 24),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
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
