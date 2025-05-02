// live_tracking_screen.dart: 실시간 트래킹 화면
// - 네이버 지도 기반 실시간 위치 및 등산로 표시
// - 현재 정보 (고도, 이동 거리, 소요 시간 등) 표시
// - 트래킹 종료 기능

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../utils/app_colors.dart';

// 네이버 지도 라이브러리 임포트
import 'package:flutter_naver_map/flutter_naver_map.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  NaverMapController? _mapController;
  NLocationOverlay? _locationOverlay;
  double _locationBearing = 0; // 직접 방향 값을 관리
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
    'name': '내가',
    'distance': 4.1,
    'time': 47,
    'maxHeartRate': 120,
    'avgHeartRate': 86,
    'isAhead': true, // 경쟁자가 앞서는지 여부
  };

  // 등산로 경로 데이터 (실제로는 선택된 경로 데이터 사용)
  final List<NLatLng> _routeCoordinates = [
    NLatLng(37.5665, 126.9780),
    NLatLng(37.5690, 126.9800),
    NLatLng(37.5720, 126.9830),
    NLatLng(37.5760, 126.9876),
  ];

  // 사용자 이동 경로 기록
  final List<NLatLng> _userPath = [];

  // 페이지 상태
  final bool _isPaused = false;
  bool _isSheetExpanded = false;

  // 경로 오버레이 및 마커 ID
  final String _routeOverlayId = 'hiking-route';
  final String _startPointMarkerId = 'start-point';
  final String _endPointMarkerId = 'end-point';

  // 네비게이션 모드 여부 (기본값을 true로 변경)
  bool _isNavigationMode = true;

  // 바텀 시트 컨트롤러
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _startTracking();

    // 초기 경로 데이터 설정
    _userPath.add(NLatLng(_currentLat, _currentLng));

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
    _mapController = null;
    _locationOverlay = null;
    super.dispose();
  }

  // 트래킹 시작
  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
          if (_elapsedSeconds % 60 == 0) {
            _elapsedMinutes++;
          }

          // 고도 변경 (테스트용)
          _currentAltitude += (math.Random().nextDouble() * 2 - 1);
        });

        // 테스트용 데이터 업데이트 - 실제로는 GPS 데이터 사용
        if (_elapsedSeconds % 10 == 0) {
          await _updatePosition();
        }

        // 심박수 업데이트 (테스트용)
        if (_elapsedSeconds % 5 == 0) {
          _updateHeartRate();
        }
      }
    });
  }

  // 위치 업데이트 (테스트용)
  Future<void> _updatePosition() async {
    final nextIdx = (_userPath.length % _routeCoordinates.length);
    final nextPoint = _routeCoordinates[nextIdx];

    _currentLat = nextPoint.latitude;
    _currentLng = nextPoint.longitude;

    // 경로에 현재 위치 추가
    _userPath.add(NLatLng(_currentLat, _currentLng));

    // 현재 위치 오버레이 업데이트
    await _updateLocationOverlay();

    // 거리 업데이트 (테스트용)
    setState(() {
      _distance -= 0.1;
      if (_distance < 0) _distance = 0;
    });
  }

  // 위치 오버레이 업데이트
  Future<void> _updateLocationOverlay() async {
    if (_mapController != null) {
      try {
        // 위치 오버레이가 아직 초기화되지 않았으면 초기화
        if (_locationOverlay == null) {
          _locationOverlay = _mapController!.getLocationOverlay();
          // 위치 오버레이 기본 스타일 설정
          // 기본 아이콘 사용
          _locationOverlay!.setCircleRadius(30);
          _locationOverlay!.setCircleColor(AppColors.primary.withAlpha(10));
          _locationOverlay!.setCircleOutlineWidth(2);
          _locationOverlay!.setCircleOutlineColor(AppColors.primary);
        }

        // 위치 오버레이 위치 및 방향 업데이트
        _locationOverlay!.setPosition(NLatLng(_currentLat, _currentLng));

        // 다음 위치 방향으로 베어링 설정 (실제로는 GPS 방향 사용)
        if (_userPath.length >= 2) {
          final lastIdx = _userPath.length - 1;
          final prevPoint = _userPath[lastIdx - 1];
          final currPoint = _userPath[lastIdx];

          // 두 지점 간의 방향 계산 (간단한 계산)
          final deltaLat = currPoint.latitude - prevPoint.latitude;
          final deltaLng = currPoint.longitude - prevPoint.longitude;
          _locationBearing = math.atan2(deltaLng, deltaLat) * 180 / math.pi;
          _locationOverlay!.setBearing(_locationBearing);
        }

        // 위치 오버레이 표시
        _locationOverlay!.setIsVisible(true);

        // 네비게이션 모드일 경우 카메라를 현재 위치로 이동
        if (_isNavigationMode) {
          _mapController!.updateCamera(
            NCameraUpdate.withParams(
              target: NLatLng(_currentLat, _currentLng),
              zoom: 17,
              bearing: _locationBearing,
              tilt: 50,
            ),
          );
        }
      } catch (e) {
        debugPrint('위치 오버레이 업데이트 중 오류 발생: $e');
      }
    }
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

  // 지도에 등산로 경로 표시
  Future<void> _showRouteOnMap() async {
    if (_mapController == null || _routeCoordinates.isEmpty) return;

    try {
      // 경로 오버레이 추가
      _mapController!.addOverlay(
        NPathOverlay(
          id: _routeOverlayId,
          coords: _routeCoordinates,
          color: AppColors.primary,
          width: 5,
          outlineWidth: 2,
          outlineColor: Colors.white,
          // 패턴 이미지 임시 제거
          patternInterval: 30,
        ),
      );

      // 출발점 마커 추가
      _mapController!.addOverlay(
        NMarker(
          id: _startPointMarkerId,
          position: _routeCoordinates.first,
          // 기본 마커 사용
          caption: const NOverlayCaption(
            text: '출발점',
            textSize: 12,
          ),
        ),
      );

      // 도착점 마커 추가
      _mapController!.addOverlay(
        NMarker(
          id: _endPointMarkerId,
          position: _routeCoordinates.last,
          // 기본 마커 사용
          caption: const NOverlayCaption(
            text: '도착점',
            textSize: 12,
          ),
        ),
      );

      // 현재 위치 오버레이 초기화 및 업데이트
      await _updateLocationOverlay();

      // 등산로 경로가 전부 보이도록 카메라 이동 (바운드 처리 수정)
      final bounds = _calculateRouteBounds();
      _mapController!.updateCamera(
        NCameraUpdate.fitBounds(
          bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (e) {
      debugPrint('등산로 경로 표시 중 오류 발생: $e');
    }
  }

  // 경로의 경계 계산 (바운딩 박스)
  NLatLngBounds _calculateRouteBounds() {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var point in _routeCoordinates) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return NLatLngBounds(
      southWest: NLatLng(minLat, minLng),
      northEast: NLatLng(maxLat, maxLng),
    );
  }

  // 네비게이션 모드 전환
  void _toggleNavigationMode() {
    setState(() {
      _isNavigationMode = !_isNavigationMode;
    });

    if (_mapController != null) {
      if (_isNavigationMode) {
        // 네비게이션 모드 활성화: 현재 위치 중심, 3D 기울기 적용
        _mapController!.updateCamera(
          NCameraUpdate.withParams(
            target: NLatLng(_currentLat, _currentLng),
            zoom: 17,
            bearing: _locationBearing,
            tilt: 50,
          ),
        );
      } else {
        // 네비게이션 모드 비활성화: 전체 경로 조망
        _mapController!.updateCamera(
          NCameraUpdate.fitBounds(
            _calculateRouteBounds(),
            padding: const EdgeInsets.all(50),
          ),
        );
        _mapController!.updateCamera(
          NCameraUpdate.withParams(tilt: 0),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 네이버 지도 영역
          Container(
            padding: const EdgeInsets.only(bottom: 127),
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(_currentLat, _currentLng),
                  zoom: 17,
                  tilt: 50,
                ),
                mapType: NMapType.navi,
                nightModeEnable: false,
                scrollGesturesEnable: true,
                zoomGesturesEnable: true,
                rotationGesturesEnable: true,
                tiltGesturesEnable: true,
                locationButtonEnable: true,
                contentPadding: const EdgeInsets.all(0),
                activeLayerGroups: [
                  NLayerGroup.mountain,
                  NLayerGroup.building,
                  NLayerGroup.transit,
                ],
              ),
              onMapReady: (controller) {
                _mapController = controller;
                // 지도가 준비되면 경로 표시
                Future.delayed(const Duration(milliseconds: 300), () async {
                  await _showRouteOnMap();

                  // 네비게이션 모드 기본 설정 - 현재 위치 중심, 3D 기울기 적용
                  if (_isNavigationMode) {
                    _mapController!.updateCamera(
                      NCameraUpdate.withParams(
                        target: NLatLng(_currentLat, _currentLng),
                        zoom: 17,
                        bearing: 0,
                        tilt: 50,
                      ),
                    );
                  }
                });
              },
            ),
          ),

          // 네비게이션 모드 토글 버튼
          _buildNavigationToggleButton(),

          // 드래그 가능한 바텀 시트
          _buildDraggableBottomSheet(),
        ],
      ),
    );
  }

  // 네비게이션 모드 토글 버튼 위젯
  Widget _buildNavigationToggleButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: FloatingActionButton(
        heroTag: 'navToggle',
        onPressed: _toggleNavigationMode,
        mini: true,
        backgroundColor: _isNavigationMode ? AppColors.primary : Colors.white,
        child: Icon(
          _isNavigationMode ? Icons.navigation : Icons.map,
          color: _isNavigationMode ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }

  // 드래그 가능한 바텀 시트 위젯
  Widget _buildDraggableBottomSheet() {
    return DraggableScrollableSheet(
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
              _buildBottomSheetHandle(),
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
                          _buildBasicInfoSection(),

                          // 올려진 상태에서만 보이는 정보
                          if (_isSheetExpanded) _buildExpandedInfoSection(),
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
    );
  }

  // 바텀 시트 핸들 위젯
  Widget _buildBottomSheetHandle() {
    return GestureDetector(
      onTap: () {
        // 터치 시 시트 확장/축소 전환
        final targetSize = _isSheetExpanded ? 0.25 : 0.9;
        _sheetController.animateTo(
          targetSize,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      onVerticalDragEnd: (details) {
        // 드래그 방향에 따라 시트 확장/축소
        final velocity = details.primaryVelocity ?? 0;
        final targetSize =
            velocity < 0 ? 0.9 : 0.25; // 위로 드래그하면 확장, 아래로 드래그하면 축소
        _sheetController.animateTo(
          targetSize,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  // 기본 정보 섹션 위젯
  Widget _buildBasicInfoSection() {
    return Column(
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
    );
  }

  // 확장된 정보 섹션 위젯
  Widget _buildExpandedInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _buildFeedbackMessage(),

        // 등산 종료 버튼
        _buildEndTrackingButton(),

        // 여분의 공간 추가해서 스크롤이 잘 되도록 함
        SizedBox(height: 30),
      ],
    );
  }

  // 피드백 메시지 위젯
  Widget _buildFeedbackMessage() {
    return Container(
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
    );
  }

  // 등산 종료 버튼 위젯
  Widget _buildEndTrackingButton() {
    return Container(
      margin: EdgeInsets.only(top: 30, left: 50, right: 50),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextButton.icon(
        onPressed: () => _showEndTrackingDialog(context),
        icon: Icon(
          _isPaused ? Icons.play_arrow : Icons.pause,
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
