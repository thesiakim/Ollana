// lib/screens/recommend/ai_recommendation_screen.dart
import 'dart:async'; // 🔥 TimeoutException 사용
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../models/app_state.dart';

/// 긴 문자열을 여러 청크로 나눠서 찍어주는 디버그용 함수
void _printFullBody(String body) {
  const int chunkSize = 800;
  for (var i = 0; i < body.length; i += chunkSize) {
    final end = (i + chunkSize < body.length) ? i + chunkSize : body.length;
    debugPrint(body.substring(i, end));
  }
}

/// Isolate에서 JSON 파싱
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
    debugPrint('▶ initState: _fetchRecommendation 호출');
    _futureRecos = _fetchRecommendation();
  }

  Future<Map<String, dynamic>> _fetchRecommendation() async {
    debugPrint('▶ _fetchRecommendation: 시작');
    final app = context.read<AppState>();
    final userId = app.userId;
    final token = app.accessToken;
    debugPrint('   userId=$userId, token=${token?.substring(0, 10)}...');

    if (userId == null || token == null) {
      debugPrint('⚠️ 인증 정보 없음');
      throw Exception('로그인 정보가 없습니다.');
    }

    final urlStr = '${dotenv.get('AI_BASE_URL')}/recommend/$userId';
    debugPrint('   요청 URL: $urlStr');
    final resp = await http.post(
      Uri.parse(urlStr),
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint('⚠️ 요청 타임아웃');
      throw TimeoutException('요청 시간이 초과되었습니다.');
    });
    debugPrint('   HTTP 상태 코드: ${resp.statusCode}');

    if (resp.statusCode != 200) {
      debugPrint('⚠️ 서버 오류: ${resp.statusCode}');
      throw Exception('서버 오류 (${resp.statusCode})');
    }

    final bodyString = utf8.decode(resp.bodyBytes);
    _printFullBody(bodyString); // 🔥 전체 raw body 출력

    debugPrint('   compute() 호출 전');
    final data = await compute(_parseJson, bodyString);
    debugPrint('   compute() 호출 후, data.keys=${data.keys}');

    if (data['recommendations'] == null ||
        (data['recommendations'] as List).isEmpty) {
      debugPrint('⚠️ 추천 데이터 없음, message=${data['message']}');
      throw Exception(data['message'] ?? '추천된 산이 없습니다.');
    }

    debugPrint('▶ _fetchRecommendation: 완료, cluster=${data['cluster']}');
    return data;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('▶ build() 호출');
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'AI 산 추천',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Dovemayo',
              fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            debugPrint('⏪ 뒤로가기');
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureRecos,
        builder: (ctx, snap) {
          debugPrint('   FutureBuilder 상태=${snap.connectionState}');
          if (snap.connectionState != ConnectionState.done) {
            debugPrint('   → 로딩 중...');
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            debugPrint('⚠️ 에러: ${snap.error}');
            return Center(
              child: Text(
                '오류: ${snap.error}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          final data = snap.data!;
          final recs = data['recommendations'] as List;
          debugPrint('   🔥 추천 개수: ${recs.length}');

          if (recs.isEmpty) {
            debugPrint('⚠️ 추천 리스트 비어 있음');
            return const Center(child: Text('추천된 산이 없습니다.'));
          }

          // 🔥 전체 리스트를 Column으로 렌더링
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: recs.map((r) {
                final rec = r as Map<String, dynamic>;
                final name = rec['mountain_name'] as String?;
                final desc = rec['mountain_description'] as String?;
                // 🔥 URL 스킴 보정
                final rawImg = rec['image_url'] as String?;
                final imgUrl = (rawImg != null && rawImg.isNotEmpty)
                    ? (rawImg.startsWith('http://') ||
                            rawImg.startsWith('https://')
                        ? rawImg
                        : 'https://$rawImg')
                    : null;

                return GestureDetector(
                  // 🔥 카드 터치 시 모달 띄우기
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(name ?? '추천 산'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imgUrl != null)
                              Image.network(imgUrl, fit: BoxFit.cover),
                            const SizedBox(height: 12),
                            Text(
                              desc ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('닫기'),
                        ),
                      ],
                    ),
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: imgUrl != null
                              ? Image.network(
                                  imgUrl,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (ctx, child, progress) =>
                                      progress == null
                                          ? child
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                  errorBuilder: (ctx, err, st) {
                                    debugPrint('   이미지 에러: $err');
                                    return Image.asset(
                                      'lib/assets/images/mount_default.png',
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
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
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              // 🔥 설명을 3줄 초과 시 말줄임표(...) 처리
                              Text(
                                desc ?? '',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
