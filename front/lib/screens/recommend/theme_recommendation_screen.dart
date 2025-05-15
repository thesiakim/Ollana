// lib/screens/recommend/theme_recommendation_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Map<String, dynamic> _parseJson(String body) => jsonDecode(body);

class ThemeRecommendationScreen extends StatefulWidget {
  const ThemeRecommendationScreen({Key? key}) : super(key: key);

  static const themes = ['계곡', '아름다운', '단풍'];

  @override
  _ThemeRecommendationScreenState createState() =>
      _ThemeRecommendationScreenState();
}

class _ThemeRecommendationScreenState extends State<ThemeRecommendationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Map<String, Future<Map<String, dynamic>>> _futures;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ThemeRecommendationScreen.themes.length,
      vsync: this,
    );
    // 각 테마별 API 호출 Future 캐싱 (토큰 없이)
    _futures = {
      for (var theme in ThemeRecommendationScreen.themes)
        theme: _fetchByKeyword(theme),
    };
  }

  Future<Map<String, dynamic>> _fetchByKeyword(String keyword) async {
    final url = Uri.parse(
      '${dotenv.get('AI_BASE_URL')}/recommend_by_keyword',
    );

    final resp = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'keyword': keyword}),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('요청 시간이 초과되었습니다.'),
        );

    if (resp.statusCode != 200) {
      throw Exception('서버 오류 (${resp.statusCode})');
    }

    // 바디를 UTF-8로 디코딩
    final bodyString = utf8.decode(resp.bodyBytes);
    // JSON 파싱 isolate 분리
    final data = await compute(_parseJson, bodyString);
    data['recommendations'] ??= [];
    return data;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: Colors.white),
        title: const Text(
          '테마별 추천',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Dovemayo',
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: ThemeRecommendationScreen.themes
              .map((t) => Tab(text: t))
              .toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: ThemeRecommendationScreen.themes.map((theme) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _futures[theme],
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Text(
                    '오류: ${snap.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              final data = snap.data!;
              final recs = data['recommendations'] as List;
              if (recs.isEmpty) {
                return const Center(child: Text('추천된 산이 없습니다.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recs.length,
                itemBuilder: (ctx, i) {
                  final rec = recs[i] as Map<String, dynamic>;
                  final name = rec['mountain_name'] as String? ?? '';
                  final desc = rec['mountain_description'] as String? ?? '';
                  final rawImg = rec['image_url'] as String?;
                  final imgUrl = (rawImg != null && rawImg.isNotEmpty)
                      ? (rawImg.startsWith('http') ? rawImg : 'https://$rawImg')
                      : null;

                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(name),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (imgUrl != null)
                                    Image.network(imgUrl, fit: BoxFit.cover)
                                  else
                                    Image.asset(
                                      'lib/assets/images/mount_default.png',
                                      fit: BoxFit.cover,
                                    ),
                                  const SizedBox(height: 12),
                                  Text(desc),
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
                        );
                      },
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
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'lib/assets/images/mount_default.png',
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
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
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  desc,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
