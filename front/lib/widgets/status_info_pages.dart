// status_info_pages.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP 요청
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // .env 읽기용
import '../../models/app_state.dart';

/// 첫 번째 페이지: 등산지수 조회
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
    final baseUrl = dotenv.env['AI_BASE_URL']!;
    final url = Uri.parse('$baseUrl/weather');
    final token = Provider.of<AppState>(context, listen: false).accessToken;

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final raw = data['score'];
      if (raw is num) return raw.toInt();
      throw Exception('score 필드가 숫자가 아닙니다.');
    }
    throw Exception('등산지수 조회 실패 (HTTP ${resp.statusCode})');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _climbingIndexFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              '정보를 불러오지 못했습니다',
              style: TextStyle(color: Colors.red[400], fontSize: 16),
            ),
          );
        }

        final score = snap.data!;
        // 색상·메시지
        final scoreColor = score < 50
            ? Colors.red
            : score < 80
                ? Colors.orange
                : Colors.green;
        final message = score < 50
            ? '등산하기에 좋지 않습니다'
            : score < 80
                ? '적당한 등산 환경입니다'
                : '등산하기 좋은 날씨입니다';

        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '등산지수',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: scoreColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 두 번째 페이지: 최근 등산 성장 일지
class SecondStatusInfo extends StatefulWidget {
  const SecondStatusInfo({super.key});
  @override
  State<SecondStatusInfo> createState() => _SecondStatusInfoState();
}

class _SecondStatusInfoState extends State<SecondStatusInfo> {
  late Future<Map<String, dynamic>?> _growthFuture;

  @override
  void initState() {
    super.initState();
    _growthFuture = fetchGrowth();
  }

  Future<Map<String, dynamic>?> fetchGrowth() async {
    final baseUrl = dotenv.env['BASE_URL']!;
    final url = Uri.parse('$baseUrl/footprint/main');
    final token = Provider.of<AppState>(context, listen: false).accessToken;

    final resp = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(utf8.decode(resp.bodyBytes));
      return body['status'] == true
          ? body['data']['growth'] as Map<String, dynamic>?
          : throw Exception(body['message']);
    }
    throw Exception('성장 정보 조회 실패 (HTTP ${resp.statusCode})');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _growthFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              '성장 정보를 불러올 수 없습니다',
              style: TextStyle(color: Colors.red[400], fontSize: 16),
            ),
          );
        }

        final growth = snap.data;

        // 항상 스크롤 처리
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          child: growth == null
              ? Center(
                  child: Text(
                    '기록된 등산 정보가 \n없습니다.\n등산을 하고 내 등산을\n기록 해보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                )
              : _buildGrowthContent(growth),
        );
      },
    );
  }

  Widget _buildGrowthContent(Map<String, dynamic> growth) {
    final hasPast = growth['pastTime'] != null;
    final name = growth['mountainName'] as String;
    final date = growth['date'] as String;
    final recent = growth['recentTime'] as int;

    // pastTime이 null일 땐 recentTime만
    if (!hasPast) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () => debugPrint('최근 등산'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29B6F6),
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: const Text('최근 등산',
                  style: TextStyle(fontSize: 14, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          Text(name,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800)),
          const SizedBox(height: 4),
          Text('($date)',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          const Text('걸린 시간',
              style: TextStyle(fontSize: 14, color: Color(0xFFEF5350))),
          const SizedBox(height: 4),
          Text('$recent분',
              style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      );
    }

    // pastTime도 있는 일반 케이스
    final past = growth['pastTime'] as int;
    final diff = (past - recent).abs();
    final improved = recent < past;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ElevatedButton(
            onPressed: () => debugPrint('최근 등산'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF29B6F6),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('최근 등산',
                style: TextStyle(fontSize: 14, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 8),
        Text(name,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800)),
        const SizedBox(height: 4),
        Text('($date)',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        const Text('걸린 시간',
            style: TextStyle(fontSize: 14, color: Color(0xFFEF5350))),
        const SizedBox(height: 4),
        Text('$past → $recent',
            style: const TextStyle(fontSize: 16, color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(improved ? Icons.arrow_upward : Icons.arrow_downward,
                color: improved
                    ? const Color(0xFF66BB6A)
                    : const Color(0xFFF44336),
                size: 16),
            const SizedBox(width: 6),
            Text('$diff분 ${improved ? '단축' : '지연'}',
                style: TextStyle(
                    fontSize: 14,
                    color: improved
                        ? const Color(0xFF66BB6A)
                        : const Color(0xFFF44336))),
          ],
        ),
        const SizedBox(height: 8),
        const Text('총 등반 거리',
            style: TextStyle(fontSize: 14, color: Color(0xFF26A69A))),
        const SizedBox(height: 4),
        Text('${growth['distance'] ?? '8.3'}km',
            style: const TextStyle(fontSize: 16, color: Colors.black87)),
      ],
    );
  }
}
