// live_tracking_screen.dart: 실시간 트래킹 화면
// - 네이버 지도 기반 실시간 위치 및 등산로 표시
// - 현재 정보 (고도, 이동 거리, 소요 시간 등) 표시
// - 트래킹 종료 기능

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  double _currentAltitude = 120;
  double _distance = 0.0;

  // 현재 위치 (테스트용 임시 데이터)
  double _currentLat = 37.5665;
  double _currentLng = 126.9780;

  // 임시 경로 데이터
  final List<Map<String, double>> _routeCoordinates = [
    {'lat': 37.5665, 'lng': 126.9780},
    {'lat': 37.5690, 'lng': 126.9800},
    {'lat': 37.5720, 'lng': 126.9830},
    {'lat': 37.5760, 'lng': 126.9876},
  ];

  // 사용자 이동 경로 기록 - 네이버 지도 SDK 설치 후 LatLng 클래스로 대체
  final List<Map<String, double>> _userPath = [];

  // 페이지 상태
  // final bool _isMapInitialized = false; // 사용되지 않는 변수
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 트래킹 시작
  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;

          // 테스트용 데이터 업데이트 - 실제로는 GPS 데이터 사용
          if (_elapsedSeconds % 10 == 0) {
            _updatePosition();
          }

          // 고도 변경 (테스트용)
          _currentAltitude += (math.Random().nextDouble() * 2 - 1);

          // 진행률 계산 (테스트용)
          if (_routeCoordinates.isNotEmpty) {
            _distance = (_elapsedSeconds / 10) * 0.1; // 임시 거리 계산
          }
        });

        // 맵 업데이트 - 네이버 지도 SDK 설치 후 주석 해제
        // if (_isMapInitialized && _mapController != null) {
        //   _updateMap();
        // }
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
  }

  // 지도 업데이트 (네이버 지도 SDK 설치 후 사용)
  /*
  void _updateMap() {
    final controller = _mapController!;
    
    // 기존 오버레이 제거
    controller.clearOverlays();
    
    // 원래 경로 그리기 (파란색)
    final routeCoords = _routeCoordinates.map((point) => 
      LatLng(point['lat']!, point['lng']!)
    ).toList();
    
    controller.addOverlay(
      PathOverlay(
        PathOverlayId('original_route'),
        routeCoords,
        width: 5,
        color: Colors.blue.withOpacity(0.7),
        outlineColor: Colors.white,
      ),
    );
    
    // 사용자 경로 그리기 (빨간색)
    if (_userPath.length > 1) {
      controller.addOverlay(
        PathOverlay(
          PathOverlayId('user_path'),
          _userPath,
          width: 5,
          color: Colors.red,
          outlineColor: Colors.white,
        ),
      );
    }
    
    // 현재 위치 마커
    controller.addOverlay(
      Marker(
        markerId: MarkerId('current_location'),
        position: LatLng(_currentLat, _currentLng),
        icon: OverlayImage.fromAssetImage('lib/assets/images/current_location.png'),
      ),
    );
    
    // 맵 카메라 이동
    controller.moveCamera(
      CameraUpdate.scrollTo(LatLng(_currentLat, _currentLng)),
    );
  }
  */

  // 포맷팅된 시간 문자열
  String get _formattedTime {
    final hours = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${appState.selectedMode} 트래킹'),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
      ),
      body: Column(
        children: [
          // 지도 영역
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // 네이버 지도 (임시 UI로 대체)
                Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '지도 영역\n(네이버 지도 SDK 설치 후 구현)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '현재 위치: $_currentLat, $_currentLng',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '경로 진행: ${_userPath.length}/${_routeCoordinates.length} 지점',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                // 정보 패널
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                              FontAwesomeIcons.clock, _formattedTime, '소요 시간'),
                          _buildInfoItem(
                              FontAwesomeIcons.mountain,
                              '${_currentAltitude.toStringAsFixed(1)}m',
                              '현재 고도'),
                          _buildInfoItem(FontAwesomeIcons.personWalking,
                              '${_distance.toStringAsFixed(1)}km', '이동 거리'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 하단 컨트롤 영역
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                // 등산로 정보
                Text(
                  '${appState.selectedMountain} - ${appState.selectedRoute}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 버튼 영역
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 일시정지/재개 버튼
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isPaused = !_isPaused;
                        });
                      },
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(_isPaused ? '재개' : '일시정지'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),

                    // 종료 버튼
                    ElevatedButton.icon(
                      onPressed: () => _showEndTrackingDialog(context),
                      icon: const Icon(Icons.stop),
                      label: const Text('등산 종료'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
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
  }

  // 정보 아이템 위젯
  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // 등산 종료 확인 다이얼로그
  void _showEndTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('등산 종료'),
        content: const Text('정말로 등산을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // 등산 종료 처리
              Provider.of<AppState>(context, listen: false).endTracking();
            },
            child: const Text('종료', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
