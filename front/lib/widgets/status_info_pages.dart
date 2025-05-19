// first_status_info.dart 수정
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../models/app_state.dart';
import '../../models/weather_data.dart';
import '../../services/weather_service.dart';

/// 첫 번째 페이지: 등산지수 조회 (수정된 코드)
class FirstStatusInfo extends StatefulWidget {
  const FirstStatusInfo({super.key});
  @override
  State<FirstStatusInfo> createState() => _FirstStatusInfoState();
}

class _FirstStatusInfoState extends State<FirstStatusInfo> {
  late Future<List<WeatherData>> _weatherDataFuture;
  int _selectedIndex = 0; // 선택된 날씨 데이터 인덱스

  @override
  void initState() {
    super.initState();
    _weatherDataFuture = _loadWeatherData();
    WeatherService.checkCachedData();
  }

  // 날씨 데이터 로드 및 AppState 업데이트
  Future<List<WeatherData>> _loadWeatherData() async {
    final token = Provider.of<AppState>(context, listen: false).accessToken;
    final weatherDataList = await WeatherService.fetchWeatherData(token);
    
    if (weatherDataList.isNotEmpty) {
      // AppState에 등산지수 업데이트
      final appState = Provider.of<AppState>(context, listen: false);
      appState.updateClimbingIndex(weatherDataList[0].score.round());
    }
    
    return weatherDataList;
  }

  // 데이터 새로고침
  Future<void> _refreshData() async {
    setState(() {
      _selectedIndex = 0;
      _weatherDataFuture = _loadWeatherData();
    });
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
                  size: 22,
                ),
                const SizedBox(height: 5),
                Text(
                  '등산 지수를 불러오지 못했습니다',
                  style: TextStyle(
                    color: Colors.red[400], 
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _refreshData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B792),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('새로고침'),
                ),
              ],
            ),
          );
        }

        final weatherDataList = snap.data!;
        final selectedData = weatherDataList[_selectedIndex];
        final score = selectedData.score.round();
        final normalizedScore = score / 100.0;
        
        final Color scoreColor = score < 50
            ? const Color(0xFFE53935)
            : score < 80
                ? const Color(0xFFFF8F00)
                : const Color(0xFF52A486);

        return Column(
          children: [
            // 시간 탭 선택 부분
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weatherDataList.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedIndex;
                  final formattedTime = weatherDataList[index].getFormattedTime();
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      
                      // AppState에 선택된 등산지수 업데이트
                      final appState = Provider.of<AppState>(context, listen: false);
                      appState.updateClimbingIndex(weatherDataList[index].score.round());
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? const Color(0xFF64B792)
                          : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected 
                            ? FontWeight.bold
                            : FontWeight.normal,
                          color: isSelected
                            ? Colors.white
                            : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 등산지수 표시 부분
            Center(
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
            ),
            
            // 날씨 세부정보 표시 (선택 사항)
            const SizedBox(height: 15),
            _buildWeatherDetails(selectedData),
          ],
        );
      },
    );
  }
  
  // 날씨 세부정보 표시 위젯
  Widget _buildWeatherDetails(WeatherData data) {
    // 주요 날씨 정보 선택 (4개만 표시)
    final keysToShow = ['체감온도', '풍속', '습도', '미세먼지'];
    final Map<String, String> filteredDetails = {};
    
    for (final key in keysToShow) {
      if (data.details.containsKey(key)) {
        filteredDetails[key] = data.details[key]!;
      }
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: filteredDetails.entries.map((entry) {
          final IconData icon = _getIconForWeatherDetail(entry.key);
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: const Color(0xFF64B792),
              ),
              const SizedBox(height: 4),
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDetailValue(entry.value),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
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
        return Icons.air_outlined;
      case '초미세먼지':
        return Icons.air_outlined;
      default:
        return Icons.info_outline;
    }
  }
  
  // 세부정보 값 포맷팅
  String _formatDetailValue(String value) {
    // 괄호 안의 텍스트 제거 (예: "18.9℃ (보통)" -> "18.9℃")
    final regex = RegExp(r'\s*\([^)]*\)');
    return value.replaceAll(regex, '');
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