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
import 'package:flutter_compass/flutter_compass.dart';

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

  // 나침반 센서 구독
  StreamSubscription<CompassEvent>? _compassStream;

  // 디바이스 방향 (나침반 방향)
  double _deviceHeading = 0.0;

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

  // 네비게이션 모드 여부 (기본값을 true로 변경)
  bool _isNavigationMode = true;
  bool _isToggling = false; // 네비게이션 모드 토글 중인지 여부

  // 바텀 시트 컨트롤러
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // 위치 마커 유지를 위한 타이머
  Timer? _locationOverlayTimer;

  // 위치 버튼 클릭 처리를 위한 변수
  bool _isLocationButtonProcessing = false;
  int _pendingLocationClicks = 0; // 대기 중인 위치 버튼 클릭 수

  @override
  void initState() {
    super.initState();

    // AppState에서 데이터 가져오기
    final appState = Provider.of<AppState>(context, listen: false);

    // 이미 저장된 데이터가 있으면 가져오기
    if (appState.isTracking) {
      _userPath.addAll(appState.userPath);

      if (appState.routeCoordinates.isNotEmpty) {
        _routeCoordinates = appState.routeCoordinates;
      }

      _currentLat = appState.currentLat;
      _currentLng = appState.currentLng;
      _currentAltitude = appState.currentAltitude;
      _elapsedSeconds = appState.elapsedSeconds;
      _elapsedMinutes = appState.elapsedMinutes;
      _distance = appState.distance;
      _maxHeartRate = appState.maxHeartRate;
      _avgHeartRate = appState.avgHeartRate;
      _isNavigationMode = appState.isNavigationMode;
      _deviceHeading = appState.deviceHeading;

      debugPrint('기존 트래킹 데이터 불러옴: $_elapsedMinutes분 $_elapsedSeconds초');
    } else {
      _loadSelectedRouteData();
      debugPrint('새로운 트래킹 데이터 로드');
    }

    // 공통 초기화
    _checkLocationPermission();
    _startTracking();
    _startCompassTracking(); // 나침반 센서 구독 시작

    // 초기 경로 데이터 설정 (아직 없는 경우)
    if (_userPath.isEmpty) {
      _userPath.add(NLatLng(_currentLat, _currentLng));
    }

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
    _compassStream?.cancel(); // 나침반 센서 구독 해제
    _locationOverlayTimer?.cancel();
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

        // AppState 업데이트
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.updateTrackingData(elapsedSeconds: _elapsedSeconds);
        }
      }
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

    // AppState 업데이트
    if (mounted) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.updateTrackingData(
          maxHeartRate: _maxHeartRate, avgHeartRate: _avgHeartRate);
    }
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
      debugPrint('등산로 경로 데이터가 없습니다. AppState에서 데이터 확인 시도');

      // AppState에서 경로 데이터 직접 가져오기
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.routeCoordinates.isNotEmpty) {
        debugPrint(
            'AppState에서 경로 데이터 찾음: ${appState.routeCoordinates.length} 포인트');
        setState(() {
          _routeCoordinates = appState.routeCoordinates;
        });
      } else {
        debugPrint('AppState에도 경로 데이터가 없습니다. 기본 경로를 설정합니다.');
        _setDefaultRoute();
        // 경로 데이터가 설정된 후 다시 호출
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _showRouteOnMap();
        });
        return;
      }
    }

    try {
      debugPrint('지도에 경로 표시 시작: ${_routeCoordinates.length} 포인트');

      // 경로 좌표 유효성 검사
      debugPrint(
          '첫 번째 좌표: ${_routeCoordinates.first.latitude}, ${_routeCoordinates.first.longitude}');
      debugPrint(
          '마지막 좌표: ${_routeCoordinates.last.latitude}, ${_routeCoordinates.last.longitude}');

      // (1) 기존 오버레이 모두 삭제 (위치 오버레이 제외)
      _mapController!.clearOverlays(type: NOverlayType.pathOverlay);
      _mapController!.clearOverlays(type: NOverlayType.marker);

      // 내 위치 오버레이는 별도로 유지
      final locOverlay = _mapController!.getLocationOverlay();
      locOverlay.setIconSize(const Size.square(24));
      locOverlay.setCircleRadius(0);
      locOverlay.setIsVisible(true);

      debugPrint('기존 경로 오버레이 삭제됨');

      // (2) 경로 오버레이·마커 그리기
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

      // 네비게이션 모드에 따라 카메라 설정 분기
      if (_isNavigationMode) {
        // 네비게이션 모드: 현재 위치 중심으로 카메라 설정
        _mapController!.updateCamera(
          NCameraUpdate.withParams(
            target: NLatLng(_currentLat, _currentLng),
            zoom: 17,
            tilt: 50,
          ),
        );
        debugPrint('네비게이션 모드로 카메라 설정됨');
      } else {
        // 전체 지도 모드: 경로 전체가 보이도록 카메라 설정
        try {
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
          debugPrint('전체 경로가 보이도록 카메라 설정됨');
        } catch (e) {
          debugPrint('바운드 계산 오류: $e');
          // 오류 발생 시 현재 위치로 카메라 이동
          _mapController!.updateCamera(
            NCameraUpdate.withParams(
              target: NLatLng(_currentLat, _currentLng),
              zoom: 15,
            ),
          );
        }
      }
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

          // AppState에도 경로 데이터 업데이트
          final appState = Provider.of<AppState>(context, listen: false);
          appState.updateTrackingData(routeCoordinates: optimizedPath);
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

      // 시작 위치 업데이트
      if (_routeCoordinates.isNotEmpty) {
        _currentLat = _routeCoordinates.first.latitude;
        _currentLng = _routeCoordinates.first.longitude;
      }
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

          // 네비게이션 모드일 경우 카메라 위치 업데이트
          if (_mapController != null) {
            // 네비게이션 모드에서만 방향과 틸트를 적용
            if (_isNavigationMode) {
              _mapController!.updateCamera(
                NCameraUpdate.withParams(
                  target: NLatLng(_currentLat, _currentLng),
                  zoom: 17,
                  tilt: 50,
                ),
              );
            } else {
              // 일반 모드에서는 위치만 업데이트 (방향과 틸트 없음)
              _mapController!.updateCamera(
                NCameraUpdate.withParams(
                  target: NLatLng(_currentLat, _currentLng),
                  zoom: 15,
                ),
              );
            }
          }

          // AppState 업데이트
          if (mounted) {
            final appState = Provider.of<AppState>(context, listen: false);
            appState.updateTrackingData(
                currentLat: _currentLat,
                currentLng: _currentLng,
                currentAltitude: _currentAltitude,
                newUserPathPoint: NLatLng(_currentLat, _currentLng),
                deviceHeading: _deviceHeading);
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
    // 이 메서드는 초기 설정 시에만 사용하고, 이후에는 재호출하지 않습니다.
    // _startLocationTracking() 메서드에서만 호출
    if (_mapController == null) return;

    try {
      debugPrint('위치 추적 모드가 활성화되었습니다.');
    } catch (e) {
      debugPrint('위치 추적 모드 설정 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 네이버 지도 영역
          Container(
            padding: const EdgeInsets.only(bottom: 150),
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
                locationButtonEnable: false, // 기본 위치 버튼 비활성화
                contentPadding: const EdgeInsets.all(0),
                activeLayerGroups: [
                  NLayerGroup.mountain,
                  NLayerGroup.transit,
                  NLayerGroup.cadastral,
                ],
              ),
              onMapReady: (controller) async {
                debugPrint('네이버 지도가 준비되었습니다.');
                _mapController = controller;

                // 1) 위치 추적 모드 활성화
                await controller
                    .setLocationTrackingMode(NLocationTrackingMode.follow);

                // 2) 내 위치 오버레이 보이게 설정
                final locOverlay = controller.getLocationOverlay();
                locOverlay.setIconSize(const Size.square(24));
                locOverlay.setCircleRadius(0);
                locOverlay.setIsVisible(true);

                // 지도가 준비되면 경로 표시 (지연 시간 증가)
                Future.delayed(const Duration(milliseconds: 1000), () async {
                  if (mounted) {
                    debugPrint('지도에 경로 표시 시도... (1초 지연 후)');

                    // 경로 데이터가 비어있으면 데이터 로드 재시도
                    if (_routeCoordinates.isEmpty) {
                      debugPrint('경로 데이터가 비어있어 다시 로드합니다.');
                      _loadSelectedRouteData();
                      // 경로 데이터 로드 후 잠시 대기
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          debugPrint('경로 데이터 로드 후 지도에 표시 시도...');
                          _showRouteOnMap();
                        }
                      });
                    } else {
                      await _showRouteOnMap();
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

          // 커스텀 위치 버튼 (좌측 하단)
          _buildLocationButton(),

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
        onPressed: _isToggling ? null : _toggleNavigationMode, // 토글 중엔 비활성화
        mini: true,
        backgroundColor: _isNavigationMode
            ? AppColors.primary.withAlpha(_isToggling ? 125 : 255) // 토글 중엔 반투명
            : Colors.white.withAlpha(_isToggling ? 125 : 255),
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
  Future<void> _toggleNavigationMode() async {
    // 이미 토글 중이면 중복 실행 방지
    if (_isToggling) return;

    // 토글 시작
    setState(() {
      _isToggling = true;
    });

    try {
      // 모드 변경
      setState(() {
        _isNavigationMode = !_isNavigationMode;
      });

      // AppState 업데이트
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.updateTrackingData(isNavigationMode: _isNavigationMode);
      }

      if (_mapController != null) {
        if (_isNavigationMode) {
          debugPrint('네비게이션 모드 활성화');
          // 네비게이션 모드 활성화: 현재 위치 중심, 3D 기울기 적용
          // 현재 보고 있는 방향(디바이스 방향 또는 이동 방향) 적용
          await _mapController!.updateCamera(
            NCameraUpdate.withParams(
              target: NLatLng(_currentLat, _currentLng),
              zoom: 17.0,
              bearing: _deviceHeading,
              tilt: 50.0,
            ),
          );
        } else {
          // 네비게이션 모드 비활성화: 전체 경로 조망
          final bounds = await compute(
              _BackgroundTask.calculateRouteBounds, _routeCoordinates);

          if (!mounted) return;

          await _mapController!.updateCamera(
            NCameraUpdate.fitBounds(
              NLatLngBounds(
                southWest: NLatLng(bounds['minLat']!, bounds['minLng']!),
                northEast: NLatLng(bounds['maxLat']!, bounds['maxLng']!),
              ),
              padding: const EdgeInsets.all(50),
            ),
          );

          await _mapController!.updateCamera(
            NCameraUpdate.withParams(tilt: 0, bearing: 0),
          );
          debugPrint('전체 지도 모드 카메라 설정 완료');
        }
      }
    } catch (e) {
      debugPrint('네비게이션 모드 전환 오류: $e');
    } finally {
      // 토글 완료
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  // 커스텀 위치 버튼 위젯
  Widget _buildLocationButton() {
    return Positioned(
      left: 11,
      bottom: 190, // 바텀 시트 위에 위치하도록 조정
      child: FloatingActionButton(
        onPressed: _onLocationButtonPressed,
        mini: true,
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.my_location,
          color: Colors.black54,
        ),
      ),
    );
  }

  // 위치 버튼 클릭 시 처리
  void _onLocationButtonPressed() {
    if (_mapController == null) return;

    // 이전 대기 중인 클릭 취소하고 새로운 클릭만 처리
    _pendingLocationClicks = 1;

    // 이미 처리 중이면 함수 종료 (대기 큐에 추가된 상태)
    if (_isLocationButtonProcessing) {
      debugPrint('위치 버튼: 이미 처리 중, 마지막 클릭만 처리됩니다');
      return;
    }

    // 처리 시작
    _isLocationButtonProcessing = true;
    _moveToCurrentLocation();
  }

  // 현재 위치로 카메라 이동
  void _moveToCurrentLocation() {
    if (_pendingLocationClicks <= 0) {
      _isLocationButtonProcessing = false;
      return;
    }

    try {
      // debugPrint('카메라를 현재 위치로 이동합니다: $_currentLat, $_currentLng');

      // 카메라를 현재 위치로 이동
      _mapController!
          .updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(_currentLat, _currentLng),
          zoom: 17,
          // tilt: 50,
        ),
      )
          .then((_) {
        // 이동이 완료되면 카운터 감소
        _pendingLocationClicks--;

        // 모든 클릭 처리 완료
        _isLocationButtonProcessing = false;
      }).catchError((error) {
        debugPrint('카메라 업데이트 오류: $error');
        // 오류 발생 시 처리 완료
        _pendingLocationClicks = 0;
        _isLocationButtonProcessing = false;
      });
    } catch (e) {
      debugPrint('위치 버튼 처리 중 오류: $e');
      // 오류 발생 시 처리 완료
      _pendingLocationClicks = 0;
      _isLocationButtonProcessing = false;
    }
  }

  // 나침반 센서 구독 시작
  void _startCompassTracking() {
    // 나침반 센서가 사용 가능한지 확인
    if (FlutterCompass.events != null) {
      _compassStream = FlutterCompass.events!.listen((CompassEvent event) {
        if (!mounted) return;

        // 유효한 방향 데이터가 있을 때만 업데이트
        if (event.heading != null) {
          setState(() {
            _deviceHeading = event.heading!;
            // debugPrint('디바이스 방향: $_deviceHeading°');
          });

          // 네비게이션 모드이고 디바이스 방향을 따라가는 설정인 경우 카메라 회전
          if (_isNavigationMode && _mapController != null) {
            // 네비게이션 모드이고 디바이스 방향을 따라가는 설정인 경우 카메라 회전
          }
        }
      });
      debugPrint('나침반 센서 구독 시작');
    } else {
      debugPrint('이 기기에서는 나침반 센서를 사용할 수 없습니다.');
    }
  }
}
