import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../home_screen.dart';
import 'package:jwt_decode/jwt_decode.dart';

class AdditionalInfoScreen extends StatefulWidget {
  final String email;
  final String nickname;
  final String profileImage;
  final bool isSocial;
  final String tempToken; // tempToken 파라미터 추가

  const AdditionalInfoScreen({
    Key? key,
    required this.email,
    required this.nickname,
    required this.profileImage,
    required this.isSocial,
    required this.tempToken, // 생성자에 tempToken 추가
  }) : super(key: key);

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthController = TextEditingController();
  String _gender = 'F';
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _birthController.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final baseUrl = dotenv.get('BASE_URL');
      final uri = Uri.parse('$baseUrl/auth/oauth/kakao/complete');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'nickname': widget.nickname,
          'profileImage': widget.profileImage,
          'birth': _birthController.text.trim(),
          'gender': _gender,
          'isSocial': widget.isSocial,
          'tempToken': widget.tempToken, // tempToken 포함
          'kakaoId': 0, // kakaoId는 백엔드에서 tempToken으로 조회하므로 더미 값
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
        final userId = payloadA['userId']?.toString() ?? '';
        final expA = payloadA['exp'] as int;
        final expiryA = DateTime.fromMillisecondsSinceEpoch(expA * 1000);
        // ▶ setToken 호출 시 userId 전달
        await context.read<AppState>().setToken(
              accessToken,
              userId: userId,
              profileImageUrl: profileImageUrl,
              nickname: nickname,
              social: social,
            );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        setState(() => _errorMsg = data['message'] ?? '회원가입을 완료할 수 없습니다.');
      }
    } catch (e) {
      debugPrint('❌ [AdditionalInfo] 오류 발생: $e');
      setState(() => _errorMsg = '네트워크 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('추가 정보 입력'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '카카오 계정으로 처음 로그인하셨습니다.\n추가 정보를 입력해 주세요.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              if (_errorMsg != null) ...[
                Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _birthController,
                decoration: InputDecoration(
                  labelText: '생년월일 (YYYYMMDD)',
                  hintText: '예: 19990101',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                keyboardType: TextInputType.number,
                maxLength: 8,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '생년월일을 입력해 주세요';
                  }
                  if (value.length != 8) {
                    return '생년월일을 8자리로 입력해 주세요 (YYYYMMDD)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text('성별', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('여성'),
                      value: 'F',
                      groupValue: _gender,
                      onChanged: (value) {
                        setState(() {
                          _gender = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('남성'),
                      value: 'M',
                      groupValue: _gender,
                      onChanged: (value) {
                        setState(() {
                          _gender = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeRegistration,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromWidth(double.infinity),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white))
                      : const Text('가입 완료'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}