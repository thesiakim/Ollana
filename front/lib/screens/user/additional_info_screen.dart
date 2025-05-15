import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../home_screen.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../../services/kakao_auth_service.dart';

class AdditionalInfoScreen extends StatefulWidget {
  final String email;
  final String nickname;
  final String profileImage;
  final bool isSocial;
  final String tempToken;
  final int kakaoId;

  const AdditionalInfoScreen({
    Key? key,
    required this.email,
    required this.nickname,
    required this.profileImage,
    required this.isSocial,
    required this.kakaoId,
    required this.tempToken,
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
  final _kakaoAuthService = KakaoAuthService();

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
      final result = await _kakaoAuthService.completeKakaoRegistration(
        email: widget.email,
        nickname: widget.nickname,
        profileImage: widget.profileImage,
        birth: _birthController.text.trim(),
        gender: _gender,
        isSocial: widget.isSocial,
        tempToken: widget.tempToken,
        kakaoId: widget.kakaoId,
      );

      // AppState에 토큰 및 사용자 정보 저장
      await context.read<AppState>().setToken(
            result['accessToken'],
            userId: result['userId'],
            profileImageUrl: result['profileImageUrl'],
            nickname: result['nickname'],
            social: result['social'],
          );

      // 홈 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ [AdditionalInfo] 오류 발생: $e');
      setState(() => _errorMsg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🖼️ AdditionalInfoScreen 빌드');
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '추가 정보 입력', 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 프로필 이미지 표시
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      backgroundImage: widget.profileImage.isNotEmpty
                          ? NetworkImage(widget.profileImage)
                          : null,
                      child: widget.profileImage.isEmpty
                          ? Icon(Icons.person, size: 50, color: primaryColor)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 닉네임 표시
                  Center(
                    child: Text(
                      widget.nickname,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 이메일 표시
                  Center(
                    child: Text(
                      widget.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 안내 메시지
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '카카오 계정으로 처음 로그인하셨습니다\n추가 정보를 입력해 주세요',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 오류 메시지
                  if (_errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 생년월일 필드
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '생년월일',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _birthController,
                        decoration: InputDecoration(
                          hintText: '예: 19990101',
                          prefixIcon: Icon(Icons.cake, color: primaryColor),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.red),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
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
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 성별 선택
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '성별',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildGenderOption('M', '남성', Icons.male),
                            _buildGenderOption('F', '여성', Icons.female),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 가입 완료 버튼
                  ElevatedButton(
                    onPressed: _isLoading ? null : _completeRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF52A486),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '가입 완료',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final primaryColor = Color(0xFF52A486); // SignUpScreen과 동일한 색상으로 변경
    final onPrimary = Colors.white;
    final isSelected = _gender == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _gender = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? onPrimary : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}