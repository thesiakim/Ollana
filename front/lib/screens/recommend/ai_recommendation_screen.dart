// lib/screens/recommend/ai_recommendation_screen.dart
import 'dart:convert';
import 'dart:async'; // ← 이 줄 추가

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/app_state.dart';

Map<String, dynamic> _parseJson(String body) {
  debugPrint('🔧 [_parseJson] isolate 파싱 시작');
  final result = jsonDecode(body);
  debugPrint('🔧 [_parseJson] isolate 파싱 완료');
  return result;
}

class AiRecommendationScreen extends StatefulWidget {
  const AiRecommendationScreen({Key? key}) : super(key: key);

  @override
  _AiRecommendationScreenState createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen> {
  late final Future<Map<String, dynamic>> _futureRecos;

  @override
  void initState() {
    super.initState();
    debugPrint('▶ initState: 화면 최초 렌더링, _fetchRecommendation 호출');
    _futureRecos = _fetchRecommendation();
  }

  Future<Map<String, dynamic>> _fetchRecommendation() async {
    debugPrint('▶ _fetchRecommendation: 시작');
    final app = context.read<AppState>();
    final userId = app.userId;
    final token = app.accessToken;
    debugPrint('   userId=$userId, token=${token?.substring(0, 10)}...');

    if (userId == null || token == null) {
      debugPrint('⚠️ _fetchRecommendation: 인증 정보 없음');
      throw Exception('로그인 정보가 없습니다.');
    }

    final urlStr = '${dotenv.get('AI_BASE_URL')}/recommend/$userId';
    debugPrint('   요청 URL: $urlStr');
    final url = Uri.parse(urlStr);

    final resp = await http.post(url, headers: {
      'Content-Type': 'application/json',
      'authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint('⚠️ _fetchRecommendation: 요청 타임아웃');
      throw TimeoutException('요청 시간이 초과되었습니다.');
    });
    debugPrint('   HTTP 상태 코드: ${resp.statusCode}');

    if (resp.statusCode != 200) {
      debugPrint('   ⚠️ 서버 오류: ${resp.statusCode}');
      throw Exception('서버 오류 (${resp.statusCode})');
    }

    final bodyString = utf8.decode(resp.bodyBytes);
    debugPrint('   raw body: $bodyString');

    debugPrint('   compute() 호출 전');
    final data = await compute(_parseJson, bodyString);
    debugPrint('   compute() 호출 후, data.keys=${data.keys}');

    if (data['recommendations'] == null ||
        (data['recommendations'] as List).isEmpty) {
      debugPrint('   ⚠️ 추천 데이터 없음, message=${data['message']}');
      throw Exception(data['message'] ?? '추천된 산이 없습니다.');
    }

    debugPrint('▶ _fetchRecommendation: 완료, cluster=${data['cluster']}');
    return data;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('▶ build() 호출: FutureBuilder 렌더링');
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
        title: const Text('AI 산 추천', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            debugPrint('⏪ 뒤로가기 버튼 클릭');
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureRecos,
        builder: (ctx, snap) {
          debugPrint('   FutureBuilder: 상태=${snap.connectionState}');
          if (snap.connectionState != ConnectionState.done) {
            debugPrint('   → 로딩 중...');
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            debugPrint('   ⚠️ 에러 발생: ${snap.error}');
            return Center(
              child: Text(
                '오류: ${snap.error}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }
          debugPrint('   ✅ 데이터 수신 성공, 렌더링 준비');
          final data = snap.data!;
          final recs = data['recommendations'] as List;
          if (recs.isEmpty) {
            debugPrint('   ⚠️ recommendation 리스트가 비어 있음');
            return const Center(child: Text('추천된 산이 없습니다.'));
          }
          final rec = recs.first as Map<String, dynamic>;
          debugPrint('   첫 번째 추천: ${rec['mountain_name']}');

          final name = rec['mountain_name'] as String?;
          final desc = rec['mountain_description'] as String?;
// … rec, name, desc 구문 생략 …

// 1) 원본 URL 가져오기 & 스킴 보정
          final rawImg = rec['image_url'] as String?;
          final imgUrl = (rawImg != null && rawImg.isNotEmpty)
              ? (rawImg.startsWith('http://') || rawImg.startsWith('https://')
                  ? rawImg
                  : 'https://$rawImg')
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2) ClipRRect 안에서 network/asset 조건 분기
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: imgUrl != null
                        ? Image.network(
                            imgUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder: (ctx, err, st) {
                              debugPrint('   이미지 로딩 에러: $err');
                              // 3) 에러 시 로컬 에셋으로 대체
                              return Image.asset(
                                'lib/assets/images/mount_default.png',
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            // 4) imgUrl 자체가 null/빈 문자열일 때
                            'lib/assets/images/mount_default.png',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          name ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(desc ?? '', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
