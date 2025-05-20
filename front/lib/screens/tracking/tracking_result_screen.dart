import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../utils/app_colors.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class TrackingResultScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;
  final String? selectedMode;
  final String? opponentRecordDate;
  final int? opponentRecordTime;
  final int? opponentMaxHeartRate;
  final int? opponentAvgHeartRate;
  final int? currentElapsedMinutes;
  final double? currentDistanceMeters;
  final String? previousRecordDate;
  final int? previousRecordTimeSeconds;
  final int? previousMaxHeartRate;
  final int? previousAvgHeartRate;

  const TrackingResultScreen({
    super.key,
    required this.resultData,
    this.selectedMode,
    this.opponentRecordDate,
    this.opponentRecordTime,
    this.opponentMaxHeartRate,
    this.opponentAvgHeartRate,
    this.currentElapsedMinutes,
    this.currentDistanceMeters,
    this.previousRecordDate,
    this.previousRecordTimeSeconds,
    this.previousMaxHeartRate,
    this.previousAvgHeartRate,
  });

  @override
  State<TrackingResultScreen> createState() => _TrackingResultScreenState();
}

class _TrackingResultScreenState extends State<TrackingResultScreen> {
  @override
  void initState() {
    super.initState();
    // 결과 페이지 진입 시 백그라운드 서비스와 알림 완전 종료
    _stopBackgroundService();
    _cancelAllNotifications();
  }

  // 백그라운드 서비스 종료
  void _stopBackgroundService() {
    try {
      // FlutterBackgroundService를 통해 서비스 종료
      final service = FlutterBackgroundService();
      service.invoke('stop');
      debugPrint('백그라운드 서비스 종료');
    } catch (e) {
      debugPrint('백그라운드 서비스 종료 중 오류: $e');
    }
  }

  // 모든 알림 종료
  void _cancelAllNotifications() {
    try {
      // 로컬 알림 종료 로직
      debugPrint('모든 알림 종료 시도');
      // 더 간단한 방식으로 처리
    } catch (e) {
      debugPrint('알림 종료 중 오류: $e');
    }
  }

