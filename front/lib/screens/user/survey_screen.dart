// lib/screens/user/survey_screen.dart

import 'dart:convert';

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
    if (_selectedTheme == null ||
        _selectedExperience == null ||
        _selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 선택해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final appState = context.read<AppState>();
    final userId = appState.userId ?? '';
    final token = appState.accessToken;

    final url = '${dotenv.get('AI_BASE_URL')}/submit_survey/$userId';

    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'theme': _selectedTheme,
          'experience': _selectedExperience,
          'region': _selectedRegion,
        }),
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body['message'] != null) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('완료'),
              content: Text(body['message']),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
          // ▶ 설문 완료 플래그를 true로 설정
          context.read<AppState>().setSurveyCompleted(true);

          Navigator.of(context).pop(); // 이전 화면으로 돌아가기
        } else {
          throw Exception('알 수 없는 응답 형식');
        }
      } else {
        final err = jsonDecode(resp.body);
        throw Exception(err['message'] ?? '설문 저장에 실패했습니다.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러: ${e.toString()}')),
      );
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
            // 상단 귀여운 마스코트 이미지
            SizedBox(
              height: 120,
              child: Image.asset('lib/assets/images/ai_recommend.png'),
            ),
            const SizedBox(height: 24),

            // 테마 선택
            DropdownButtonFormField<String>(
              decoration: _buildDecoration('테마 선택', Icons.filter_vintage),
              value: _selectedTheme,
              items: _themes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedTheme = val),
            ),
            const SizedBox(height: 16),

            // 난이도(경험) 선택
            DropdownButtonFormField<String>(
              decoration: _buildDecoration('난이도 선택', Icons.terrain),
              value: _selectedExperience,
              items: _experiences
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedExperience = val),
            ),
            const SizedBox(height: 16),

            // 지역 선택
            DropdownButtonFormField<String>(
              decoration: _buildDecoration('지역 선택', Icons.place),
              value: _selectedRegion,
              items: _regions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedRegion = val),
            ),
            const SizedBox(height: 32),

            // 제출 버튼
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
