// live_tracking_screen.dart: 실시간 트래킹 화면
// - 네이버 지도 기반 실시간 위치 및 등산로 표시
// - 현재 정보 (고도, 이동 거리, 소요 시간 등) 표시
// - 트래킹 종료 기능

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/app_state.dart';
import '../../utils/app_colors.dart';

// 네이버 지도 라이브러리 임포트
import 'package:flutter_naver_map/flutter_naver_map.dart';

// 백그라운드 작업을 위한 헬퍼 함수
class _BackgroundTask {
  // 경로 최적화 계산 (백그라운드)
  static List<NLatLng> optimizeRoute(List<NLatLng> originalRoute) {
    if (originalRoute.length <= 100) return originalRoute;

    // 단순화 비율 계산 (최대 100개의 포인트로 제한)
    final int step = (originalRoute.length / 100).ceil();

    final List<NLatLng> optimized = [];
    // 시작점과 끝점은 항상 포함
    optimized.add(originalRoute.first);

    // 중간 포인트는 간격을 두고 추가
    for (int i = step; i < originalRoute.length - 1; i += step) {
      optimized.add(originalRoute[i]);
    }

    // 마지막 포인트 추가
    optimized.add(originalRoute.last);

    return optimized;
  }

  // 거리 계산 (백그라운드)
  static double calculateDistance(Map<String, double> params) {
    final double lat1 = params['lat1']!;
    final double lng1 = params['lng1']!;
    final double lat2 = params['lat2']!;
    final double lng2 = params['lng2']!;

    const double earthRadius = 6371000; // 지구 반경 (미터)
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // 각도를 라디안으로 변환
  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // 경로 바운드 계산 (백그라운드)
  static Map<String, double> calculateRouteBounds(List<NLatLng> routeToUse) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var point in routeToUse) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }
}

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  NaverMapController? _mapController;
  double _locationBearing = 0; // 직접 방향 값을 관리
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _elapsedMinutes = 0;
  double _currentAltitude = 120;
  double _distance = 3.7;

  // 현재 위치 (처음 지도 로드 위치)
  double _currentLat = 37.5665;
  double _currentLng = 126.9780;

  // 위치 트래킹 구독
  StreamSubscription<Position>? _positionStream;

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

  // 등산로 경로 데이터
  List<NLatLng> _routeCoordinates = [];

  // 사용자 이동 경로 기록
  final List<NLatLng> _userPath = [];

  // 페이지 상태
  final bool _isPaused = false;
  bool _isSheetExpanded = false;

  // 경로 오버레이 및 마커 ID
  final String _routeOverlayId = 'hiking-route';
  final String _startPointMarkerId = 'start-point';
  final String _endPointMarkerId = 'end-point';
  final String _userPathOverlayId = 'user-path';

  // 네비게이션 모드 여부 (기본값을 true로 변경)
  bool _isNavigationMode = true;

  // 바텀 시트 컨트롤러
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _loadSelectedRouteData();
    _checkLocationPermission();
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
    _positionStream?.cancel();
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    _mapController = null;
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
        });

        // 심박수 업데이트 (테스트용)
        if (_elapsedSeconds % 5 == 0) {
          _updateHeartRate();
        }
      }
    });
  }

  // 베어링(방향) 업데이트
  void _updateBearing() {
    if (_userPath.length >= 2) {
      final lastIdx = _userPath.length - 1;
      final prevPoint = _userPath[lastIdx - 1];
      final currPoint = _userPath[lastIdx];

      // 두 지점 간의 방향 계산
      final deltaLat = currPoint.latitude - prevPoint.latitude;
      final deltaLng = currPoint.longitude - prevPoint.longitude;
      _locationBearing = math.atan2(deltaLng, deltaLat) * 180 / math.pi;

      // 네비게이션 모드일 경우 카메라 회전
      if (_isNavigationMode && _mapController != null) {
        _mapController!.updateCamera(
          NCameraUpdate.withParams(
            target: NLatLng(_currentLat, _currentLng),
            zoom: 17,
            bearing: _locationBearing,
            tilt: 50,
          ),
        );
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
    if (_mapController == null) {
      debugPrint('지도 컨트롤러가 초기화되지 않았습니다.');
      return;
    }

    if (_routeCoordinates.isEmpty) {
      debugPrint('등산로 경로 데이터가 없습니다.');
      return;
    }

    try {
      debugPrint('지도에 경로 표시 시작: ${_routeCoordinates.length} 포인트');

      // 기존 오버레이 삭제
      _mapController!.clearOverlays();
      debugPrint('기존 오버레이 삭제됨');

      // 경로 오버레이 추가
      _mapController!.addOverlay(
        NPathOverlay(
          id: _routeOverlayId,
          coords: _routeCoordinates,
          color: AppColors.primary,
          width: 5,
          outlineWidth: 2,
          outlineColor: Colors.white,
          patternInterval: 30,
        ),
      );
      debugPrint('경로 오버레이 추가됨');

      // 출발점 마커 추가
      _mapController!.addOverlay(
        NMarker(
          id: _startPointMarkerId,
          position: _routeCoordinates.first,
          caption: const NOverlayCaption(
            text: '출발점',
            textSize: 12,
          ),
        ),
      );
      debugPrint('출발점 마커 추가됨');

      // 도착점 마커 추가
      _mapController!.addOverlay(
        NMarker(
          id: _endPointMarkerId,
          position: _routeCoordinates.last,
          caption: const NOverlayCaption(
            text: '도착점',
            textSize: 12,
          ),
        ),
      );
      debugPrint('도착점 마커 추가됨');

      // 현재 위치 오버레이 초기화 및 업데이트
      await _updateLocationOverlay();
      debugPrint('현재 위치 오버레이 업데이트됨');

      // 바운드 계산을 백그라운드에서 수행
      final bounds = await compute(
          _BackgroundTask.calculateRouteBounds, _routeCoordinates);

      // 계산된 바운드로 카메라 이동
      _mapController!.updateCamera(
        NCameraUpdate.fitBounds(
          NLatLngBounds(
            southWest: NLatLng(bounds['minLat']!, bounds['minLng']!),
            northEast: NLatLng(bounds['maxLat']!, bounds['maxLng']!),
          ),
          padding: const EdgeInsets.all(50),
        ),
      );
      debugPrint('카메라 위치 업데이트됨');

      // 위치 추적 모드 활성화
      _enableLocationTracking();
    } catch (e) {
      debugPrint('등산로 경로 표시 중 오류 발생: $e');
    }
  }

  // 선택된 등산로 데이터 로딩
  void _loadSelectedRouteData() {
    final appState = Provider.of<AppState>(context, listen: false);
    final selectedRoute = appState.selectedRoute;

    debugPrint('선택된 등산로: ${selectedRoute?.name}');

    if (selectedRoute != null && selectedRoute.path.isNotEmpty) {
      debugPrint('경로 데이터 있음: ${selectedRoute.path.length} 포인트');
      try {
        // 경로 데이터 변환
        final pathPoints = selectedRoute.path
            .map((coord) {
              final lat = coord['latitude'];
              final lng = coord['longitude'];

              if (lat == null || lng == null) {
                debugPrint('좌표 데이터 오류: $coord');
                return null;
              }

              return NLatLng(lat, lng);
            })
            .where((point) => point != null)
            .cast<NLatLng>()
            .toList();

        if (pathPoints.isEmpty) {
          debugPrint('변환된 경로 데이터가 없습니다.');
          _setDefaultRoute();
          return;
        }

        // 백그라운드에서 경로 최적화 수행
        compute(_BackgroundTask.optimizeRoute, pathPoints)
            .then((optimizedPath) {
          if (!mounted) return;

          setState(() {
            _routeCoordinates = optimizedPath;

            // 거리와 시간 정보 설정
            _distance = selectedRoute.distance;
            _elapsedMinutes = selectedRoute.estimatedTime;

            // 시작 위치 설정 (경로의 첫 번째 포인트)
            if (_routeCoordinates.isNotEmpty) {
              _currentLat = _routeCoordinates.first.latitude;
              _currentLng = _routeCoordinates.first.longitude;
            }

            debugPrint('경로 데이터 로드 완료: $_distance km, $_elapsedMinutes 분');
          });
        });
      } catch (e) {
        debugPrint('경로 데이터 처리 중 오류 발생: $e');
        _setDefaultRoute();
      }
    } else {
      debugPrint('선택된 경로가 없거나 경로 데이터가 비어있습니다.');
      _setDefaultRoute();
    }
  }

  // 기본 경로 설정 (데이터가 없을 경우)
  void _setDefaultRoute() {
    debugPrint('기본 경로 데이터를 사용합니다.');
    setState(() {
      _routeCoordinates = [
        NLatLng(37.5665, 126.9780),
        NLatLng(37.5690, 126.9800),
        NLatLng(37.5720, 126.9830),
        NLatLng(37.5760, 126.9876),
      ];
    });
  }

  // 위치 권한 확인 및 요청
  Future<void> _checkLocationPermission() async {
    // 위치 서비스 활성화 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return; // 비동기 작업 후 mounted 체크

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.')),
      );
      return;
    }

    // 위치 권한 확인
    PermissionStatus status = await Permission.locationWhenInUse.status;
    if (!mounted) return; // 비동기 작업 후 mounted 체크

    if (status.isDenied) {
      // 권한 요청
      status = await Permission.locationWhenInUse.request();
      if (!mounted) return; // 비동기 작업 후 mounted 체크
    }

    if (status.isPermanentlyDenied) {
      // 사용자가 영구적으로 거부한 경우 앱 설정으로 이동 안내
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.'),
          action: SnackBarAction(
            label: '설정',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    if (status.isGranted) {
      _startLocationTracking();
    }
  }

  // 실시간 위치 추적 시작
  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10미터마다 업데이트
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      // 백그라운드에서 거리 계산
      compute(_BackgroundTask.calculateDistance, {
        'lat1': _currentLat,
        'lng1': _currentLng,
        'lat2': position.latitude,
        'lng2': position.longitude,
      }).then((distance) {
        if (!mounted) return;

        // 현재 위치와 충분히 차이가 있을 때만 업데이트 (5미터 이상)
        if (distance > 5.0) {
          setState(() {
            _currentLat = position.latitude;
            _currentLng = position.longitude;
            _currentAltitude = position.altitude;

            // 사용자 이동 경로에 현재 위치 추가
            final newPoint = NLatLng(_currentLat, _currentLng);
            _userPath.add(newPoint);

            // 이동 거리 누적 (테스트용 코드 대체)
            // _distance += distance / 1000; // 미터 -> 킬로미터
          });

          // 경로 업데이트와 베어링은 UI 상태 변경 후에 수행
          _updateUserPathOverlay();
          _updateBearing();

          // 네비게이션 모드일 경우 카메라 위치 업데이트
          if (_isNavigationMode && _mapController != null) {
            _mapController!.updateCamera(
              NCameraUpdate.withParams(
                target: NLatLng(_currentLat, _currentLng),
                zoom: 17,
                bearing: _locationBearing,
                tilt: 50,
              ),
            );
          }
        }
      });
    });

    // 위치 추적 모드 활성화 (지도 컨트롤러가 있는 경우)
    if (_mapController != null) {
      _enableLocationTracking();
    }
  }

  // 위치 추적 모드 활성화
  void _enableLocationTracking() {
    if (_mapController == null) return;

    try {
      // 위치 추적 모드 설정
      _mapController!.setLocationTrackingMode(NLocationTrackingMode.follow);
      debugPrint('위치 추적 모드가 활성화되었습니다.');
    } catch (e) {
      debugPrint('위치 추적 모드 설정 중 오류 발생: $e');
    }
  }

  // 사용자 이동 경로 오버레이 업데이트
  void _updateUserPathOverlay() {
    if (_mapController == null || _userPath.length < 2) return;

    try {
      // 백그라운드에서 사용자 경로 최적화
      compute<List<NLatLng>, List<NLatLng>>((userPath) {
        // 너무 많은 포인트가 있는 경우 마지막 N개만 반환
        return userPath.length > 200
            ? userPath.sublist(userPath.length - 200)
            : userPath;
      }, _userPath)
          .then((userPathToShow) {
        if (!mounted || _mapController == null) return;

        // 새 사용자 경로 오버레이 추가 (기존 ID가 있으면 자동으로 교체됨)
        _mapController!.addOverlay(
          NPathOverlay(
            id: _userPathOverlayId,
            coords: userPathToShow,
            color: Colors.blue.withAlpha(150), // 반투명 파란색으로 변경
            width: 4, // 너비 감소
            outlineWidth: 1, // 테두리 너비 감소
            outlineColor: Colors.white,
            patternInterval: 0, // 패턴 제거
          ),
        );
        debugPrint('사용자 경로 오버레이 업데이트됨: ${userPathToShow.length} 포인트');
      });
    } catch (e) {
      debugPrint('사용자 경로 오버레이 업데이트 중 오류: $e');
    }
  }

  // 위치 오버레이 업데이트
  Future<void> _updateLocationOverlay() async {
    if (_mapController == null) {
      debugPrint('지도 컨트롤러가 초기화되지 않았습니다.');
      return;
    }

    try {
      // 위치 추적 모드를 사용하여 자동으로 위치 표시
      _mapController!.setLocationTrackingMode(NLocationTrackingMode.follow);
      debugPrint('위치 오버레이가 업데이트되었습니다: $_currentLat, $_currentLng');
    } catch (e) {
      debugPrint('위치 오버레이 업데이트 중 오류 발생: $e');
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
                mapType: NMapType.terrain,
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
                  NLayerGroup.traffic,
                  NLayerGroup.cadastral,
                ],
              ),
              onMapReady: (controller) {
                debugPrint('네이버 지도가 준비되었습니다.');
                _mapController = controller;

                // 지도가 준비되면 경로 표시 (지연 시간 증가)
                Future.delayed(const Duration(milliseconds: 500), () async {
                  if (mounted) {
                    debugPrint('지도에 경로 표시 시도...');
                    await _showRouteOnMap();

                    // 네비게이션 모드 기본 설정 - 현재 위치 중심, 3D 기울기 적용
                    if (_isNavigationMode && mounted) {
                      debugPrint('네비게이션 모드 카메라 설정...');
                      _mapController!.updateCamera(
                        NCameraUpdate.withParams(
                          target: NLatLng(_currentLat, _currentLng),
                          zoom: 17,
                          bearing: 0,
                          tilt: 50,
                        ),
                      );
                    }
                  }
                });
              },
              onMapTapped: (point, latLng) {
                debugPrint(
                    '지도가 탭되었습니다: ${latLng.latitude}, ${latLng.longitude}');
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

        // 위치 추적 모드 설정
        _mapController!.setLocationTrackingMode(NLocationTrackingMode.follow);
      } else {
        // 네비게이션 모드 비활성화: 전체 경로 조망
        // 백그라운드에서 바운드 계산 후 카메라 이동
        compute(_BackgroundTask.calculateRouteBounds, _routeCoordinates)
            .then((bounds) {
          if (!mounted) return;

          _mapController!.updateCamera(
            NCameraUpdate.fitBounds(
              NLatLngBounds(
                southWest: NLatLng(bounds['minLat']!, bounds['minLng']!),
                northEast: NLatLng(bounds['maxLat']!, bounds['maxLng']!),
              ),
              padding: const EdgeInsets.all(50),
            ),
          );
          _mapController!.updateCamera(
            NCameraUpdate.withParams(tilt: 0),
          );

          // 위치 추적 모드 해제
          _mapController!
              .setLocationTrackingMode(NLocationTrackingMode.noFollow);
        });
      }
    }
  }
}
