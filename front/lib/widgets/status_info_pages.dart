// status_info_pages.dart - 스타일 통일 및 아이콘 변경
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/app_state.dart';

/// 첫 번째 페이지: 등산지수 조회 (기존 코드 유지)
class FirstStatusInfo extends StatefulWidget {
  const FirstStatusInfo({super.key});
  @override
  State<FirstStatusInfo> createState() => _FirstStatusInfoState();
}

class _FirstStatusInfoState extends State<FirstStatusInfo> {
  // 기존 코드는 그대로 유지...
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
      debugPrint('등산지수 조회 : $data');
      if (raw is num) {
        final score = raw.toInt();
        
        // AppState에 등산지수 업데이트
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
        final normalizedScore = score / 100.0;
        
        final Color scoreColor = score < 50
            ? const Color(0xFFE53935)
            : score < 80
                ? const Color(0xFFFF8F00)
                : const Color(0xFF52A486);

        return Center(
          child: SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                
                SizedBox(
                  width: 110,
                  height: 110,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: normalizedScore),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8.5,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                ),
                
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '등산지수',
                      style: TextStyle(
                        fontSize: 11,
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

/// 두 번째 페이지: 등산 기록 (스타일 통일 및 아이콘 변경)
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red[400],
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  '성장 정보를 불러올 수 없습니다',
                  style: TextStyle(
                    color: Colors.red[400], 
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final growth = snap.data;
        
        // 케이스 3: 등산 기록이 없는 경우 (growth가 null)
        if (growth == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF52A486).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.landscape_outlined,
                    size: 36,
                    color: Color(0xFF52A486),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '등산 기록이 없어요',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // 등산 기록이 있는 경우 (케이스 1, 2)
        return _buildClimbingRecord(growth);
      },
    );
  }

  // 등산 기록이 있는 경우의 UI (케이스 1, 2) - 스타일 통일 및 아이콘 변경
  Widget _buildClimbingRecord(Map<String, dynamic> growth) {
    final hasPast = growth['pastTime'] != null;
    final name = growth['mountainName'] as String;
    final date = growth['date'] as String;
    final recent = growth['recentTime'] as int;
    final past = hasPast ? growth['pastTime'] as int : 0;
    
    // 시간 차이 계산 (hasPast인 경우만)
    final bool hasTimeDiff = hasPast && (recent != past);
    final int timeDiff = hasTimeDiff ? (past - recent).abs() : 0;
    final bool isImproved = hasTimeDiff && (recent < past);
    
    // 날짜와 시간 텍스트 스타일 
    final textStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey[800],
    );
    
    return SizedBox(
      height: 150,
      child: Center(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 산 이름
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.terrain,
                      size: 16,
                      color: Color(0xFF52A486),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF52A486),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // 날짜 
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined, 
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: textStyle, // 공통 스타일 적용
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // 시간 정보 
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_outlined, 
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    
                    // 케이스에 따른 시간 표시 
                    if (hasPast) ...[
                      // pastTime이 있는 경우
                      Text(
                        '$past분',
                        style: textStyle, 
                      ),
                      const SizedBox(width: 4),
                      
                      // 화살표
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.grey[400], 
                      ),
                      const SizedBox(width: 4),
                      
                      // 현재 시간
                      Text(
                        '$recent분',
                        style: textStyle, 
                      ),
                    ] else ...[
                      // pastTime이 null인 경우 (현재 시간만 표시)
                      Text(
                        '$recent분',
                        style: textStyle, 
                      ),
                    ],
                  ],
                ),

                // 첫 등산 메시지 또는 시간 차이 표시 
                if (hasPast && hasTimeDiff) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 22),
                      ConstrainedBox( // 여기에 ConstrainedBox 추가
                        constraints: BoxConstraints(maxWidth: 150), // 최대 너비 제한
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isImproved 
                                ? const Color(0xFFE8F5E9) 
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isImproved ? '${timeDiff}분 단축되었어요!' : '${timeDiff}분 증가했어요!',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isImproved 
                                  ? const Color(0xFF4CAF50) 
                                  : const Color(0xFFE57373),
                            ),
                            overflow: TextOverflow.visible, // overflow 처리 방식 지정
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (!hasPast) ...[
                  // pastTime이 null인 경우 첫 등산 메시지
                  const SizedBox(height: 4), // 6에서 4로 줄임
                  Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: ConstrainedBox( // 여기에 ConstrainedBox 추가
                      constraints: BoxConstraints(maxWidth: 150), // 최대 너비 제한
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '이 코스는 처음이네요!',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4CAF50),
                          ),
                          overflow: TextOverflow.visible, // overflow 처리 방식 지정
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}