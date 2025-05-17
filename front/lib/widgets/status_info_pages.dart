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

  // status_info_pages.dart의 _FirstStatusInfoState 클래스 내 fetchClimbingIndex 메서드 수정
Future<int> fetchClimbingIndex() async {
  final baseUrl = dotenv.env['AI_BASE_URL']!;
  final url = Uri.parse('$baseUrl/weather');
  final token = Provider.of<AppState>(context, listen: false).accessToken;
  final appState = Provider.of<AppState>(context, listen: false);

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
    if (raw is num) {
      final score = raw.toInt();
      
      // AppState에 등산지수 업데이트 - 여기가 중요한 부분입니다!
      appState.updateClimbingIndex(score);
      
      return score;
    }
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
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B792)),
            ),
          ),
        );
      }
      
      if (snap.hasError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red[400],
                size: 22,
              ),
              const SizedBox(height: 5),
              Text(
                '정보를 불러오지 못했습니다',
                style: TextStyle(
                  color: Colors.red[400], 
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      final score = snap.data!;
      final normalizedScore = score / 100.0; // 프로그레스바용 0.0-1.0 값
      
      // 색상 선택 - 디자인 개선: 색상 조화롭게 변경
      final Color scoreColor = score < 50
          ? const Color(0xFFE53935)  // 진한 빨강
          : score < 80
              ? const Color(0xFFFF8F00)  // 진한 주황
              : const Color(0xFF43A047);  // 진한 초록

      return Center(
        child: SizedBox(
          width: 110, // 약간 키워서 여유공간 확보
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 원형 배경 (흰색) - 디자인 개선: 그림자 효과 강화
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              
              // 프로그레스 바 - 디자인 개선: 두께와 효과 개선
              SizedBox(
                width: 110,
                height: 110,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: normalizedScore),
                  duration: const Duration(milliseconds: 1500), // 애니메이션 시간 증가
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8.5, // 약간 두껍게
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
              
              // 중앙 숫자와 텍스트 - 디자인 개선: 폰트 크기와 무게 조정
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 28, // 크기 증가
                      fontWeight: FontWeight.w800, // 더 굵게
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    '등산지수',
                    style: TextStyle(
                      fontSize: 11, // 약간 키움
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B792)),
              ),
            ),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red[400],
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  '성장 정보를 불러올 수 없습니다',
                  style: TextStyle(
                    color: Colors.red[400], 
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final growth = snap.data;

        // 항상 스크롤 처리
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // 패딩 개선
          physics: const BouncingScrollPhysics(), // 스크롤 물리 효과 추가
          child: growth == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      '기록된 등산 정보가 \n없습니다.\n등산을 하고 내 등산을\n기록 해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600], 
                        fontSize: 15,
                        height: 1.5, // 줄 간격 추가
                      ),
                    ),
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
                backgroundColor: const Color(0xFF26A69A), // 색상 변경
                foregroundColor: Colors.white,
                elevation: 2, // 그림자 추가
                shadowColor: const Color(0xFF26A69A).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25), // 더 둥글게
                ),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10), // 패딩 증가
              ),
              child: const Text(
                '최근 등산',
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.white,
                  fontWeight: FontWeight.w600, // 더 굵게
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 산 이름과 날짜 - 디자인 개선: 카드 스타일
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.terrain, // 산 아이콘 추가
                      size: 18,
                      color: Color(0xFF64B792),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    '($date)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 걸린 시간 정보 - 디자인 개선: 카드 스타일
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.timer, // 시간 아이콘 추가
                      size: 16,
                      color: Color(0xFFEF5350),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '걸린 시간',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFEF5350),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    '$recent분',
                    style: const TextStyle(
                      fontSize: 18, // 크기 증가
                      fontWeight: FontWeight.w700, // 더 굵게
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
              backgroundColor: const Color(0xFF26A69A), // 색상 변경
              foregroundColor: Colors.white,
              elevation: 2, // 그림자 추가
              shadowColor: const Color(0xFF26A69A).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25), // 더 둥글게
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10), // 패딩 증가
            ),
            child: const Text(
              '최근 등산',
              style: TextStyle(
                fontSize: 14, 
                color: Colors.white,
                fontWeight: FontWeight.w600, // 더 굵게
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 산 이름과 날짜 - 디자인 개선: 카드 스타일
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.terrain, // 산 아이콘 추가
                    size: 18,
                    color: Color(0xFF64B792),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  '($date)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 걸린 시간 정보 - 디자인 개선: 카드 스타일
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timer, // 시간 아이콘 추가
                    size: 16,
                    color: Color(0xFFEF5350),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '걸린 시간',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFEF5350),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Row(
                  children: [
                    Text(
                      '$past',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const Text(
                      ' → ',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '$recent',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      '분',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // 향상/퇴보 정보 - 디자인 개선: 배경 추가
              Container(
                margin: const EdgeInsets.only(left: 24),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: improved 
                      ? const Color(0xFF66BB6A).withOpacity(0.1)
                      : const Color(0xFFF44336).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      improved ? Icons.arrow_upward : Icons.arrow_downward,
                      color: improved
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFFF44336),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$diff분 ${improved ? '단축' : '지연'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: improved
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFFF44336),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 거리 정보 - 디자인 개선: 카드 스타일
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.straighten, // 거리 아이콘 추가
                    size: 16,
                    color: Color(0xFF26A69A),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '총 등반 거리',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF26A69A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Row(
                  children: [
                    Text(
                      '${growth['distance'] ?? '8.3'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'km',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}