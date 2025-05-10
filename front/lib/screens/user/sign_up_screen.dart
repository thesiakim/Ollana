// lib/screens/sign_up_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_state.dart';
import 'package:http_parser/http_parser.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

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
  final _codeCtrl = TextEditingController();
  String _gender = 'M';
  File? _profileImage;
  bool _isLoading = false;
  bool _isSending = false;
  bool _isVerifying = false;
  bool _emailSent = false;
  bool _emailVerified = false;
  String? _errorMsg;
  String? _verifyError;
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
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = '유효한 이메일을 입력해 주세요.');
      return;
    }
    setState(() {
      _isSending = true;
      _errorMsg = null;
    });
    final uri = Uri.parse('${dotenv.get('BASE_URL')}/auth/email/send');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          setState(() {
            _emailSent = true;
            _verifyError = null;
          });
        } else {
          setState(() => _errorMsg = data['message'] ?? '인증 코드 전송 실패');
        }
      } else {
        setState(() => _errorMsg = '서버 오류: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMsg = '네트워크 오류 발생');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _verifyError = '인증 코드를 입력해 주세요.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _verifyError = null;
    });
    final uri = Uri.parse('${dotenv.get('BASE_URL')}/auth/email/verify');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          setState(() {
            _emailVerified = true;
          });
        } else {
          setState(() => _verifyError = data['message'] ?? '인증 코드 확인 실패');
        }
      } else {
        setState(() => _verifyError = '서버 오류: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _verifyError = '네트워크 오류 발생');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || !_emailVerified) {
      if (!_emailVerified) {
        setState(() => _errorMsg = '이메일 인증을 완료해 주세요.');
      }
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    final baseUrl = dotenv.get('BASE_URL');
    final uri = Uri.parse('$baseUrl/auth/signup');
    final req = http.MultipartRequest('POST', uri);
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
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      final bodyString = utf8.decode(resp.bodyBytes);
      final data = jsonDecode(bodyString);
      if (!mounted) return;
      if (resp.statusCode == 200 && data['status'] == true) {
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
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('오류'),
          content: Text('네트워크 오류가 발생했습니다.\n\$e'),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMsg != null) ...[
                Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],

              // Email + Send Code
              // Email 입력
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
                  filled: _emailVerified, // 인증 완료 시 회색 배경
                  fillColor: _emailVerified ? Colors.grey.shade200 : null,
                  suffixIcon: _emailVerified
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_emailVerified,
                validator: (v) =>
                    v != null && v.contains('@') ? null : '유효한 이메일을 입력해 주세요.',
              ),
              const SizedBox(height: 8),
              // 인증 코드 전송 버튼 (이메일 아래)
              ElevatedButton(
                onPressed: (_isSending || _emailSent || _emailVerified)
                    ? null
                    : _sendVerificationCode,
                child: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('인증 코드 전송'),
              ),
              const SizedBox(height: 16),
              // 인증 코드 입력 및 확인
              if (_emailSent && !_emailVerified) ...[
                TextFormField(
                  controller: _codeCtrl,
                  decoration: InputDecoration(
                    labelText: '인증 코드',
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primary)),
                  ),
                ),
                if (_verifyError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _verifyError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyCode,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('인증 확인'),
                ),
                const SizedBox(height: 16),
              ],

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
                onChanged: (_) => setState(() {}),
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
                  if (v == null || v.isEmpty) return '비밀번호 확인을 입력해 주세요.';
                  if (v != _passwordCtrl.text) return '비밀번호가 일치하지 않습니다.';
                  return null;
                },
              ),
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

              // Nickname
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
                  FilteringTextInputFormatter.allow(RegExp(r'[가-힣a-zA-Z0-9]'))
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
                validator: (v) => v != null && RegExp(r'^\d{8}$').hasMatch(v)
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
