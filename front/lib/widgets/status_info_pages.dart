// first_status_info.dart 수정

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/weather_data.dart';
import '../../services/weather_service.dart';

/// 첫 번째 페이지: 등산지수 조회 (utf8 디코딩 적용 및 시간 형식 수정)
class FirstStatusInfo extends StatefulWidget {
  const FirstStatusInfo({super.key});
  @override
  State<FirstStatusInfo> createState() => _FirstStatusInfoState();
}

class _FirstStatusInfoState extends State<FirstStatusInfo> {
  late Future<List<WeatherData>> _weatherDataFuture;

  @override
  void initState() {
    super.initState();
    _weatherDataFuture = _loadWeatherData();
  }

  // 날씨 데이터 로드
  Future<List<WeatherData>> _loadWeatherData() async {
    final token = Provider.of<AppState>(context, listen: false).accessToken;
    //WeatherService.clearCache(); // 테스트 시 캐시 강제 삭제 
    return await WeatherService.fetchWeatherData(token);
  }

  // 데이터 새로고침
  Future<void> _refreshData() async {
    setState(() {
      _weatherDataFuture = _loadWeatherData();
    });
  }

  // 모달창으로 날씨 정보 표시
  void _showWeatherModal(BuildContext context, WeatherData data) {
    final score = data.score.round();
    final scoreColor = score < 50
        ? const Color(0xFFE53935)
        : score < 80
            ? const Color(0xFFFF9800)
            : const Color(0xFF52A486);
            
    // AppState에 선택된 등산지수 업데이트
    final appState = Provider.of<AppState>(context, listen: false);
    appState.updateClimbingIndex(score);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 모달 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${data.getFormattedTime()} 등산지수',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const Divider(),
              const SizedBox(height: 12),
              
              // 등산지수 표시
              Row(
                children: [
                  // 원형 프로그레스
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: score / 100.0,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                          strokeCap: StrokeCap.round,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            Text(
                              '등산지수',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // 날씨 상태 설명
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getScoreMessage(score),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 날씨 세부정보 제목
              Text(
                '날씨 상세정보',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 날씨 세부정보 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: data.details.length,
                itemBuilder: (context, index) {
                  final entry = data.details.entries.elementAt(index);
                  final key = entry.key;
                  final value = entry.value;
                  final formattedValue = _formatDetailValue(value);
                  final category = _getDetailCategory(value);
                  
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF64B792).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _getIconForWeatherDetail(key),
                            size: 14,
                            color: const Color(0xFF64B792),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                key,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 4,
                                children: [
                                  Text(
                                    formattedValue,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (category.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(category).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: _getCategoryColor(category),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // 하단 버튼
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B792),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ),
              
              // 키보드나 기타 UI 요소와 겹치지 않도록 여백 추가
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WeatherData>>(
      future: _weatherDataFuture,
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
        
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red[400],
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  '날씨 정보를 불러오지 못했습니다',
                  style: TextStyle(
                    color: Colors.red[400], 
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refreshData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B792),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 24),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('새로고침', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          );
        }

        final weatherDataList = snap.data!;
        
        // 시간 목록과 제목 표시 (오버플로우 해결)
        return Container(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8), // 위쪽 패딩 추가
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 귀여운 제목
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEFE2), // 연한 민트색으로 변경
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF64B792).withOpacity(0.15),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: const Color(0xFF52A486),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '등산지수 시간표',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF52A486),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 시간 버튼 그리드 (등산지수 제외)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,  // 한 줄에 4개씩
                  childAspectRatio: 2.2,  // 가로:세로 비율 좀 더 넓게
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: weatherDataList.length,
                itemBuilder: (context, index) {
                  final data = weatherDataList[index];
                  final formattedTime = data.getFormattedTime();
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showWeatherModal(context, data),
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              const Color(0xFFE8F5EC), // 연한 민트 그린
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF52A486), // 모든 시간 텍스트 색상 통일
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 점수에 따른 메시지 반환
  String _getScoreMessage(int score) {
    if (score < 50) return '최악의 등산 날씨에요';
    if (score < 80) return '무난한 등산 날씨에요';
    return '최고의 등산 날씨에요';
  }
  
  // 세부정보 값 포맷팅 (괄호 내용 제거)
  String _formatDetailValue(String value) {
    final regex = RegExp(r'(.*?)\s*\([^)]*\)');
    final match = regex.firstMatch(value);
    return match != null ? match.group(1)! : value;
  }
  
  // 세부정보 카테고리 추출 (괄호 안의 내용)
  String _getDetailCategory(String value) {
    final regex = RegExp(r'\(([^)]*)\)');
    final match = regex.firstMatch(value);
    return match != null ? match.group(1)! : '';
  }
  
  // 날씨 세부정보 항목에 맞는 아이콘 반환
  IconData _getIconForWeatherDetail(String key) {
    switch (key) {
      case '체감온도':
        return Icons.thermostat_outlined;
      case '풍속':
        return Icons.air_outlined;
      case '습도':
        return Icons.water_drop_outlined;
      case '구름':
        return Icons.cloud_outlined;
      case '미세먼지':
        return Icons.air;
      case '초미세먼지':
        return Icons.air;
      default:
        return Icons.info_outline;
    }
  }
  
  // 카테고리에 따른 색상 반환
  Color _getCategoryColor(String category) {
    switch (category.trim()) {
      case '좋음':
        return Colors.green;
      case '보통':
        return Colors.blue;
      case '나쁨':
        return Colors.orange;
      case '매우나쁨':
        return Colors.red;
      case '많음':
        return Colors.blueGrey;
      case '적음':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
                  padding: const EdgeInsets.all(12),
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
                    fontSize: 14,
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
      height: 130,
      child: Center(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isImproved 
                              ? const Color(0xFFE8F5E9) // 연한 초록 배경
                              : const Color(0xFFFFEBEE), // 연한 빨강 배경
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
                        ),
                      ),
                    ],
                  ),
                ] else if (!hasPast) ...[
                  // pastTime이 null인 경우 첫 등산 메시지
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 22), 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9), // 연한 초록 배경
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '이 코스는 첫 등산이네요!',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
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
