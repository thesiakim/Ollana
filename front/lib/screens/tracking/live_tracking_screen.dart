// live_tracking_screen.dart: 실시간 트래킹 화면
// - 네이버 지도 기반 실시간 위치 및 등산로 표시
// - 현재 정보 (고도, 이동 거리, 소요 시간 등) 표시
// - 트래킹 종료 기능

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';

// 현재 flutter_naver_map 라이브러리가 설치되지 않아 임시 UI로 대체
// 실제 구현 시 아래 주석을 해제하고 사용
// import 'package:flutter_naver_map/flutter_naver_map.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  // NaverMapController? _mapController;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _elapsedMinutes = 0;
  double _currentAltitude = 120;
  double _distance = 3.7;

  // 현재 위치 (테스트용 임시 데이터)
  double _currentLat = 37.5665;
  double _currentLng = 126.9780;

  // 최고/평균 심박수
  int _maxHeartRate = 120;
  int _avgHeartRate = 86;

  // 경쟁 모드 데이터 (테스트용)
  final Map<String, dynamic> _competitorData = {
    'name': '내가바로락선',
    'distance': 4.1,
    'time': 47,
    'maxHeartRate': 120,
    'avgHeartRate': 86,
    'isAhead': true, // 경쟁자가 앞서는지 여부
  };

  // 임시 경로 데이터
  final List<Map<String, double>> _routeCoordinates = [
    {'lat': 37.5665, 'lng': 126.9780},
    {'lat': 37.5690, 'lng': 126.9800},
    {'lat': 37.5720, 'lng': 126.9830},
    {'lat': 37.5760, 'lng': 126.9876},
  ];

  // 사용자 이동 경로 기록
  final List<Map<String, double>> _userPath = [];

  // 페이지 상태
  final bool _isPaused = false;
  bool _isSheetExpanded = false;

  // 바텀 시트 컨트롤러
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _startTracking();

    // 초기 경로 데이터 설정
    _userPath.add({'lat': _currentLat, 'lng': _currentLng});

    // 시트 컨트롤러 리스너 설정
    _sheetController.addListener(_onSheetChanged);
  }

  void _onSheetChanged() {
    final isExpanded = _sheetController.size >= 0.5;
    if (isExpanded != _isSheetExpanded) {
      setState(() {
        _isSheetExpanded = isExpanded;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    super.dispose();
  }

  // 트래킹 시작
  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
          if (_elapsedSeconds % 60 == 0) {
            _elapsedMinutes++;
          }

          // 테스트용 데이터 업데이트 - 실제로는 GPS 데이터 사용
          if (_elapsedSeconds % 10 == 0) {
            _updatePosition();
          }

          // 고도 변경 (테스트용)
          _currentAltitude += (math.Random().nextDouble() * 2 - 1);

          // 심박수 업데이트 (테스트용)
          if (_elapsedSeconds % 5 == 0) {
            _updateHeartRate();
          }
        });
      }
    });
  }

  // 위치 업데이트 (테스트용)
  void _updatePosition() {
    final nextIdx = (_userPath.length % _routeCoordinates.length);
    final nextPoint = _routeCoordinates[nextIdx];

    _currentLat = nextPoint['lat']!;
    _currentLng = nextPoint['lng']!;

    // 경로에 현재 위치 추가
    _userPath.add({'lat': _currentLat, 'lng': _currentLng});

    // 거리 업데이트 (테스트용)
    setState(() {
      _distance -= 0.1;
      if (_distance < 0) _distance = 0;
    });
  }

  // 심박수 업데이트 (테스트용)
  void _updateHeartRate() {
    // 현재 심박수 (80~140 사이 랜덤값)
    int currentHeartRate = 80 + math.Random().nextInt(60);

    // 최고 심박수 업데이트
    if (currentHeartRate > _maxHeartRate) {
      _maxHeartRate = currentHeartRate;
    }

    // 평균 심박수 업데이트 (간단한 시뮬레이션)
    _avgHeartRate = ((_avgHeartRate * 9) + currentHeartRate) ~/ 10; // 가중 평균
  }

  // 포맷팅된 시간 문자열
  String get _formattedTime {
    final minutes = _elapsedMinutes;
    return '$minutes분';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도 영역
          Container(
            padding: EdgeInsets.only(bottom: 127),
            color: Colors.grey[200],
            child: CustomPaint(
              painter: RoutePainter(),
              child: Stack(
                children: [
                  // 현재 위치 표시
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          '전체 지도 + 내 위치 핀',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 추가적인 지도 오버레이 요소들은 여기에 배치할 수 있습니다.
                ],
              ),
            ),
          ),

          // 드래그 가능한 바텀 시트
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.25,
            minChildSize: 0.25,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 바텀 시트 핸들 - 고정 영역
                    Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    // 스크롤 가능한 내용 영역
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          // 정보 패널
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 기본 정보 (항상 표시)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '남은 거리 : ${_distance.toStringAsFixed(1)}km',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '예상 남은 시간 : $_formattedTime',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '현재 고도 : ${_currentAltitude.toStringAsFixed(1)}m',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '최고 심박수 : $_maxHeartRate bpm',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '평균 심박수 : $_avgHeartRate bpm',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),

                                // 올려진 상태에서만 보이는 정보
                                if (_isSheetExpanded) ...[
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Text(
                                        '내 정보',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'vs',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    '내가바로락선',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '(지금 재연이 나바봐 또는 진구 네바리)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    '남은 거리 : ${_competitorData['distance']}km',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '예상 남은 시간 : ${_competitorData['time']}분',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '최고 심박수 : ${_competitorData['maxHeartRate']} bpm',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '평균 심박수 : ${_competitorData['avgHeartRate']} bpm',
                                    style: TextStyle(fontSize: 14),
                                  ),

                                  // 피드백 메시지
                                  Container(
                                    margin: EdgeInsets.only(top: 12),
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '0.4km 앞서는 중!',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_upward,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 등산 종료 버튼
                                  SizedBox(height: 30),
                                  Container(
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 50),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _showEndTrackingDialog(context),
                                      icon: Icon(
                                        _isPaused
                                            ? Icons.play_arrow
                                            : Icons.pause,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        '등산 종료',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 여분의 공간 추가해서 스크롤이 잘 되도록 함
                                  SizedBox(height: 30),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 등산 종료 확인 다이얼로그
  void _showEndTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '등산 종료',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                '정말로 등산을 \n종료하시겠습니까?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      // 등산 종료 처리
                      Provider.of<AppState>(context, listen: false)
                          .endTracking();
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '종료',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 임시 등산로 페인터
class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 경로 그리기 (검은색)
    final routePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 현재 진행 경로 (노란색)
    final currentPathPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 경로 경계 그리기
    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.25,
      size.width * 0.6,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.7,
      size.width * 0.7,
      size.height * 0.6,
    );

    canvas.drawPath(path, routePaint);

    // 현재 진행 경로 그리기
    final currentPath = Path();
    currentPath.moveTo(size.width * 0.1, size.height * 0.8);
    currentPath.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.2,
    );

    canvas.drawPath(currentPath, currentPathPaint);

    // 종점 표시 (파란색 원)
    final endPointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.2),
      20,
      endPointPaint,
    );

    // 종점 텍스트
    const endPointText = "End Point";
    final endPointSpan = TextSpan(
      text: endPointText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );

    final endPointPainter = TextPainter(
      text: endPointSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    endPointPainter.layout();
    endPointPainter.paint(
      canvas,
      Offset(
        size.width * 0.5 - endPointPainter.width / 2,
        size.height * 0.2 - endPointPainter.height / 2,
      ),
    );

    // 현재 위치 표시 (빨간색 원)
    final currentPointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      15,
      currentPointPaint,
    );

    // 현재 위치 텍스트
    const currentPointText = "내 위치";
    final currentPointSpan = TextSpan(
      text: currentPointText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    );

    final currentPointPainter = TextPainter(
      text: currentPointSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    currentPointPainter.layout();
    currentPointPainter.paint(
      canvas,
      Offset(
        size.width * 0.1 - currentPointPainter.width / 2,
        size.height * 0.8 - currentPointPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
