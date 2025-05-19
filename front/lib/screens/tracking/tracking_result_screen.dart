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
  final double? opponentAvgHeartRate;
  final int? currentElapsedSeconds;
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
    this.currentElapsedSeconds,
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
  String _formatSeconds(int minutes) {
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}시간 ${remainingMinutes}분';
    } else {
      return '${remainingMinutes}분';
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

  // 나 vs 나 모드 결과 화면
  Widget _buildVsMeResult(String mountainName) {
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

    // 결과 데이터 전체 로그
    debugPrint('[tracking_result_screen] resultData: ${widget.resultData}');

    // 현재 기록
    final int currTime = widget.currentElapsedSeconds ?? 0;
    final double currDist = widget.currentDistanceMeters ?? 0.0;
    final String currDistText = currDist < 1000
        ? '${currDist.toInt()}분'
        : '${(currDist / 1000).toStringAsFixed(2)}km';
    final int currMaxHr = (widget.resultData['maxHeartRate'] is double)
        ? (widget.resultData['maxHeartRate'] as double).round()
        : widget.resultData['maxHeartRate'] ?? 0;
    final int currAvgHr = (widget.resultData['averageHeartRate'] is double)
        ? (widget.resultData['averageHeartRate'] as double).round()
        : widget.resultData['averageHeartRate'] ?? 0;

    // 이전 기록
    final String prevDate = widget.previousRecordDate ?? '—';
    final int prevTime = widget.previousRecordTimeSeconds ?? 0;
    final String prevTimeText = _formatSeconds(prevTime);
    final int prevMaxHr = widget.previousMaxHeartRate ?? 0;
    final int prevAvgHrDouble = widget.previousAvgHeartRate ?? 0;
    final String prevAvgHrText = '${prevAvgHrDouble.round()} bpm';

    // 심박수 차이 계산
    final int maxHrDiff = currMaxHr - prevMaxHr;
    final int avgHrDiff = currAvgHr - prevAvgHrDouble;

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

    // 디버그 로그 추가
    debugPrint('[tracking_result_screen] _buildVsMeResult - 이전 기록:');
    debugPrint('  - prevDate: $prevDate');
    debugPrint('  - prevTimeSeconds: $prevTime');
    debugPrint('  - prevMaxHeartRate: $prevMaxHr');
    debugPrint('  - prevAvgHeartRate: $prevAvgHrText');

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
                    '나 vs 나',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),

                  // 이전 기록과 현재 기록 비교
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 현재 기록
                      Column(
                        children: [
                          Text('현재 기록',
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
                                Text(_formatDate(appState.currentRecordDate),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700])),
                                SizedBox(height: 8),
                                Text(_formatSeconds(appState.elapsedMinutes),
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
                                Text('$currMaxHr bpm',
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
                                Text('$currAvgHr bpm',
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

                      // 이전 기록 부분
                      Column(
                        children: [
                          Text('이전 기록',
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
                                Text(
                                    _formatDate(
                                        appState.previousRecordDate ?? ''),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700])),
                                SizedBox(height: 8),
                                Text(prevTimeText,
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
                                Text('$prevMaxHr bpm',
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
                                Text(prevAvgHrText,
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

                  SizedBox(height: 24),

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

                  SizedBox(height: 16),

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
    debugPrint('  - friendTimeSeconds: ${widget.opponentRecordTime}');
    debugPrint('  - friendMaxHeartRate: ${widget.opponentMaxHeartRate}');
    debugPrint('  - friendAvgHeartRate: ${widget.opponentAvgHeartRate}');

    // badge URL 가져오기
    final String badgeUrl = widget.resultData['badge'] ?? '';

    // 친구 기록 정보 - 위젯에서 가져오기
    final String friendDate = _formatDate(widget.opponentRecordDate) ?? '기본값';
    final int friendTimeSeconds = widget.opponentRecordTime ?? 0;
    final int friendMaxHeartRate =
        widget.opponentMaxHeartRate ?? widget.resultData['maxHeartRate'] ?? 0;
    final double friendAvgHeartRate = widget.opponentAvgHeartRate ??
        widget.resultData['averageHeartRate'] ??
        0.0;

    // 현재 기록 정보
    final int currTimeSeconds = widget.currentElapsedSeconds ?? 0;
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
                                Text(_formatSeconds(currTimeSeconds),
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
                                    '${widget.resultData['averageHeartRate'] ?? 0} bpm',
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
                                Text(_formatSeconds(friendTimeSeconds),
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

                  SizedBox(height: 24),

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

                  SizedBox(height: 16),

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

  // 일반 등산 모드 결과 화면
  Widget _buildGeneralResult(String mountainName) {
    final appState = Provider.of<AppState>(context, listen: false);

    // 뱃지 URL 가져오기
    final String badgeUrl = widget.resultData['badge'] ?? '';

    // 현재 날짜 포맷팅
    final now = DateTime.now();
    final String currentDate =
        '${now.year.toString().substring(2)}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    // 등산 데이터를 live_tracking_screen에서 전달된 값으로 사용
    final int timeSeconds = appState.elapsedSeconds;
    final String timeFormatted = _formatSeconds(timeSeconds);

    // 심박수 데이터는 서버 응답에서 가져옴
    final int maxHeartRate = (widget.resultData['maxHeartRate'] is double)
        ? (widget.resultData['maxHeartRate'] as double).round()
        : widget.resultData['maxHeartRate'] ?? 0;
    final int avgHeartRate = (widget.resultData['averageHeartRate'] is double)
        ? (widget.resultData['averageHeartRate'] as double).round()
        : widget.resultData['averageHeartRate'] ?? 0;

    // 이동 거리는 AppState에서 가져옴 (m를 km로 변환)
    final double distance = appState.distance / 1000;
    final String distanceFormatted = '${distance.toStringAsFixed(1)}km';

    debugPrint(
        '등산 결과 데이터 - 시간: $timeSeconds초, 거리: $distance km, 최고심박수: $maxHeartRate, 평균심박수: $avgHeartRate');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$mountainName 등반 결과',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // 노란색 결과 카드
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFFEEAA1), // 이미지의 노란색 배경
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // 날짜
                Text(
                  currentDate,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10),

                // 산행 거리
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '총 산행 거리 : ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      distanceFormatted,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),

                // 등산 시간
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '총 등산 시간 : ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      timeFormatted,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // 심박수 데이터
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '최고 심박수 : ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$maxHeartRate bpm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '평균 심박수 : ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$avgHeartRate bpm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 뱃지 이미지 표시
          Expanded(
            child: Center(
              child: badgeUrl.isNotEmpty
                  ? Image.network(
                      badgeUrl,
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildBadgeFallback(),
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
                    )
                  : _buildBadgeFallback(),
            ),
          ),

          // 결과에 대한 코멘트 버튼
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              onPressed: () {
                // 코멘트 표시 로직 추가
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('수고하셨습니다! 오늘도 성공적인 등산이었습니다.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '총평',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '결과에 대한 코멘트',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
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

  // 확인 버튼
  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () async {
          // 1. AppState 트래킹 데이터 초기화
          final appState = Provider.of<AppState>(context, listen: false);
          appState.endTracking(); // 여기서 모든 데이터 초기화

          // 2. 트래킹 서비스와 알림 종료 확인
          _stopBackgroundService();
          _cancelAllNotifications();

          // 3. 홈 화면으로 이동
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '확인',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