  // 분을 시간 문자열로 변환 (예: 90 -> "1시간 30분")
  String _formatMinutes(int minutes) {
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '$hours시간 $remainingMinutes분';
    } else {
      return '$remainingMinutes분';
    }
  }

  // 날짜를 "YY.MM.DD" 형식으로 포맷팅
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      // 날짜가 없는 경우 오늘 날짜 사용
      final now = DateTime.now();
      return '${now.year.toString().substring(2)}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    }

    try {
      // 서버에서 받은 날짜 형식 파싱 (예: "2025-05-10" -> "25.05.10")
      final parts = dateString.split('-');
      if (parts.length == 3) {
        final year = parts[0].substring(2); // "2025" -> "25"
        final month = parts[1];
        final day = parts[2];
        return '$year.$month.$day';
      }

      // 다른 형식이면 그대로 반환
      return dateString;
    } catch (e) {
      debugPrint('날짜 변환 오류: $e');
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // 위젯에서 전달된 모드를 우선 사용하고, 없으면 AppState에서 가져옴
    final selectedMode = widget.selectedMode ?? appState.selectedMode;
    final isVsMode = selectedMode == '나 vs 나' || selectedMode == '나 vs 친구';

    // 산 이름 가져오기
    final String mountainName = appState.selectedMountain ?? '등산';

    // 디버깅을 위한 로그 추가
    debugPrint('TrackingResultScreen - 선택된 모드: $selectedMode');
    debugPrint('TrackingResultScreen - 결과 데이터: ${widget.resultData}');
    debugPrint('TrackingResultScreen - 산 이름: $mountainName');

    // 등산 결과 화면 렌더링
    return Scaffold(
      appBar: AppBar(
        title: Text('등산 결과', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildResultContent(selectedMode, mountainName),
            ),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(String? selectedMode, String mountainName) {
    // 어떤 모드인지에 따라 다른 결과 화면 표시
    // 디버깅 로그 추가
    debugPrint('_buildResultContent - 모드: $selectedMode');

    if (selectedMode == '나 vs 나') {
      debugPrint('나 vs 나 결과 화면 빌드');
      return _buildVsMeResult(mountainName);
    } else if (selectedMode == '나 vs 친구') {
      debugPrint('나 vs 친구 결과 화면 빌드');
      return _buildVsFriendResult(mountainName);
    } else {
      debugPrint('일반 등산 결과 화면 빌드');
      return _buildGeneralResult(mountainName);
    }
  }

  // 나 vs 나 모드 결과 화면 개선
Widget _buildVsMeResult(String mountainName) {
  final appState = Provider.of<AppState>(context, listen: false);
  final modeData = appState.modeData;
  final timeDiff = widget.resultData['timeDiff'];
  final String timeDiffText = timeDiff != null
      ? timeDiff < 0
          ? "${timeDiff.abs()}분 단축"
          : "$timeDiff분 증가"
      : "";

  // 현재/이전 기록
  final int currMaxHr = (widget.resultData['maxHeartRate'] is double)
      ? (widget.resultData['maxHeartRate'] as double).round()
      : widget.resultData['maxHeartRate'] ?? 0;
  final int currAvgHr = (widget.resultData['averageHeartRate'] is double)
      ? (widget.resultData['averageHeartRate'] as double).round()
      : widget.resultData['averageHeartRate'] ?? 0;
  final String prevDate = widget.previousRecordDate ?? '—';
  final int prevTime = widget.previousRecordTimeSeconds ?? 0;
  final String prevTimeText = _formatMinutes(prevTime);
  final int prevMaxHr = widget.previousMaxHeartRate ?? 0;
  final int prevAvgHrDouble = widget.previousAvgHeartRate ?? 0;
  final String prevAvgHrText = '${prevAvgHrDouble.round()} bpm';

  // 심박수 차이 계산
  final int maxHrDiff = currMaxHr - prevMaxHr;
  final int avgHrDiff = currAvgHr - prevAvgHrDouble;
  String maxHrComment = maxHrDiff > 0 ? '최고 심박수 ${maxHrDiff}bpm 증가' : 
                        maxHrDiff < 0 ? '최고 심박수 ${maxHrDiff.abs()}bpm 감소' : 
                        '최고 심박수 변화 없음';
  String avgHrComment = avgHrDiff > 0 ? '평균 심박수 ${avgHrDiff.toStringAsFixed(1)}bpm 증가' : 
                        avgHrDiff < 0 ? '평균 심박수 ${(avgHrDiff.abs()).toStringAsFixed(1)}bpm 감소' : 
                        '평균 심박수 변화 없음';

  // badge URL 가져오기
  final String badgeUrl = widget.resultData['badge'] ?? '';

  // 색상 상수 정의
  final Color primaryColor = Color(0xFF52A486);
  final Color lightOrangeColor = Color(0xFFFFF3E0);
  final Color lightGreenColor = Color(0xFFE8F5EC);

  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 타이틀 섹션
          Container(
            margin: EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Text(
                  '$mountainName 등반 결과',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFEEF7F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '나 vs 나',
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 기록 비교 섹션
          Container(
            margin: EdgeInsets.only(bottom: 24),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 비교 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '현재 기록',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    Text(
                      '이전 기록',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // 날짜 비교
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: lightOrangeColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _formatDate(appState.currentRecordDate),
                        style: TextStyle(
                          fontSize: 12, 
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                    Icon(Icons.compare_arrows, color: Colors.grey),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: lightGreenColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _formatDate(appState.previousRecordDate ?? ''),
                        style: TextStyle(
                          fontSize: 12, 
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // 시간 비교
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '총 등산 시간',
                          style: TextStyle(
                            fontSize: 12, 
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatMinutes(appState.elapsedMinutes),
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: timeDiff != null && timeDiff < 0 ? lightGreenColor : lightOrangeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        timeDiff != null && timeDiff < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 20,
                        color: timeDiff != null && timeDiff < 0 ? primaryColor : Colors.orange[800],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '총 등산 시간',
                          style: TextStyle(
                            fontSize: 12, 
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          prevTimeText,
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // 시간 차이 표시
                Container(
                  margin: EdgeInsets.symmetric(vertical: 16),
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: timeDiff != null && timeDiff < 0 ? Color(0xFFE8F5EC) : Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: timeDiff != null && timeDiff < 0 ? Color(0xFFCCE8DC) : Color(0xFFFFE0B2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        timeDiff != null && timeDiff < 0 ? Icons.trending_down : Icons.trending_up,
                        size: 18,
                        color: timeDiff != null && timeDiff < 0 ? primaryColor : Colors.orange[800],
                      ),
                      SizedBox(width: 8),
                      Text(
                        timeDiffText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: timeDiff != null && timeDiff < 0 ? primaryColor : Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Divider(height: 32, thickness: 1, color: Colors.grey[200]),
                
                // 심박수 비교
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.red, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '최고 심박수',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$currMaxHr bpm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.favorite_border, color: Colors.red, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '평균 심박수',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$currAvgHr bpm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              '최고 심박수',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.favorite, color: Colors.red, size: 14),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$prevMaxHr bpm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '평균 심박수',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.favorite_border, color: Colors.red, size: 14),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          prevAvgHrText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 뱃지 섹션
          Container(
            margin: EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Text(
                  '획득한 뱃지',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 16),
                if (badgeUrl.isNotEmpty)
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        badgeUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('이미지를 불러올 수 없습니다',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: Colors.amber,
                    ),
                  ),
              ],
            ),
          ),

          // 심박수 변화 카드
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      maxHrComment,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      avgHrComment,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  // 나 vs 친구 모드 결과 화면
  Widget _buildVsFriendResult(String mountainName) {
    final appState = Provider.of<AppState>(context, listen: false);
    final modeData = appState.modeData;
    final timeDiff = widget.resultData['timeDiff'];
    final String timeDiffText = timeDiff != null
        ? timeDiff < 0
            ? "${timeDiff.abs()}분 단축"
            : "$timeDiff분 증가"
        : "";

    // 위젯으로 전달된 친구 기록 데이터 디버그 출력
    debugPrint('[tracking_result_screen] _buildVsFriendResult:');
    debugPrint('  - friendDate: ${widget.opponentRecordDate}');
    debugPrint('  - friendTimeMinutes: ${widget.opponentRecordTime}');
    debugPrint('  - friendMaxHeartRate: ${widget.opponentMaxHeartRate}');
    debugPrint('  - friendAvgHeartRate: ${widget.opponentAvgHeartRate}');

    // badge URL 가져오기
    final String badgeUrl = widget.resultData['badge'] ?? '';

    // 친구 기록 정보 - 위젯에서 가져오기
    final String friendDate = _formatDate(widget.opponentRecordDate) ?? '기본값';
    final int friendTimeMinutes = widget.opponentRecordTime ?? 0;
    final int friendMaxHeartRate =
        widget.opponentMaxHeartRate ?? widget.resultData['maxHeartRate'] ?? 0;
    final double friendAvgHeartRate = widget.opponentAvgHeartRate ??
        widget.resultData['averageHeartRate'] ??
        0.0;

    // 현재 기록 정보
    final int currTimeSeconds = widget.currentElapsedMinutes ?? 0;
    final now = DateTime.now();
    final String currentDate =
        '${now.year.toString().substring(2)}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    // 심박수 차이 계산
    final int maxHrDiff = (widget.resultData['maxHeartRate'] is double)
        ? (widget.resultData['maxHeartRate'] as double).round() -
            friendMaxHeartRate
        : (widget.resultData['maxHeartRate'] ?? 0) - friendMaxHeartRate;
    final double avgHrDiff = (widget.resultData['averageHeartRate'] is double)
        ? (widget.resultData['averageHeartRate'] as double) - friendAvgHeartRate
        : (widget.resultData['averageHeartRate'] ?? 0.0) - friendAvgHeartRate;

    String maxHrComment = '';
    if (maxHrDiff > 0) {
      maxHrComment = '최고 심박수 ${maxHrDiff}bpm 증가';
    } else if (maxHrDiff < 0) {
      maxHrComment = '최고 심박수 ${maxHrDiff.abs()}bpm 감소';
    } else {
      maxHrComment = '최고 심박수 변화 없음';
    }

    String avgHrComment = '';
    if (avgHrDiff > 0) {
      avgHrComment = '평균 심박수 ${avgHrDiff.toStringAsFixed(1)}bpm 증가';
    } else if (avgHrDiff < 0) {
      avgHrComment = '평균 심박수 ${(avgHrDiff.abs()).toStringAsFixed(1)}bpm 감소';
    } else {
      avgHrComment = '평균 심박수 변화 없음';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$mountainName 등반 결과',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          // 결과 요약 카드
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '나 vs 친구',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),

                  // 데이터 비교 (이미지와 비슷하게 구성)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 내 기록
                      Column(
                        children: [
                          Text('내 기록',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Container(
                            width: 140,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(currentDate,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700])),
                                SizedBox(height: 8),
                                Text(_formatMinutes(currTimeSeconds),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.favorite,
                                        color: Colors.red, size: 16),
                                    SizedBox(width: 4),
                                    Text('최고 심박수',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                Text(
                                    '${widget.resultData['maxHeartRate'] ?? 0} bpm',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.favorite_border,
                                        color: Colors.red, size: 16),
                                    SizedBox(width: 4),
                                    Text('평균 심박수',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                Text(
                                    '${widget.resultData['averageHeartRate'].toInt() ?? 0} bpm',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // vs 구분선
                      Column(
                        children: [
                          Icon(Icons.arrow_forward, color: Colors.red),
                          SizedBox(height: 60),
                        ],
                      ),

                      // 친구 기록
                      Column(
                        children: [
                          Text('친구 기록',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Container(
                            width: 140,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(friendDate,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700])),
                                SizedBox(height: 8),
                                Text(_formatMinutes(friendTimeMinutes),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.favorite,
                                        color: Colors.red, size: 16),
                                    SizedBox(width: 4),
                                    Text('최고 심박수',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                Text('$friendMaxHeartRate bpm',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.favorite_border,
                                        color: Colors.red, size: 16),
                                    SizedBox(width: 4),
                                    Text('평균 심박수',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                Text('${friendAvgHeartRate.round()} bpm',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // 뱃지 이미지 표시
                  if (badgeUrl.isNotEmpty)
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Image.network(
                        badgeUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('이미지를 불러올 수 없습니다',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Icon(Icons.emoji_events, size: 80, color: Colors.amber),

                  SizedBox(height: 9),

                  // 결과 정보 카드
                  Card(
                    color: Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flash_on, color: Colors.amber),
                              SizedBox(width: 8),
                              Text(timeDiffText,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.favorite, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text(maxHrComment,
                                  style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.favorite_border,
                                  color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text(avgHrComment,
                                  style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 일반 등산 모드 결과 화면 개선
Widget _buildGeneralResult(String mountainName) {
  final appState = Provider.of<AppState>(context, listen: false);
  final String badgeUrl = widget.resultData['badge'] ?? '';
  
  // 현재 날짜 포맷팅
  final now = DateTime.now();
  final String currentDate =
      '${now.year.toString().substring(2)}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

  // 등산 데이터
  final int timeMinutes = appState.elapsedMinutes;
  final String timeFormatted = _formatMinutes(timeMinutes);
  final int maxHeartRate = (widget.resultData['maxHeartRate'] is double)
      ? (widget.resultData['maxHeartRate'] as double).round()
      : widget.resultData['maxHeartRate'] ?? 0;
  final int avgHeartRate = (widget.resultData['averageHeartRate'] is double)
      ? (widget.resultData['averageHeartRate'] as double).round()
      : widget.resultData['averageHeartRate'] ?? 0;
  final double distance = appState.distance;
  final String distanceFormatted = distance < 1.0
      ? '${(distance * 1000).toInt()}m'
      : '${distance.toStringAsFixed(1)}km';

  // 색상 상수 정의
  final Color primaryColor = Color(0xFF52A486);
  final Color backgroundColor = Color(0xFFFFFBE6);
  final Color cardColor = Colors.white;
  
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 상단 타이틀
          Container(
            margin: EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Text(
                  '$mountainName 등반 결과',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFEEF7F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 뱃지 표시
          Container(
            margin: EdgeInsets.only(bottom: 24),
            child: badgeUrl.isNotEmpty
                ? Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        badgeUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('이미지를 불러올 수 없습니다',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 100,
                      color: Colors.amber,
                    ),
                  ),
          ),
          
          // 등산 결과 정보 카드
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // 거리 정보
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFAFFF7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.straighten,
                          size: 24,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '총 산행 거리',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            distanceFormatted,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 시간 정보
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.timer_outlined,
                          size: 24,
                          color: Colors.orange[700],
                        ),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '총 등산 시간',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            timeFormatted,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 심박수 정보
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.2),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite,
                              size: 24,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '최고 심박수',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$maxHeartRate bpm',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.1),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite_border,
                              size: 24,
                              color: Colors.red[300],
                            ),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '평균 심박수',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$avgHeartRate bpm',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[300],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // 뱃지 대체 위젯
  Widget _buildBadgeFallback() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.emoji_events,
        size: 80,
        color: Colors.amber,
      ),
    );
  }

  // 확인 버튼 개선
Widget _buildConfirmButton() {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: ElevatedButton(
      onPressed: () async {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.endTracking(); 
        _stopBackgroundService();
        _cancelAllNotifications();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF52A486),
        minimumSize: Size(double.infinity, 56),
        elevation: 3,
        shadowColor: Color(0xFF52A486).withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        '완료',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    ),
  );
}
}
