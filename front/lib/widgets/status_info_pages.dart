// status_info_pages.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ← dotenv 로드
import '../../models/app_state.dart';

class FirstStatusInfo extends StatefulWidget {
  const FirstStatusInfo({super.key});

  @override
  State<FirstStatusInfo> createState() => _FirstStatusInfoState();
}

class _FirstStatusInfoState extends State<FirstStatusInfo> {
  late Future<int> _climbingIndexFuture;

  @override
  void initState() {
    super.initState();
    _climbingIndexFuture = fetchClimbingIndex();
  }

  Future<int> fetchClimbingIndex() async {
    final baseUrl = dotenv.env['AI_BASE_URL']!; // ← 빈 문자열 대신 non-null 단언
    debugPrint('▶ AI_BASE_URL = $baseUrl'); // ← 로깅 추가
    final url = Uri.parse('$baseUrl/weather'); // ← leading slash 제거, 올바른 URI 형식
    final token = Provider.of<AppState>(context, listen: false).accessToken;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['score'] != null) {
        final rawScore = data['score'];
        if (rawScore is num) {
          return rawScore.toInt(); // ← num으로 받아서 toInt()
        }
        throw Exception('score 필드가 숫자가 아닙니다.');
      }
      throw Exception('API 응답에 score 필드가 없습니다.');
    } else {
      throw Exception('등산지수 조회 실패: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _climbingIndexFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              '오류: ${snapshot.error}', // ← 실제 예외 메시지 노출
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
          );
        } else if (snapshot.hasData) {
          final score = snapshot.data!;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '등산지수',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$score', // ← 문자열 보간 바로 적용
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(2, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class SecondStatusInfo extends StatelessWidget {
  const SecondStatusInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double fontSize = constraints.maxHeight < 150 ? 11.0 : 13.0;
      double spacing = constraints.maxHeight < 150 ? 2.0 : 2.0;
      double iconSize = constraints.maxHeight < 150 ? 8.0 : 10.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 등산 성장 일지 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                width: 80,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('등산 성장 일지 버튼 클릭');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    textStyle: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('등산 성장 일지'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 성장 정보
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '한라산',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    '(25.04.23)',
                    style: TextStyle(
                      fontSize: fontSize - 1,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: spacing),
                  const Text(
                    '걸린 시간',
                    style: TextStyle(color: Colors.red, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const Text(
                    '2h 26m → 2h 10m',
                    style: TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_upward,
                            color: Colors.green, size: iconSize),
                        const Flexible(
                          child: Text(
                            ' 16분 단축',
                            style: TextStyle(color: Colors.green, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing),
                  const Text(
                    '총 등반 거리',
                    style: TextStyle(color: Colors.blue, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const Text(
                    '8.3km',
                    style: TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
