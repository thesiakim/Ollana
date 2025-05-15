// lib/screens/recommend/location_recommendation_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Map<String, dynamic> _parseJson(String body) => jsonDecode(body);

class LocationRecommendationScreen extends StatefulWidget {
  const LocationRecommendationScreen({Key? key}) : super(key: key);

  @override
  _LocationRecommendationScreenState createState() =>
      _LocationRecommendationScreenState();
}

class _LocationRecommendationScreenState
    extends State<LocationRecommendationScreen> {
  final List<String> _regions = [
    '서울',
    '경기',
    '강원',
    '충청',
    '경상',
    '전라',
  ]; // ▶ 사용자가 선택할 수 있는 지역 리스트

  String? _selectedRegion; // ▶ 사용자가 선택한 지역
  Future<Map<String, dynamic>>? _futureRecos; // ▶ API 결과 Future

  @override
  void initState() {
    super.initState();
    _selectedRegion = _regions.first; // ▶ 초기 선택값
  }

  Future<Map<String, dynamic>> _fetchByRegion(String region) async {
    final url = Uri.parse('${dotenv.get('AI_BASE_URL')}/recommend_by_region');
    final resp = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'region': region}),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('요청 시간이 초과되었습니다.'),
        );

    if (resp.statusCode != 200) {
      throw Exception('서버 오류 (${resp.statusCode})');
    }

    final bodyString = utf8.decode(resp.bodyBytes);
    final data = await compute(_parseJson, bodyString);
    data['recommendations'] ??= [];
    return data;
  }

  void _onRecommendPressed() {
    if (_selectedRegion == null) return;
    setState(() {
      // ▶ 사용자가 선택한 지역으로 Future 재생성
      _futureRecos = _fetchByRegion(_selectedRegion!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          '지역별 추천',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Dovemayo',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRegion,
                    decoration: InputDecoration(
                      labelText: '지역 선택',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _regions
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedRegion = val),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _onRecommendPressed,
                  child: const Text('추천 보기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _futureRecos == null
                ? const Center(
                    child: Text(
                      '원하는 지역을 선택하고\n"추천 보기"를 눌러주세요.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : FutureBuilder<Map<String, dynamic>>(
                    future: _futureRecos,
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            '오류: ${snap.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      final data = snap.data!;
                      final recs = data['recommendations'] as List<dynamic>;
                      if (recs.isEmpty) {
                        return const Center(child: Text('추천된 산이 없습니다.'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: recs.length,
                        itemBuilder: (ctx, i) {
                          final rec = recs[i] as Map<String, dynamic>;
                          final name = rec['mountain_name'] as String? ?? '';
                          final desc =
                              rec['mountain_description'] as String? ?? '';
                          final rawImg = rec['image_url'] as String?;
                          final imgUrl = (rawImg != null && rawImg.isNotEmpty)
                              ? (rawImg.startsWith('http')
                                  ? rawImg
                                  : 'https://$rawImg')
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (imgUrl != null)
                                            Image.network(imgUrl,
                                                fit: BoxFit.cover)
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
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
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
                                            errorBuilder: (_, __, ___) =>
                                                Image.asset(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                  ),
          ),
        ],
      ),
    );
  }
}
