// lib/screens/user/survey_screen.dart

import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../models/app_state.dart';
import '../../widgets/custom_app_bar.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({Key? key}) : super(key: key);

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  String? _selectedTheme;
  String? _selectedExperience;
  String? _selectedRegion;
  bool _isLoading = false;

  final List<String> _themes = ['단풍', '아름다운', '계곡'];
  final List<String> _experiences = ['초급', '중급', '고급'];
  final List<String> _regions = [
    '전국',
    '서울',
    '경기',
    '강원',
    '충청',
    '경상',
    '전라',
  ];

  Future<void> _submitSurvey() async {
    // ▶ 입력값 유효성 확인
    if (_selectedTheme == null ||
        _selectedExperience == null ||
        _selectedRegion == null) {
      debugPrint('▶ _submitSurvey: 선택값 없음'); // 디버그
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 선택해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final appState = context.read<AppState>();
    final userId = appState.userId;
    final token = appState.accessToken;

    debugPrint('▶ userId: $userId, token: ${token?.substring(0, 10)}...');

    if (userId == null || token == null) {
      debugPrint('▶ _submitSurvey: userId 또는 token null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 정보가 없습니다. 다시 로그인해주세요.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final endpoint = '${dotenv.get('AI_BASE_URL')}/submit_survey/$userId';
    debugPrint('▶ 요청 URL: $endpoint');

    try {
      final bodyMap = {
        'theme': _selectedTheme,
        'experience': _selectedExperience,
        'region': _selectedRegion,
      };
      final bodyJson = jsonEncode(bodyMap);
      debugPrint('▶ 요청 바디: $bodyJson');

      final resp = await http
          .post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: bodyJson,
      )
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('요청이 시간 초과되었습니다.');
      });

      debugPrint('▶ HTTP 상태 코드: ${resp.statusCode}');
      final respBody = utf8.decode(resp.bodyBytes);
      debugPrint('▶ 응답 바디(raw): $respBody');

      if (resp.statusCode == 200) {
        final data = jsonDecode(respBody) as Map<String, dynamic>;
        debugPrint('▶ 파싱된 응답: $data');

        final msg = data['message'] as String?;
        if (msg != null) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('완료'),
              content: Text(msg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
          context.read<AppState>().setSurveyCompleted(true);
          Navigator.of(context).pop();
        } else {
          throw Exception('알 수 없는 응답 형식');
        }
      } else {
        debugPrint('▶ 서버 에러 발생');
        final errData = jsonDecode(respBody) as Map<String, dynamic>?;
        debugPrint('▶ 에러 파싱: $errData');
        final errMsg = errData?['message'] as String? ?? '설문 저장 실패';
        throw Exception(errMsg);
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('요청 시간이 초과되었습니다.')));
    } catch (e) {
      debugPrint('❌ 예외 발생: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('에러: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF52A486)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF52A486), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: Image.asset('lib/assets/images/ai_recommend.png'),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: _buildDecoration('테마 선택', Icons.filter_vintage),
              value: _selectedTheme,
              items: _themes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedTheme = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: _buildDecoration('난이도 선택', Icons.terrain),
              value: _selectedExperience,
              items: _experiences
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedExperience = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: _buildDecoration('지역 선택', Icons.place),
              value: _selectedRegion,
              items: _regions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedRegion = val),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_selectedTheme != null &&
                        _selectedExperience != null &&
                        _selectedRegion != null &&
                        !_isLoading)
                    ? _submitSurvey
                    : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      )
                    : const Text('제출하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
