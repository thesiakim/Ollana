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
  final int? currentDistanceMeters;
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
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0, // 스크롤 시 엘리베이션 변화 방지
        title: Text(
          '$mountainName 등산 결과',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
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

  Widget _buildVsMeResult(String mountainName) {
    final appState = Provider.of<AppState>(context, listen: false);
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
    final int prevTime = widget.previousRecordTimeSeconds ?? 0;
    final int prevMaxHr = widget.previousMaxHeartRate ?? 0;
    final int prevAvgHr = widget.previousAvgHeartRate ?? 0;

    // badge URL 가져오기
    final String badgeUrl = widget.resultData['badge'] ?? '';

    // 색상 정의 - 더 세련된 컬러 스킴
    final Color primaryColor = Color(0xFF53A487);
    final Color previousColor = Color(0xFF8E9EAB); // 부드러운 청회색
    final Color currentColor = Color(0xFF3A8A6E); // 진한 녹색
    final Color positiveColor = Color(0xFF53A487); // 긍정적 변화 (녹색)
    final Color negativeColor = Color(0xFFE57373); // 부정적 변화 (빨간색)
    final Color neutralColor = Color(0xFF9E9E9E); // 중립적 색상 (회색)
    final Color cardColor = Colors.white;
    final Color bgColor = Color(0xFFF8F9FA);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 섹션 - 더 세련된 디자인 (아이콘과 박스 크기 축소)
            Container(
              margin: EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8), // 패딩 축소
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10), // 모서리 반경 축소
                    ),
                    child: Icon(
                      Icons.compare_arrows_rounded,
                      size: 18, // 아이콘 크기 축소
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '나의 등산 기록 비교',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // 날짜 비교 카드 - 심플한 디자인
            Container(
              margin: EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 이전 날짜
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 16,
                          color: previousColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatDate(appState.previousRecordDate ?? ''),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: previousColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // VS 표시 - 심플한 스타일
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),

                  // 현재 날짜
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 16,
                          color: currentColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatDate(appState.currentRecordDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: currentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 통합 비교 카드 - 더 심플하고 모던한 디자인
            Container(
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 등산 시간 비교
                  _buildModernComparisonItem(
                    title: '총 등산 시간',
                    icon: Icons.timer_outlined,
                    iconColor: primaryColor, // 아이콘 색상 통일
                    previousValue: _formatMinutes(prevTime),
                    currentValue: _formatMinutes(appState.elapsedMinutes),
                    changeText: timeDiffText,
                    isPositive: timeDiff != null && timeDiff < 0,
                    previousColor: previousColor,
                    currentColor: currentColor,
                    showDivider: true,
                    iconBgColor: primaryColor.withOpacity(0.1), // 배경색 통일
                  ),

                  // 최고 심박수 비교
                  _buildModernComparisonItem(
                    title: '최고 심박수',
                    icon: Icons.monitor_heart_rounded,
                    iconColor: primaryColor, // 아이콘 색상 통일
                    previousValue: '$prevMaxHr bpm',
                    currentValue: '$currMaxHr bpm',
                    changeText: currMaxHr > prevMaxHr
                        ? '${currMaxHr - prevMaxHr} bpm 증가'
                        : currMaxHr < prevMaxHr
                            ? '${prevMaxHr - currMaxHr} bpm 감소'
                            : '변화 없음',
                    isPositive: currMaxHr < prevMaxHr,
                    previousColor: previousColor,
                    currentColor: currentColor,
                    showDivider: true,
                    iconBgColor: primaryColor.withOpacity(0.1), // 배경색 통일
                  ),

                  // 평균 심박수 비교
                  _buildModernComparisonItem(
                    title: '평균 심박수',
                    icon: Icons.favorite_border_rounded,
                    iconColor: primaryColor, // 아이콘 색상 통일
                    previousValue: '$prevAvgHr bpm',
                    currentValue: '$currAvgHr bpm',
                    changeText: currAvgHr > prevAvgHr
                        ? '${currAvgHr - prevAvgHr} bpm 증가'
                        : currAvgHr < prevAvgHr
                            ? '${prevAvgHr - currAvgHr} bpm 감소'
                            : '변화 없음',
                    isPositive: currAvgHr < prevAvgHr,
                    previousColor: previousColor,
                    currentColor: currentColor,
                    showDivider: false,
                    iconBgColor: primaryColor.withOpacity(0.1), // 배경색 통일
                  ),
                ],
              ),
            ),

            // 뱃지 표시 - "획득 뱃지" 제거하고 더 큰 뱃지로 수정
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 뱃지 이미지 (뱃지 외곽선에서 바로 후광이 나오는 효과)
                    Center(
                      child: SizedBox(
                        width: 160, // 크기 증가
                        height: 160, // 크기 증가
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 후광 효과 레이어
                            Container(
                              width: 200, // 크기 증가
                              height: 200, // 크기 증가
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  // 바깥쪽 후광 (넓게 퍼지는 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[100]!.withOpacity(0.9),
                                    blurRadius: 50,
                                    spreadRadius: 20,
                                  ),
                                  // 중간 후광 (선명한 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[200]!.withOpacity(0.8),
                                    blurRadius: 30,
                                    spreadRadius: 12,
                                  ),
                                  // 안쪽 후광 (강한 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[300]!.withOpacity(0.7),
                                    blurRadius: 20,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),

                            // 뱃지 이미지
                            Container(
                              width: 160, // 크기 증가
                              height: 160, // 크기 증가
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.amber[200]!, // 더 은은한 노란색
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: badgeUrl.isNotEmpty
                                    ? Image.network(
                                        badgeUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.amber[50], // 더 은은한 배경색
                                          child: Icon(
                                            Icons.emoji_events_rounded,
                                            size: 80, // 크기 증가
                                            color:
                                                Colors.amber[500], // 더 은은한 노란색
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.amber[50], // 더 은은한 배경색
                                        child: Icon(
                                          Icons.emoji_events_rounded,
                                          size: 80, // 크기 증가
                                          color: Colors.amber[500], // 더 은은한 노란색
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 뱃지 아래에 텍스트 추가
                    SizedBox(height: 50),
                    Text(
                      "뱃지를 획득했어요!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700], // 노란색과 어울리는 색상
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

// 더 깔끔하고 모던한 비교 아이템 위젯 (아이콘 박스 크기 축소 및 색상 파라미터 추가)
  Widget _buildModernComparisonItem({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String previousValue,
    required String currentValue,
    required String changeText,
    required bool isPositive,
    required Color previousColor,
    required Color currentColor,
    required bool showDivider,
    required Color iconBgColor, // 아이콘 배경색 파라미터 추가
  }) {
    final Color positiveColor = Color(0xFF53A487);
    final Color negativeColor = Color(0xFFE57373);
    final Color neutralColor = Color(0xFF9E9E9E);

    Color getChangeColor() {
      if (isPositive) return positiveColor;
      if (!isPositive && changeText != '변화 없음') return negativeColor;
      return neutralColor;
    }

    final changeColor = getChangeColor();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 타이틀과 아이콘 (아이콘 박스 크기 축소)
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8), // 패딩 축소
                    decoration: BoxDecoration(
                      color: iconBgColor, // 배경색 파라미터 사용
                      borderRadius: BorderRadius.circular(10), // 모서리 반경 축소
                    ),
                    child: Icon(
                      icon,
                      size: 18, // 아이콘 크기 축소
                      color: iconColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  Spacer(),

                  // 변화량 표시 (우측 정렬)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_downward_rounded
                              : changeText != '변화 없음'
                                  ? Icons.arrow_upward_rounded
                                  : Icons.remove_rounded,
                          size: 14,
                          color: changeColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          changeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // 값 비교 - 깔끔한 레이아웃
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 이전 값
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이전 기록',
                          style: TextStyle(
                            fontSize: 12,
                            color: previousColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          previousValue,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: previousColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 화살표 아이콘
                  Icon(
                    Icons.east_rounded,
                    size: 20,
                    color: Colors.grey[300],
                  ),

                  // 현재 값
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '현재 기록',
                          style: TextStyle(
                            fontSize: 12,
                            color: currentColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          currentValue,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: currentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 구분선 (마지막 항목이 아닐 경우에만)
        if (showDivider)
          Divider(
            color: Colors.grey[100],
            thickness: 2,
            height: 1,
          ),
      ],
    );
  }

  // 나 vs 친구 모드 결과 화면 - 오버플로우 수정 버전
  Widget _buildVsFriendResult(String mountainName) {
    final appState = Provider.of<AppState>(context, listen: false);
    final modeData = appState.modeData;
    final timeDiff = widget.resultData['timeDiff'];
    final String timeDiffText = timeDiff != null
        ? timeDiff < 0
            ? "${timeDiff.abs()}분 단축"
            : "$timeDiff분 증가"
        : "";

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

    // 심박수 차이 계산 및 코멘트 생성
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

    // 색상 상수 정의
    final Color primaryColor = Color(0xFF52A486);
    final Color orangeColor = Colors.orange[700]!;

    // SingleChildScrollView를 사용하여 오버플로우 방지
    return SingleChildScrollView(
      child: Padding(
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '나 vs 친구',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 24),

                    Container(
                      margin: EdgeInsets.symmetric(vertical: 16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 비교 헤더
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.orange[200]!, width: 1),
                                ),
                                child: Text(
                                  '내 기록',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.compare_arrows,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.green[200]!, width: 1),
                                ),
                                child: Text(
                                  '친구 기록',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 20),

                          // 날짜 비교
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currentDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '날짜',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                friendDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          // 구분선
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child:
                                Divider(color: Colors.grey[200], thickness: 1),
                          ),

                          // 시간 비교
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatMinutes(currTimeSeconds),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                              Column(
                                children: [
                                  Icon(Icons.timer_outlined,
                                      color: Colors.grey[600], size: 18),
                                  SizedBox(height: 4),
                                  Text(
                                    '소요 시간',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _formatMinutes(friendTimeMinutes),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),

                          // 구분선
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child:
                                Divider(color: Colors.grey[200], thickness: 1),
                          ),

                          // 최고 심박수 비교
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${widget.resultData['maxHeartRate'] ?? 0} bpm',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              Column(
                                children: [
                                  Icon(Icons.favorite,
                                      color: Colors.red, size: 18),
                                  SizedBox(height: 4),
                                  Text(
                                    '최고 심박수',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$friendMaxHeartRate bpm',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),

                          // 구분선
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child:
                                Divider(color: Colors.grey[200], thickness: 1),
                          ),

                          // 평균 심박수 비교
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${widget.resultData['averageHeartRate'] is double ? (widget.resultData['averageHeartRate'] as double).toInt() : widget.resultData['averageHeartRate'] ?? 0} bpm',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[400],
                                ),
                              ),
                              Column(
                                children: [
                                  Icon(Icons.favorite_border,
                                      color: Colors.red[400], size: 18),
                                  SizedBox(height: 4),
                                  Text(
                                    '평균 심박수',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${friendAvgHeartRate.round()} bpm',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // 성과 비교 표시
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: timeDiff != null && timeDiff < 0
                            ? Color(0xFFE8F5EC)
                            : Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: timeDiff != null && timeDiff < 0
                              ? primaryColor.withOpacity(0.3)
                              : orangeColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            timeDiff != null && timeDiff < 0
                                ? Icons.trending_down
                                : Icons.trending_up,
                            color: timeDiff != null && timeDiff < 0
                                ? primaryColor
                                : orangeColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            timeDiffText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: timeDiff != null && timeDiff < 0
                                  ? primaryColor
                                  : orangeColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // 뱃지 이미지 표시
                    if (badgeUrl.isNotEmpty)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            badgeUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Column(
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
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          size: 80,
                          color: Colors.amber,
                        ),
                      ),

                    SizedBox(height: 20),

                    // 심박수 차이 카드
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.favorite, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Text(
                                maxHrComment,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.favorite_border,
                                  color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Text(
                                avgHrComment,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
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
            ),
          ],
        ),
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
    final int distance = appState.distance;
    final String distanceFormatted =
        distance < 1.0 ? '${distance}m' : '${distance.toStringAsFixed(1)}km';

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
