// live_tracking_screen.dart: 실시간 트래킹 화면
// - 네이버 지도 기반 실시간 위치 및 등산로 표시
// - 현재 정보 (고도, 이동 거리, 소요 시간 등) 표시
// - 트래킹 종료 기능

import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../models/app_state.dart';
import '../../utils/app_colors.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../models/mode_data.dart';
import '../../services/mode_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

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

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with WidgetsBindingObserver {
  // WidgetsBindingObserver mixin 추가
  NaverMapController? _mapController;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _elapsedMinutes = 0;
  double _currentAltitude = 120;
  double _distance = 3.7;

  // 토스트 메시지 관련 변수 추가
  bool _showToast = false;
  String _toastMessage = '';
  Color _toastColor = Colors.green;
  Timer? _toastTimer;

  // 위치 초기화 및 거리 계산 관련 변수
  bool _isFirstLocationUpdate = true;
  DateTime? _lastLocationUpdateTime;
  static const double _maxReasonableSpeed = 5.0; // 최대 합리적 속도 (m/s), 약 18km/h

  // WatchConnectivity 인스턴스 추가
  final WatchConnectivity _watch = WatchConnectivity();
  bool _isWatchPaired = false;
  bool _isCheckingWatch = false;
  String _watchStatus = '워치 연결 확인이 필요합니다';
  int _steps = 0; // 걸음 수 변수 추가

  // 현재 위치 (처음 지도 로드 위치)
  double _currentLat = 37.5665;
  double _currentLng = 126.9780;

  // 위치 트래킹 구독
  StreamSubscription<Position>? _positionStream;

  // 나침반 센서 구독
  StreamSubscription<CompassEvent>? _compassStream;

  // 디바이스 방향 (나침반 방향)
  double _deviceHeading = 0.0;
  double _lastAppliedHeading = 0.0; // 마지막으로 적용된 방향
  static const double _minHeadingChangeForUpdate =
      10.0; // 업데이트를 위한 최소 방향 변화 (도)

  // 현재 심박수
  int _currentHeartRate = 0; // _avgHeartRate에서 _currentHeartRate로 변경 및 초기값 설정

  // 경쟁 모드 데이터 (테스트용)
  Map<String, dynamic> _competitorData = {
    'name': '내가',
    'distance': 4.1,
    'time': 47,
    'isAhead': true, // 경쟁자가 앞서는지 여부
  };

  // 등산로 경로 데이터
  List<NLatLng> _routeCoordinates = [];

  // 사용자 이동 경로 기록
  final List<NLatLng> _userPath = [];

  // 페이지 상태
  final bool _isPaused = false;
  bool _isSheetExpanded = false;

  // 남은 거리 및 예상 시간 계산용 변수
  double _remainingDistance = 0.0;
  int _estimatedRemainingSeconds = 0;
  double _averageSpeedMetersPerSecond = 1.0; // 초당 평균 이동 속도 (미터)
  double _completedPercentage = 0.0; // 완료된 경로 비율

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

  // 카메라 이동 중인지 확인하는 플래그
  bool _isMovingToCurrentLocation = false;

  // 목적지 도착 관련 변수
  bool _isDestinationReached = false;
  final double _destinationRadius = 50.0; // 도착 감지 반경 (미터)

  // 이전 기록 비교 관련 변수
  bool _isAheadOfRecord = false;
  double _distanceDifference = 0.0;
  double _pastDistanceAtCurrentTime = 0.0;
  double _currentTotalDistance = 0.0;

  // 현재 속도 관련 변수 추가
  double _currentSpeed = 0.0; // 현재 속도 (km/h)
  DateTime? _lastSpeedUpdateTime; // 마지막 속도 업데이트 시간

  // 5초 전 좌표 및 시간 (속도 계산용)
  double _speedCalcPreviousLat = 0.0;
  double _speedCalcPreviousLng = 0.0;
  DateTime? _speedCalcPreviousTime;
  static const int _speedCalcIntervalSeconds = 5; // 속도 계산에 사용할 시간 간격 (초)

  // 워치 알림 상태
  bool _hasNotifiedWatchForAhead = false;
  bool _hasNotifiedWatchForBehind = false;
  bool _hasNotifiedWatchForDestination = false;

  // ModeData 객체 저장 (이전 기록 및 경쟁자 정보 포함)
  ModeData? _modeData;

  // 등산 기록 데이터 저장을 위한 변수들
  final List<Map<String, dynamic>> _trackingRecords = [];
  DateTime? _lastRecordTime;
  final int _recordIntervalSeconds = 1800; // 30분마다 records에 기록 추가
  Timer? _recordTimer;
  final bool _isSavingEnabled = true; // 기록 저장 여부 (기본값: true)

  // 앱 생명주기 상태 저장을 위한 변수
  AppLifecycleState? _currentLifecycleState;

  @override
  void initState() {
    super.initState();

    // 블루투스 권한 요청
    _requestBluetoothPermissions();

    // 워치 연결 상태 초기 확인
    _checkWatchConnection();

    // (1) 워치 메시지 수신 리스너 등록
    _watch.messageStream.listen((Map<String, dynamic> message) {
      debugPrint('워치 메시지 수신: $message');
      String path = message['path'];
      switch (path) {
        case '/SENSOR_DATA':
          _currentHeartRate = message['heartRate'];
          _steps = message['steps'];
          break;
        case '/STOP_TRACKING_CONFIRM': // 새로운 case 추가
          debugPrint('워치로부터 /STOP_TRACKING_CONFIRM 메시지 수신');
          // 현재 화면 상태와 관계없이 등산 종료 및 기록 저장
          _finishTracking(true);
          break;
        case '/STOP_TRACKING_CANCEL': // 새로운 case 추가
          debugPrint('워치로부터 /STOP_TRACKING_CANCEL 메시지 수신');
          // 현재 화면 상태와 관계없이 등산 종료 (기록 저장 안 함)
          _finishTracking(false);
          break;
      }
    }, onError: (err) {
      debugPrint('메시지 수신 오류: $err');
    });

    // AppState에서 데이터 가져오기
    final appState = Provider.of<AppState>(context, listen: false);

    // 선택된 모드 정보 가져오기
    _loadModeData();

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
      _isNavigationMode = appState.isNavigationMode;
      _deviceHeading = appState.deviceHeading;

      // 남은 거리와 예상 시간 초기화
      _calculateRemainingDistanceAndTime();

      debugPrint('기존 트래킹 데이터 불러옴: $_elapsedMinutes분 $_elapsedSeconds초');
    } else {
      _loadSelectedRouteData();
      debugPrint('새로운 트래킹 데이터 로드');
    }

    // 공통 초기화
    _checkLocationPermission();
    _startTracking();
    _startCompassTracking(); // 나침반 센서 구독 시작
    _startTrackingRecords(); // 등산 기록 저장 시작

    // 초기 경로 데이터 설정 (아직 없는 경우)
    if (_userPath.isEmpty) {
      _userPath.add(NLatLng(_currentLat, _currentLng));
    }

    // 시트 컨트롤러 리스너 설정
    _sheetController.addListener(_onSheetChanged);

    // 앱 생명주기 옵저버 등록
    WidgetsBinding.instance.addObserver(this);
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
    _recordTimer?.cancel(); // 기록 타이머 해제
    _toastTimer?.cancel(); // 토스트 타이머 해제
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    _mapController = null;

    // 앱 생명주기 옵저버 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 앱 생명주기 변경 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    setState(() {
      _currentLifecycleState = state;
    });
    debugPrint('App lifecycle state changed to: $state');
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

        // 현재 이동 거리 계산 (매 초마다)
        await _calculateTotalDistance();

        // 남은 거리와 예상 시간 계산 (매 초마다 실시간 업데이트)
        _calculateRemainingDistanceAndTime();

        // 이전 기록과 현재 기록 비교
        if (_modeData?.opponent != null) {
          // 5초마다 내부 계산 업데이트 (UI 갱신용)
          if (_elapsedSeconds % 5 == 0) {
            await _compareWithPastRecord(sendNotification: false);
          }

          // 30분(1800초)마다 워치 알림 전송
          if (_elapsedSeconds % 1800 == 0 && _elapsedSeconds > 0) {
            await _compareWithPastRecord(sendNotification: true);
            debugPrint('30분 주기 워치 알림 전송 시간: $_elapsedMinutes분');
          }
        }

        // 목적지 도착 감지 (3초마다)
        if (_elapsedSeconds % 3 == 0) {
          _checkDestinationReached();
        }

        // AppState 업데이트
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.updateTrackingData(elapsedSeconds: _elapsedSeconds);
        }

        // 워치에 도착 알림 전송
        if (!_hasNotifiedWatchForDestination) {
          _notifyWatch('destination');
          _hasNotifiedWatchForDestination = true;

          // 사용자의 요청: 앱이 백그라운드 상태이고, 목적지에 도착했고, 워치에 연동되어 있으면 메시지 전송
          if (_isWatchPaired &&
              _currentLifecycleState == AppLifecycleState.paused) {
            try {
              _watch.sendMessage({
                'path': '/REACHED',
              });
              debugPrint('백그라운드에서 목적지 도착 메시지 워치로 전송됨');
            } catch (e) {
              debugPrint('백그라운드 워치 메시지(/REACHED) 전송 실패: $e');
            }
          }
        }
      }
    });
  }

  // 심박수 업데이트 (실제 데이터 사용 또는 목데이터 백업)
  void _updateHeartRate() {
    // 워치에서 최근 5초 이내에 받은 심박수 데이터가 있는지 확인
    // 없으면 목데이터 사용 (테스트용)
    bool useRealData = _isWatchPaired; // 실제 워치 연동 시 true로 변경 가정

    if (useRealData) {
      // 실제 데이터 사용 로직 (예: _currentHeartRate가 워치에서 직접 업데이트된다고 가정)
      // 이 부분은 워치 연동 방식에 따라 달라짐
      debugPrint('현재 심박수 (워치): $_currentHeartRate');
    } else {
      // 목데이터 사용 (실제 워치 연동 전 테스트용)
      // _currentHeartRate 값을 직접 업데이트 (예: 80 ~ 139 사이의 랜덤 값)
      _currentHeartRate = 0;
      debugPrint('현재 심박수 (목데이터): $_currentHeartRate');
    }
  }

  // 포맷팅된 시간 문자열
  String get _formattedTime {
    final minutes = _elapsedMinutes;
    final seconds = _elapsedSeconds % 60;

    // 60분 이상일 경우 시간, 분, 초로 표시
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '$hours시 $mins분 $seconds초';
    } else {
      return '$minutes분 $seconds초';
    }
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
      locOverlay.setIconSize(const Size(64, 64)); // 크기를 더 크게 설정
      locOverlay.setCircleRadius(10); // 원 반경 설정

      // 3) 커스텀 위치 오버레이 아이콘 설정 - 화살표 모양 마커 사용
      try {
        // 화살표 모양의 위치 아이콘 설정 (기본적으로 북쪽을 향하는 화살표)
        final NOverlayImage arrowIcon =
            NOverlayImage.fromAssetImage('lib/assets/images/up-arrow.png');
        locOverlay.setIcon(arrowIcon);

        // 베어링 값 직접 설정 (현재 방향으로)
        locOverlay.setBearing(_deviceHeading);

        // 내 위치 오버레이 색상 설정
        locOverlay.setCircleColor(AppColors.primary.withAlpha(51));
        locOverlay.setCircleOutlineColor(AppColors.primary);

        // 위치 추적 모드 설정 (face 모드로 설정)
        _mapController!.setLocationTrackingMode(NLocationTrackingMode.face);
      } catch (e) {
        debugPrint('위치 오버레이 아이콘 설정 오류: $e');
      }

      // 위치 오버레이를 보이게 설정하고 주기적으로 확인
      locOverlay.setIsVisible(true);

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
      // 현재 위치 기록
      final now = DateTime.now();
      final double newLat = position.latitude;
      final double newLng = position.longitude;

      // 5초 전 좌표가 없거나 첫 위치 업데이트인 경우 초기화
      if (_speedCalcPreviousTime == null ||
          _speedCalcPreviousLat == 0.0 ||
          _speedCalcPreviousLng == 0.0) {
        _speedCalcPreviousLat = newLat;
        _speedCalcPreviousLng = newLng;
        _speedCalcPreviousTime = now;
      }

      // 5초 이상 경과했는지 확인
      final timeSinceLastSpeedCalc = _speedCalcPreviousTime != null
          ? now.difference(_speedCalcPreviousTime!).inSeconds
          : 0;

      // 5초 이상 경과한 경우 속도 계산
      if (timeSinceLastSpeedCalc >= _speedCalcIntervalSeconds) {
        // 5초 전 좌표와 현재 좌표 사이의 거리 계산
        compute(_BackgroundTask.calculateDistance, {
          'lat1': _speedCalcPreviousLat,
          'lng1': _speedCalcPreviousLng,
          'lat2': newLat,
          'lng2': newLng,
        }).then((distance) {
          if (!mounted) return;

          // 정확히 5초로 나누어 속도 계산
          final speedMeterPerSecond = distance / _speedCalcIntervalSeconds;

          // 속도 업데이트 (m/s -> km/h 변환)
          setState(() {
            _currentSpeed = speedMeterPerSecond * 3.6;
          });

          debugPrint(
              '5초 간격 속도 계산: ${_currentSpeed.toStringAsFixed(1)} km/h (거리: ${distance.toStringAsFixed(1)}m)');

          // 현재 좌표와 시간을 새로운 "5초 전 좌표와 시간"으로 업데이트
          _speedCalcPreviousLat = newLat;
          _speedCalcPreviousLng = newLng;
          _speedCalcPreviousTime = now;
        });
      }

      // 기존 거리 계산 코드 (경로 업데이트용)
      compute(_BackgroundTask.calculateDistance, {
        'lat1': _currentLat,
        'lng1': _currentLng,
        'lat2': newLat,
        'lng2': newLng,
      }).then((distance) {
        if (!mounted) return;

        bool shouldUpdatePath = true;

        // 비현실적인 위치 변화 필터링
        if (_isFirstLocationUpdate) {
          // 첫 번째 위치 업데이트는 거리 계산에서 제외하되, 위치는 업데이트
          shouldUpdatePath = false;
          _isFirstLocationUpdate = false;
          debugPrint('첫 번째 위치 업데이트: 거리 계산에서 제외');
        } else if (_lastLocationUpdateTime != null) {
          // 이전 위치 업데이트와의 시간 차이 계산 (밀리초)
          final timeDiff =
              now.difference(_lastLocationUpdateTime!).inMilliseconds;

          if (timeDiff > 0) {
            // 속도 계산 (미터/초) - 경로 업데이트 필터링용으로만 사용
            final instantSpeed = distance / (timeDiff / 1000);

            // 비현실적으로 빠른 속도(예: 18km/h 이상)로 움직인 경우 필터링
            if (instantSpeed > _maxReasonableSpeed) {
              shouldUpdatePath = false;
              debugPrint(
                  '비현실적인 위치 변화 감지: ${instantSpeed.toStringAsFixed(2)} m/s, 거리: ${distance.toStringAsFixed(2)}m');
            }
          }
        }

        // 위치 업데이트 시간 기록
        _lastLocationUpdateTime = now;

        // 현재 위치와 충분히 차이가 있을 때만 업데이트 (5미터 이상)
        if (distance > 5.0) {
          setState(() {
            _currentLat = newLat;
            _currentLng = newLng;
            _currentAltitude = position.altitude;

            // 사용자 이동 경로에 현재 위치 추가 (필터링 조건 적용)
            if (shouldUpdatePath) {
              final newPoint = NLatLng(_currentLat, _currentLng);
              _userPath.add(newPoint);
            }
          });

          // 네비게이션 모드일 경우에만 카메라 위치 업데이트
          // 전체 맵 보기 모드에서는 카메라를 자동으로 이동시키지 않음
          if (_mapController != null && _isNavigationMode) {
            _mapController!.updateCamera(
              NCameraUpdate.withParams(
                target: NLatLng(_currentLat, _currentLng),
                zoom: 17,
                tilt: 50,
              ),
            );
          }

          // AppState 업데이트
          if (mounted) {
            final appState = Provider.of<AppState>(context, listen: false);
            appState.updateTrackingData(
                currentLat: _currentLat,
                currentLng: _currentLng,
                currentAltitude: _currentAltitude,
                newUserPathPoint:
                    shouldUpdatePath ? NLatLng(_currentLat, _currentLng) : null,
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
      // 모드에 따라 다른 추적 모드 설정
      if (_isNavigationMode) {
        // 네비게이션 모드는 face 모드로 설정 (방향에 따라 회전)
        _mapController!.setLocationTrackingMode(NLocationTrackingMode.face);
        debugPrint('위치 추적 모드가 활성화되었습니다 (Face 모드)');
      } else {
        // 전체 맵 보기 모드는 NoFollow로 설정 (현재 위치는 표시하되 카메라는 이동하지 않음)
        _mapController!.setLocationTrackingMode(NLocationTrackingMode.noFollow);
        debugPrint('위치 추적 모드가 활성화되었습니다 (NoFollow 모드)');
      }
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
                await controller.setLocationTrackingMode(
                    NLocationTrackingMode.face); // face 모드로 변경

                // 2) 내 위치 오버레이 보이게 설정
                final locOverlay = controller.getLocationOverlay();

                // 내 위치 오버레이 아이콘 설정
                try {
                  debugPrint('위치 마커 설정 시작 (onMapReady)...');

                  // 아이콘 크기를 더 크게 설정 (64픽셀로 증가)
                  locOverlay.setIconSize(const Size(64, 64));

                  // 원의 반경을 설정 (완전히 사라지지 않게 약간의 크기 유지)
                  locOverlay.setCircleRadius(10);

                  // 화살표 모양의 위치 아이콘 설정 (기본적으로 북쪽을 향하는 화살표)
                  final NOverlayImage arrowIcon = NOverlayImage.fromAssetImage(
                      'lib/assets/images/up-arrow.png');
                  locOverlay.setIcon(arrowIcon);

                  // 베어링 값을 현재 디바이스 방향으로 설정
                  locOverlay.setBearing(_deviceHeading);

                  // 내 위치 오버레이 색상 설정
                  locOverlay.setCircleColor(AppColors.primary.withAlpha(51));
                  locOverlay.setCircleOutlineColor(AppColors.primary);

                  // 위치 추적 모드를 face로 설정 (아이콘이 항상 방향에 따라 회전하도록)
                  controller
                      .setLocationTrackingMode(NLocationTrackingMode.face);

                  debugPrint('위치 마커 설정 완료 (onMapReady)!');
                } catch (e) {
                  debugPrint('위치 오버레이 아이콘 설정 오류: $e');
                }

                // 위치 오버레이를 보이게 설정
                locOverlay.setIsVisible(true);
                debugPrint(
                    '위치 오버레이 표시 설정 (onMapReady): ${locOverlay.isVisible}');

                // 위치 오버레이 항상 보이게 하기 위한 타이머 설정
                _locationOverlayTimer =
                    Timer.periodic(const Duration(seconds: 1), (_) {
                  if (_mapController == null) return;

                  try {
                    // 정기적으로 위치 오버레이가 보이는지 확인하고 필요하면 다시 표시
                    final locOverlay = _mapController!.getLocationOverlay();
                    if (!locOverlay.isVisible) {
                      debugPrint('위치 오버레이가 보이지 않아 다시 표시합니다.');
                      locOverlay.setIsVisible(true);
                    }

                    // 모드에 따라 추적 모드 확인 및 재설정 (비동기 처리를 위해 별도 함수 호출)
                    if (!_isToggling) {
                      _checkAndUpdateTrackingMode();
                    }
                  } catch (e) {
                    debugPrint('위치 오버레이/추적 모드 확인 중 오류: $e');
                  }
                });

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

          // 워치 연결 버튼 추가 (좌측 상단)
          _buildWatchButton(),

          // 토스트 메시지 (지도 상단 가운데)
          if (_showToast)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _toastColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    _toastMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

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
    // 거리 변환: 미터를 km로 표시
    String distanceText = '';
    if (_remainingDistance < 1.0) {
      // 1km 미만은 미터로 표시
      distanceText = '${(_remainingDistance * 1000).toInt()}m';
    } else {
      // 1km 이상은 소수점 한 자리까지 km로 표시
      distanceText = '${_remainingDistance.toStringAsFixed(1)}km';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '남은 거리 : $distanceText',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '예상 남은 시간 : $_formattedRemainingTime',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 4), // 심박수 표시 전에 SizedBox 추가
        if (_isWatchPaired)
          Text(
            '현재 심박수 : $_currentHeartRate bpm',
            style: TextStyle(fontSize: 14),
          )
        else
          Text(
            '현재 심박수 : 워치와 연동해주세요',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        SizedBox(height: 4),
        Text(
          '현재 속도 : ${_currentSpeed.toStringAsFixed(1)} km/h',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  // 이전 기록과 현재 기록 비교
  Future<void> _compareWithPastRecord({bool sendNotification = false}) async {
    if (_modeData == null || _modeData?.opponent == null) return;

    try {
      // 현재 시간에 해당하는 이전 기록의 진행 거리 계산
      // (간단한 비례식으로 계산: 전체 시간 대비 현재 진행 시간의 비율로 계산)
      final totalTime = _modeData!.path.estimatedTime * 60; // 초 단위로 변환
      if (totalTime <= 0) return;

      // 현재 진행 시간이 전체 예상 시간보다 적을 때만 계산
      final currentElapsedTime = _elapsedMinutes * 60 + _elapsedSeconds;
      if (currentElapsedTime > totalTime) return;

      // 현재 시간에 해당하는 이전 기록의 예상 진행 거리
      _pastDistanceAtCurrentTime =
          (_modeData!.path.distance * currentElapsedTime) / totalTime;

      // 현재 총 이동 거리 계산 (이미 계산되어 있으므로 추가 계산 불필요)
      // 비동기 처리를 위해 await 추가
      await _calculateTotalDistance();

      // 현재 기록과 이전 기록 비교
      final oldAheadState = _isAheadOfRecord;
      _distanceDifference = _currentTotalDistance - _pastDistanceAtCurrentTime;
      _isAheadOfRecord = _distanceDifference > 0;

      debugPrint(
          '기록 비교: 현재=${_currentTotalDistance.toStringAsFixed(2)}km, 이전=${_pastDistanceAtCurrentTime.toStringAsFixed(2)}km, 차이=${_distanceDifference.toStringAsFixed(2)}km');

      // 앞서거나 뒤처진 상태가 변경되었을 때 또는 sendNotification이 true일 때(30분 주기) 워치에 알림 전송
      if ((_isAheadOfRecord != oldAheadState || sendNotification) &&
          _isWatchPaired) {
        // 기존 알림
        if (_isAheadOfRecord) {
          _notifyWatch('ahead');
          _hasNotifiedWatchForAhead = true;
          _hasNotifiedWatchForBehind = false;
        } else {
          _notifyWatch('behind');
          _hasNotifiedWatchForAhead = false;
          _hasNotifiedWatchForBehind = true;
        }

        // 사용자가 요청한 새로운 형식의 메시지 전송
        // 차이 값 계산 (미터 단위의 절대값)
        int differenceInMeters = (_distanceDifference.abs() * 1000).toInt();

        // 앞서는지 뒤처지는지에 따라 메시지 타입 결정
        String progressType = _isAheadOfRecord ? "FAST" : "SLOW";

        // 토스트 메시지 표시
        String toastMessage = _isAheadOfRecord
            ? "이전 기록보다 ${differenceInMeters}m 앞서고 있습니다!"
            : "이전 기록보다 ${differenceInMeters}m 뒤처지고 있습니다!";
        _showToastMessage(toastMessage, isAhead: _isAheadOfRecord);

        // 새로운 형식으로 워치에 메시지 전송
        try {
          await _watch.sendMessage({
            'path': '/PROGRESS',
            'type': progressType,
            'difference': differenceInMeters
          });

          debugPrint(
              '진행 상황 워치 메시지 전송 완료: $progressType, 차이: $differenceInMeters 미터');
        } catch (e) {
          debugPrint('진행 상황 워치 메시지 전송 실패: $e');
        }
      }

      // 상태 업데이트 (UI 갱신)
      if (mounted) {
        setState(() {
          // 경쟁자 데이터 업데이트
          _competitorData['isAhead'] = !_isAheadOfRecord; // 내가 앞서면 경쟁자는 뒤처짐
        });
      }
    } catch (e) {
      debugPrint('기록 비교 중 오류: $e');
    }
  }

  // 현재까지 이동한 총 거리 계산
  Future<void> _calculateTotalDistance() async {
    if (_userPath.length < 2) {
      setState(() {
        _currentTotalDistance = 0.0;
      });
      return;
    }

    try {
      double total = 0.0;

      // 처음부터 모든 경로 포인트 간의 거리를 계산
      // 최적화: 마지막 계산 이후 추가된 포인트만 계산
      if (_userPath.length > 2 && _currentTotalDistance > 0) {
        // 마지막 두 포인트 간의 거리만 계산해서 기존 총 거리에 더함
        final lastIndex = _userPath.length - 1;
        final params = {
          'lat1': _userPath[lastIndex - 1].latitude,
          'lng1': _userPath[lastIndex - 1].longitude,
          'lat2': _userPath[lastIndex].latitude,
          'lng2': _userPath[lastIndex].longitude,
        };
        final distance = _calculateDistanceSync(params);
        total = _currentTotalDistance * 1000 + distance; // 미터 단위로 변환 후 계산
        total = total / 1000; // 다시 킬로미터로 변환
      } else {
        // 처음 계산이거나 경로 포인트가 2개뿐인 경우, 모든 구간 계산
        for (int i = 1; i < _userPath.length; i++) {
          final params = {
            'lat1': _userPath[i - 1].latitude,
            'lng1': _userPath[i - 1].longitude,
            'lat2': _userPath[i].latitude,
            'lng2': _userPath[i].longitude,
          };
          final distance = _calculateDistanceSync(params);
          total += distance; // 미터 단위로 더함
        }
        total = total / 1000; // 미터를 킬로미터로 변환
      }

      if (_elapsedSeconds % 10 == 0) {
        debugPrint('현재 이동 거리: ${total.toStringAsFixed(2)}km'); // 수정된 부분
      }

      // UI 갱신
      if (mounted) {
        setState(() {
          _currentTotalDistance = total;
        });
      }
    } catch (e) {
      debugPrint('거리 계산 중 오류: $e');
    }
  }

  // 목적지 도착 감지
  void _checkDestinationReached() {
    if (_routeCoordinates.isEmpty || _isDestinationReached) return;

    try {
      // 목적지 좌표 (등산로의 마지막 지점)
      final destination = _routeCoordinates.last;

      // 현재 위치와 목적지 간의 거리 계산
      final params = {
        'lat1': _currentLat,
        'lng1': _currentLng,
        'lat2': destination.latitude,
        'lng2': destination.longitude,
      };

      compute(_BackgroundTask.calculateDistance, params).then((distance) {
        // 10초마다 현재 위치와 목적지 간 거리 로그 출력 (디버깅용)
        if (_elapsedSeconds % 10 == 0) {
          debugPrint(
              '목적지까지 남은 거리: ${distance.toStringAsFixed(2)}m, 도착 반경: ${_destinationRadius}m');
        }

        // 목적지 반경 내에 있는지 확인
        if (distance <= _destinationRadius && !_isDestinationReached) {
          setState(() {
            _isDestinationReached = true;
          });

          debugPrint('목적지 도착! 현재 위치와의 거리: ${distance.toStringAsFixed(2)}m');

          // 도착 알림 표시
          _showDestinationReachedDialog();

          // 워치에 도착 알림 전송
          if (!_hasNotifiedWatchForDestination) {
            _notifyWatch('destination');
            _hasNotifiedWatchForDestination = true;
          }
        }
      });
    } catch (e) {
      debugPrint('목적지 도착 감지 중 오류: $e');
    }
  }

  // 목적지 도착 다이얼로그
  void _showDestinationReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '등산 완료',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '목적지에 도착했습니다. 등산을 종료하시겠습니까?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // 취소해도 isDestinationReached는 true로 유지
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // 기록 저장 여부를 묻는 다이얼로그 표시
              _showSaveOptionDialog(context);
            },
            child: const Text(
              '종료',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 워치에 알림 전송 (목데이터 사용)
  void _notifyWatch(String status) {
    // 워치 알림 메시지 구성
    String notificationTitle = '등산 상태 알림';
    String notificationBody = '';

    try {
      switch (status) {
        case 'ahead':
          notificationTitle = '앞서고 있습니다';
          notificationBody =
              '이전 기록보다 ${_distanceDifference.abs().toStringAsFixed(2)}km 앞서고 있습니다.';
          debugPrint('[워치 알림 내용] $notificationBody');
          break;
        case 'behind':
          notificationTitle = '뒤처지고 있습니다';
          notificationBody =
              '이전 기록보다 ${_distanceDifference.abs().toStringAsFixed(2)}km 뒤처지고 있습니다.';
          debugPrint('[워치 알림 내용] $notificationBody');
          break;
        case 'destination':
          notificationTitle = '목적지 도착';
          notificationBody = '목적지에 도착했습니다. 등산을 종료하시겠습니까?';
          debugPrint('[워치 알림 내용] $notificationBody');
          break;
      }

      // 워치 앱에 알림 전송
      _sendWatchNotification(notificationTitle, notificationBody);
    } catch (e) {
      debugPrint('워치 알림 전송 중 오류: $e');
    }
  }

  // 워치 알림 전송 메소드 (watch_connectivity 라이브러리 사용)
  void _sendWatchNotification(String title, String messageBody) async {
    try {
      debugPrint('워치 알림 전송 시작: $title - $messageBody');

      // 워치가 연결되어 있는지 확인
      if (!await _watch.isPaired) {
        debugPrint('워치가 연결되어 있지 않습니다.');
        return;
      }

      // 워치에 전송할 알림 데이터
      final notificationData = {
        'type': 'notification',
        'title': title,
        'body': messageBody,
        'data': {
          'mountainName': _modeData?.mountain.name ?? '',
          'pathName': _modeData?.path.name ?? '',
          'elapsedTime': _formattedTime,
          'currentDistance': _currentTotalDistance.toStringAsFixed(2),
          'remainingDistance': _remainingDistance.toStringAsFixed(2),
        }
      };

      // watch_connectivity를 사용하여 워치에 메시지 전송
      await _watch.sendMessage(notificationData);

      debugPrint('워치 알림 전송 완료');
    } catch (e) {
      debugPrint('워치 알림 전송 실패: $e');
    }
  }

  // 확장된 정보 섹션 위젯
  Widget _buildExpandedInfoSection() {
    // 일반 모드 여부 확인 (opponent가 없으면 일반 모드)
    final bool isGeneralMode = _modeData?.opponent == null;

    // 경쟁자의 남은 시간 포맷팅 (일반 모드가 아닌 경우만)
    String competitorTimeFormatted = '';
    if (!isGeneralMode) {
      final compMinutes = _competitorData['time'] as int;
      if (compMinutes >= 60) {
        final hours = compMinutes ~/ 60;
        final mins = compMinutes % 60;
        competitorTimeFormatted = '$hours시 $mins분 00초';
      } else {
        competitorTimeFormatted = '$compMinutes분 00초';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),

        // 비교 모드 정보 (일반 모드가 아닐 때만 표시)
        if (!isGeneralMode) ...<Widget>[
          Row(
            children: <Widget>[
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
            _modeData?.opponent?.nickname ?? '이전 기록',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '(과거 기록과 비교 중)',
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
            '예상 남은 시간 : $competitorTimeFormatted',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 4),
          // Text(
          //   '최고 심박수 : ${_competitorData['maxHeartRate']} bpm',
          //   style: TextStyle(fontSize: 14),
          // ),
          // SizedBox(height: 4),
          // Text(
          //   '평균 심박수 : ${_competitorData['avgHeartRate']} bpm',
          //   style: TextStyle(fontSize: 14),
          // ),
        ]
        // 일반 모드 정보
        else ...<Widget>[
          Text(
            '일반 등산 모드',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '고도 변화: ${_currentAltitude.toStringAsFixed(1)}m',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            '등산 시간: $_formattedTime',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            '이동 거리: ${_currentTotalDistance.toStringAsFixed(2)}km',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 4),
          if (_isWatchPaired)
            Text(
              '현재 심박수: $_currentHeartRate bpm',
              style: TextStyle(fontSize: 14),
            )
          else
            Text(
              '현재 심박수: 워치와 연동해주세요',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
        ],

        // 피드백 메시지 (일반 모드가 아닐 때만 표시)
        if (!isGeneralMode) _buildFeedbackMessage(),

        // 등산 종료 버튼
        _buildEndTrackingButton(),

        // 여분의 공간 추가해서 스크롤이 잘 되도록 함
        SizedBox(height: 30),
      ],
    );
  }

  // 피드백 메시지 위젯
  Widget _buildFeedbackMessage() {
    // 이전 기록이 있는 경우만 표시
    if (_modeData?.opponent == null) {
      return SizedBox.shrink();
    }

    final String message = _isAheadOfRecord
        ? '${_distanceDifference.abs().toStringAsFixed(2)}km 앞서는 중!'
        : '${_distanceDifference.abs().toStringAsFixed(2)}km 뒤처지는 중!';

    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isAheadOfRecord ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isAheadOfRecord ? Colors.green[800] : Colors.red[800],
            ),
          ),
          SizedBox(width: 4),
          Icon(
            _isAheadOfRecord ? Icons.arrow_upward : Icons.arrow_downward,
            color: _isAheadOfRecord ? Colors.green : Colors.red,
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
        onPressed: () {
          if (_isDestinationReached) {
            // 목적지 도달 시: 기존대로 저장 여부 선택 다이얼로그 표시
            _showSaveOptionDialog(context);
          } else {
            // 목적지 미도달 시: 경고 문구와 함께 바로 종료 확인 다이얼로그 표시 (저장 안 함)
            _showEndTrackingDialog(context, false, isEarlyExit: true);
          }
        },
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

  // 등산 기록 저장 여부 확인 다이얼로그
  void _showSaveOptionDialog(BuildContext context) {
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
                '등산 기록 저장',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                '등산 기록을 저장하시겠습니까?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 저장 안 함 버튼
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      // 저장하지 않고 종료 확인 다이얼로그 표시
                      _showEndTrackingDialog(context, false);
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '저장 안 함',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 저장 버튼
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      // 저장하고 종료 확인 다이얼로그 표시
                      _showEndTrackingDialog(context, true);
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '저장',
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

  // 등산 종료 확인 다이얼로그
  void _showEndTrackingDialog(BuildContext context, bool shouldSave,
      {bool isEarlyExit = false}) {
    // isEarlyExit 파라미터 추가
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
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    shouldSave ? Icons.save : Icons.do_not_disturb,
                    color: shouldSave ? Colors.blue : Colors.grey,
                    size: 18,
                  ),
                  SizedBox(width: 5),
                  Text(
                    shouldSave ? '등산 기록이 저장됩니다.' : '등산 기록이 저장되지 않습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: shouldSave ? Colors.blue : Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              // 목적지 미도달 시 추가 경고 문구
              if (isEarlyExit)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    '목적지에 도달하지 않고 종료 시에는\n기록이 저장되지 않고 경험치도 주어지지 않습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              SizedBox(height: 20),
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
                      // 등산 종료 처리 및 서버 전송, isSave 값을 전달
                      _finishTracking(shouldSave);
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

  // 등산 종료 처리 및 서버 전송
  Future<void> _finishTracking([bool shouldSave = true]) async {
    try {
      // 현재 상태의 데이터 저장
      _saveCurrentTrackingData();

      // AppState
      final appState = Provider.of<AppState>(context, listen: false);
      final token = appState.accessToken ?? '';

      // 선택된 산과 등산로
      final mountainId =
          _modeData?.mountain.id ?? (appState.selectedRoute?.mountainId ?? 0);
      final pathId = _modeData?.path.id ?? (appState.selectedRoute?.id ?? 0);

      // 대결 관련 설정
      final opponentId = _modeData?.opponent?.opponentId;
      final recordId = null; // ModeData에 recordId가 없으므로 null로 설정

      debugPrint(
          '등산 종료 요청 준비: mountainId=$mountainId, pathId=$pathId, 기록 저장: $shouldSave');

      // 서버에 전송할 데이터
      // 기록 저장 여부에 관계없이 API는 항상 호출, isSave 값만 다르게 전달
      final modeService = ModeService();

      // 종료 API 호출
      await modeService.endTracking(
        mountainId: mountainId.toInt(),
        pathId: pathId.toInt(),
        opponentId: opponentId,
        recordId: recordId,
        isSave: shouldSave, // 사용자 선택에 따라 저장 여부 설정
        finalLatitude: _currentLat,
        finalLongitude: _currentLng,
        finalTime: _elapsedSeconds,
        finalDistance: (_currentTotalDistance * 1000).toInt(), // km -> m 변환
        records: _trackingRecords,
        token: token,
      );

      debugPrint('등산 종료 요청 성공 (기록 저장: $shouldSave)');
    } catch (e) {
      debugPrint('등산 종료 요청 오류: $e');
      // 오류 발생 시에도 트래킹은 종료
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등산 기록 저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      // 종료 처리 (앱 상태 초기화)
      final appState = Provider.of<AppState>(context, listen: false);
      appState.endTracking(); // isTracking = false, AppState 리스너들에게 알림

      // 홈 화면(0번 탭)으로 이동하도록 AppState 변경
      // HomeScreen이 이 변경을 감지하고 화면을 전환하거나 새로고침할 것임
      appState.changePage(0);
    }
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

          // 카메라 이동 중 플래그 설정 - 방향 회전 방지
          _isMovingToCurrentLocation = true;

          // 위치 추적 모드를 face로 설정 (방향에 맞춰 회전)
          await _mapController!
              .setLocationTrackingMode(NLocationTrackingMode.face);

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

          // 이동 완료 후 방향 기준점 재설정 및 이동 플래그 해제
          _lastAppliedHeading = _deviceHeading;
          _isMovingToCurrentLocation = false;

          // 모드 변경 후 일정 시간 후 다시 한번 추적 모드 확인
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _mapController != null && _isNavigationMode) {
              try {
                _mapController!
                    .setLocationTrackingMode(NLocationTrackingMode.face);
                debugPrint('네비게이션 모드 추적 모드 재확인');
              } catch (e) {
                debugPrint('추적 모드 재설정 오류: $e');
              }
            }
          });
        } else {
          // 위치 추적 모드를 noFollow로 설정 (방향 회전 없음)
          await _mapController!
              .setLocationTrackingMode(NLocationTrackingMode.noFollow);

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

          // 모드 변경 후 일정 시간 후 다시 한번 추적 모드 확인
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _mapController != null && !_isNavigationMode) {
              try {
                _mapController!
                    .setLocationTrackingMode(NLocationTrackingMode.noFollow);
                debugPrint('전체 맵 모드 추적 모드 재확인');
              } catch (e) {
                debugPrint('추적 모드 재설정 오류: $e');
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('네비게이션 모드 전환 오류: $e');
      // 오류 발생 시 이동 플래그 초기화
      _isMovingToCurrentLocation = false;
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

    // 위치 추적 모드를 다시 설정
    _resetLocationTrackingMode();

    _moveToCurrentLocation();
  }

  // 위치 추적 모드 재설정
  void _resetLocationTrackingMode() {
    if (_mapController == null) return;

    try {
      // 현재 모드에 맞게 위치 추적 모드 설정
      if (_isNavigationMode) {
        _mapController!.setLocationTrackingMode(NLocationTrackingMode.face);
      } else {
        _mapController!.setLocationTrackingMode(NLocationTrackingMode.noFollow);
      }

      // 위치 오버레이 설정 재적용
      final locOverlay = _mapController!.getLocationOverlay();

      // 크기 및 스타일 설정
      locOverlay.setIconSize(const Size(64, 64));
      locOverlay.setCircleRadius(10);

      try {
        // 화살표 아이콘 설정
        final NOverlayImage arrowIcon =
            NOverlayImage.fromAssetImage('lib/assets/images/up-arrow.png');
        locOverlay.setIcon(arrowIcon);

        // 베어링 값 직접 설정 (현재 디바이스 방향)
        locOverlay.setBearing(_deviceHeading);
      } catch (e) {
        debugPrint('아이콘 재설정 오류: $e');
      }

      // 색상 및 가시성 설정
      locOverlay.setCircleColor(AppColors.primary.withAlpha(51));
      locOverlay.setCircleOutlineColor(AppColors.primary);
      locOverlay.setIsVisible(true);

      debugPrint('위치 추적 모드 재설정 완료');
    } catch (e) {
      debugPrint('위치 추적 모드 재설정 오류: $e');
    }
  }

  // 현재 위치로 카메라 이동
  void _moveToCurrentLocation() {
    if (_pendingLocationClicks <= 0) {
      _isLocationButtonProcessing = false;
      return;
    }

    try {
      // 카메라 이동 중 플래그 설정
      _isMovingToCurrentLocation = true;

      // debugPrint('카메라를 현재 위치로 이동합니다: $_currentLat, $_currentLng');

      // 카메라를 현재 위치로 이동
      _mapController!
          .updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(_currentLat, _currentLng),
          zoom: 17,
          tilt: _isNavigationMode ? 50 : 0,
          bearing: _isNavigationMode ? _deviceHeading : 0,
        ),
      )
          .then((_) {
        // 이동이 완료되면 카운터 감소
        _pendingLocationClicks--;

        // 모든 클릭 처리 완료
        _isLocationButtonProcessing = false;

        // 이동이 완료되면 이동 중 플래그 해제
        _isMovingToCurrentLocation = false;

        // 이동 후에는 마지막 적용 방향을 현재 방향과 동기화 (움직이지 않는 효과)
        _lastAppliedHeading = _deviceHeading;
      }).catchError((error) {
        debugPrint('카메라 업데이트 오류: $error');
        // 오류 발생 시 처리 완료
        _pendingLocationClicks = 0;
        _isLocationButtonProcessing = false;
        _isMovingToCurrentLocation = false;
      });
    } catch (e) {
      debugPrint('위치 버튼 처리 중 오류: $e');
      // 오류 발생 시 처리 완료
      _pendingLocationClicks = 0;
      _isLocationButtonProcessing = false;
      _isMovingToCurrentLocation = false;
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
          // 현재 방향 저장
          final newHeading = event.heading!;

          // 방향 변화량 계산 (절대값)
          final double headingChange = (newHeading - _lastAppliedHeading).abs();
          // 360도 근처에서의 방향 변화 특별 처리 (예: 355도 -> 5도)
          final double circularHeadingChange =
              math.min(headingChange, 360 - headingChange);

          setState(() {
            _deviceHeading = newHeading;
          });

          // 위치 오버레이의 베어링을 직접 업데이트
          if (_mapController != null) {
            try {
              final locOverlay = _mapController!.getLocationOverlay();
              locOverlay.setBearing(newHeading);
            } catch (e) {
              debugPrint('위치 오버레이 베어링 업데이트 오류: $e');
            }
          }

          // 네비게이션 모드이고 방향 변화가 충분할 때만 카메라 회전
          // 그리고 현재 위치로 이동 중이 아닐 때만 방향 갱신
          if (_isNavigationMode &&
              _mapController != null &&
              circularHeadingChange >= _minHeadingChangeForUpdate &&
              !_isMovingToCurrentLocation) {
            // 부드러운 카메라 회전을 위한 보간 적용
            // 현재 방향과 목표 방향 사이의 중간 값을 계산하여 부드럽게 이동
            final interpolatedHeading =
                _interpolateHeading(_lastAppliedHeading, newHeading);

            // 현재 위치에 초점을 맞추고 카메라를 디바이스 방향으로 회전
            _mapController!
                .updateCamera(
              NCameraUpdate.withParams(
                target: NLatLng(_currentLat, _currentLng),
                bearing: interpolatedHeading,
                tilt: 50,
              ),
            )
                .then((_) {
              // 성공적으로 적용된 경우 마지막 적용 방향 업데이트
              _lastAppliedHeading = newHeading;
            });
          }
        }
      });
      debugPrint('나침반 센서 구독 시작');
    } else {
      debugPrint('이 기기에서는 나침반 센서를 사용할 수 없습니다.');
    }
  }

  // 방향 보간 계산 함수
  double _interpolateHeading(double current, double target) {
    // 두 방향 사이의 최단 회전 방향 계산
    double diff = target - current;

    // 180도를 넘는 회전은 반대 방향으로 처리 (최단 경로)
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    // 부드러운 이동을 위한 보간 계수 (0.3 = 30% 이동)
    final interpolationFactor = 0.3;

    // 현재 방향에서 목표 방향으로 부분적으로 이동
    double newHeading = current + (diff * interpolationFactor);

    // 0-360 범위로 정규화
    if (newHeading < 0) {
      newHeading += 360;
    } else if (newHeading >= 360) {
      newHeading -= 360;
    }

    return newHeading;
  }

  // 위치 추적 모드를 확인하고 필요하면 업데이트하는 별도 함수
  Future<void> _checkAndUpdateTrackingMode() async {
    if (_mapController == null) return;

    try {
      final currentMode = await _mapController!.getLocationTrackingMode();
      if (_isNavigationMode) {
        // 네비게이션 모드인데 추적 모드가 face가 아니면 재설정
        // if (currentMode != NLocationTrackingMode.face) {
        //   _mapController!.setLocationTrackingMode(NLocationTrackingMode.face);
        //   debugPrint('네비게이션 모드로 추적 모드 재설정 (Face)');
        // }
      } else {
        // 전체 맵 모드인데 추적 모드가 noFollow가 아니면 재설정
        if (currentMode != NLocationTrackingMode.noFollow) {
          _mapController!
              .setLocationTrackingMode(NLocationTrackingMode.noFollow);
          debugPrint('전체 맵 모드로 추적 모드 재설정 (NoFollow)');
        }
      }
    } catch (e) {
      debugPrint('추적 모드 확인/재설정 중 비동기 오류: $e');
    }
  }

  // 모드 데이터 로드 (이전 기록 정보 포함)
  Future<void> _loadModeData() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);

      // 앱 상태에서 이미 저장된 ModeData가 있으면 가져오기
      if (appState.modeData != null) {
        setState(() {
          _modeData = appState.modeData;
          debugPrint('저장된 모드 데이터 로드: ${_modeData?.path.name}');

          // ModeData에서 opponent 정보 가져와서 경쟁자 데이터로 설정
          if (_modeData?.opponent != null) {
            _competitorData = {
              'name': _modeData?.opponent?.nickname ?? '이전 기록',
              'distance': _modeData?.path.distance ?? 0.0,
              'time': _modeData?.path.estimatedTime ?? 0,
              'isAhead': true,
            };
            debugPrint('경쟁자 데이터 설정: ${_competitorData['name']}');
          }
        });
      } else {
        debugPrint('저장된 모드 데이터가 없습니다.');
      }
    } catch (e) {
      debugPrint('모드 데이터 로드 오류: $e');
    }
  }

  // 남은 거리 및 예상 시간 계산 함수
  void _calculateRemainingDistanceAndTime() {
    if (_routeCoordinates.isEmpty || _userPath.isEmpty) return;

    try {
      // 1. 현재 위치에서 등산로 상의 가장 가까운 지점 찾기
      final currentPosition = NLatLng(_currentLat, _currentLng);
      double minDistance = double.infinity;
      int closestPointIndex = 0;

      for (int i = 0; i < _routeCoordinates.length; i++) {
        final params = {
          'lat1': currentPosition.latitude,
          'lng1': currentPosition.longitude,
          'lat2': _routeCoordinates[i].latitude,
          'lng2': _routeCoordinates[i].longitude,
        };

        final distance = _calculateDistanceSync(params);
        if (distance < minDistance) {
          minDistance = distance;
          closestPointIndex = i;
        }
      }

      // 2. 등산로의 총 거리 (pathLength) 활용
      // - 선택된 등산로가 AppState에 있을 경우, 그대로 사용
      // - 아닐 경우, 각 구간 별 거리의 합으로 계산
      double totalPathLength = 0.0;
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.selectedRoute != null) {
        totalPathLength = appState.selectedRoute!.distance * 1000; // km를 m로 변환
        if (_elapsedSeconds % 30 == 0) {
          // 30초마다 로그 출력
          debugPrint('등산로 전체 길이(pathLength): ${totalPathLength}m');
        }
      } else {
        // 등산로 경로 좌표로부터 총 길이 계산
        for (int i = 0; i < _routeCoordinates.length - 1; i++) {
          final params = {
            'lat1': _routeCoordinates[i].latitude,
            'lng1': _routeCoordinates[i].longitude,
            'lat2': _routeCoordinates[i + 1].latitude,
            'lng2': _routeCoordinates[i + 1].longitude,
          };
          totalPathLength += _calculateDistanceSync(params);
        }
        if (_elapsedSeconds % 30 == 0) {
          // 30초마다 로그 출력
          debugPrint('계산된 등산로 전체 길이: ${totalPathLength}m');
        }
      }

      // 3. 가장 가까운 지점부터 목적지(경로의 마지막 지점)까지의 거리 계산
      double remainingDistance = 0.0;
      for (int i = closestPointIndex; i < _routeCoordinates.length - 1; i++) {
        final params = {
          'lat1': _routeCoordinates[i].latitude,
          'lng1': _routeCoordinates[i].longitude,
          'lat2': _routeCoordinates[i + 1].latitude,
          'lng2': _routeCoordinates[i + 1].longitude,
        };

        remainingDistance += _calculateDistanceSync(params);
      }

      // 4. 경로 진행률 계산 (pathLength 활용)
      double completedDistance = totalPathLength - remainingDistance;

      // 5. 진행률이 음수가 되지 않도록 보정 (현재 위치가 경로 밖에 있는 경우 등)
      if (completedDistance < 0) completedDistance = 0;
      if (completedDistance > totalPathLength)
        completedDistance = totalPathLength;

      // 6. 진행률 계산 및 남은 거리 설정
      final oldCompletedPercentage = _completedPercentage;
      _completedPercentage = completedDistance / totalPathLength;
      _completedPercentage = _completedPercentage.clamp(0.0, 1.0); // 0~1 범위로 제한

      // 7. 남은 거리 설정 (킬로미터 단위로 변환)
      final oldRemainingDistance = _remainingDistance;
      _remainingDistance = remainingDistance / 1000;

      // 8. 현재까지의 평균 이동 속도 계산
      if (_elapsedSeconds > 0 && completedDistance > 0) {
        final avgSpeed = completedDistance / _elapsedSeconds;

        // 급격한 속도 변화 방지를 위한 가중 평균 (새 속도에 20% 가중치 부여)
        _averageSpeedMetersPerSecond =
            (_averageSpeedMetersPerSecond * 0.8 + avgSpeed * 0.2);

        // 너무 느리거나 빠른 속도 방지 (일반 등산 속도 기준으로 조정)
        _averageSpeedMetersPerSecond =
            math.max(_averageSpeedMetersPerSecond, 0.15); // 최소 초당 15cm
        _averageSpeedMetersPerSecond = math.min(
            _averageSpeedMetersPerSecond, 0.8); // 최대 초당 0.8m (약 2.88km/h)
      }

      // 9. 예상 남은 시간 계산 (초 단위)
      final oldEstimatedRemainingSeconds = _estimatedRemainingSeconds;
      if (_averageSpeedMetersPerSecond > 0) {
        _estimatedRemainingSeconds =
            (remainingDistance / _averageSpeedMetersPerSecond).round();

        // 경사도, 지형 난이도 등을 고려한 보정 (상향 보정)
        double difficultyFactor = 1.2; // 기본 보정 계수를 1.0에서 1.2로 증가 (20% 더 오래 걸림)

        // 남은 부분이 많을수록 더 많은 보정
        difficultyFactor +=
            0.3 * (1.0 - _completedPercentage); // 0.2에서 0.3으로 증가

        // 등산로 난이도에 따른 보정 (AppState에서 선택된 경로가 있는 경우)
        if (appState.selectedRoute != null) {
          switch (appState.selectedRoute!.difficulty) {
            case '상':
              difficultyFactor += 0.5; // 0.3에서 0.5로 증가
              break;
            case '중':
              difficultyFactor += 0.3; // 0.2에서 0.3으로 증가
              break;
            case '하':
              difficultyFactor += 0.15; // 0.1에서 0.15로 증가
              break;
          }
        }

        _estimatedRemainingSeconds =
            (_estimatedRemainingSeconds * difficultyFactor).round();
      }

      // 10. 값이 변경되었을 때만 setState 호출해서 UI 갱신 (불필요한 렌더링 방지)
      if (_completedPercentage != oldCompletedPercentage ||
          _remainingDistance != oldRemainingDistance ||
          _estimatedRemainingSeconds != oldEstimatedRemainingSeconds) {
        setState(() {
          // 이미 값은 변경되어 있으므로 UI 갱신만 수행
        });
      }

      // 디버그 로그 (10초마다 출력)
      if (_elapsedSeconds % 10 == 0) {
        debugPrint(
            '남은 거리: ${_remainingDistance.toStringAsFixed(2)}km (${(_remainingDistance * 1000).toStringAsFixed(0)}m), '
            '예상 남은 시간: $_formattedRemainingTime, '
            '평균 속도: ${(_averageSpeedMetersPerSecond * 3.6).toStringAsFixed(1)}km/h, '
            '완료율: ${(_completedPercentage * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      debugPrint('남은 거리 및 시간 계산 중 오류: $e');
    }
  }

  // 거리 계산 함수 (동기 버전)
  double _calculateDistanceSync(Map<String, double> params) {
    const double earthRadius = 6371000; // 지구 반경 (미터)
    final double lat1 = params['lat1']!;
    final double lng1 = params['lng1']!;
    final double lat2 = params['lat2']!;
    final double lng2 = params['lng2']!;

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

  // 각도를 라디안으로 변환 (BackgroundTask의 메서드와 동일)
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // 남은 시간 포맷팅
  String get _formattedRemainingTime {
    final totalSeconds = _estimatedRemainingSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours시 $minutes분 $seconds초';
    } else {
      return '$minutes분 $seconds초';
    }
  }

  // 등산 기록 저장 시작
  void _startTrackingRecords() {
    // 5초마다 현재 데이터 저장
    _recordTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isPaused) {
        _saveCurrentTrackingData();
      }
    });
  }

  // 현재 등산 데이터 저장
  void _saveCurrentTrackingData() {
    // 현재 시간
    final now = DateTime.now();

    // 처음 기록하는 경우 lastRecordTime 초기화
    _lastRecordTime ??= now;

    // 30초마다 records에 데이터 추가
    final secondsSinceLastRecord = now.difference(_lastRecordTime!).inSeconds;
    if (secondsSinceLastRecord >= _recordIntervalSeconds) {
      // 추가할 기록 생성
      final record = {
        'time': _elapsedSeconds,
        'distance': (_currentTotalDistance * 1000).toInt(), // km -> m 변환
        'latitude': _currentLat,
        'longitude': _currentLng,
        'heartRate': _currentHeartRate, // _avgHeartRate를 _currentHeartRate로 변경
      };

      // 기록 추가
      _trackingRecords.add(record);
      _lastRecordTime = now;

      debugPrint(
          '기록 저장: ${_trackingRecords.length}번째 기록 ($_elapsedSeconds초, ${_currentTotalDistance.toStringAsFixed(2)}km)');
    }
  }

  // 블루투스 권한 요청
  Future<void> _requestBluetoothPermissions() async {
    try {
      // 블루투스 관련 권한 요청
      final status = await Permission.bluetooth.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      final scanStatus = await Permission.bluetoothScan.request();

      debugPrint('블루투스 권한 상태: $status');
      debugPrint('블루투스 연결 권한 상태: $connectStatus');
      debugPrint('블루투스 스캔 권한 상태: $scanStatus');
    } catch (e) {
      debugPrint('블루투스 권한 요청 오류: $e');
    }
  }

  // 워치 연결 상태 확인
  Future<void> _checkWatchConnection() async {
    if (_isCheckingWatch) return;

    setState(() {
      _isCheckingWatch = true;
      _watchStatus = '워치 연결 확인 중...';
    });

    try {
      // watch_connectivity 라이브러리를 사용해 워치 연결 상태 확인
      final isPaired = await _watch.isPaired;

      setState(() {
        _isWatchPaired = isPaired;
        _watchStatus = isPaired ? '워치가 연결되어 있습니다' : '워치가 연결되어 있지 않습니다';
        _isCheckingWatch = false;
      });

      debugPrint('워치 연결 상태: ${isPaired ? '연결됨' : '연결되지 않음'}');
    } catch (e) {
      setState(() {
        _isWatchPaired = false;
        _watchStatus = '워치 연결 확인 중 오류 발생: $e';
        _isCheckingWatch = false;
      });
      debugPrint('워치 연결 확인 중 오류: $e');
    }
  }

  // 워치에 메시지 전송 (watch_connectivity 사용)
  Future<void> _sendMessageToWatch() async {
    if (!_isWatchPaired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('워치가 연결되어 있지 않습니다.')),
      );
      return;
    }

    try {
      debugPrint('워치에 메시지 전송 시도...');

      // 테스트 메시지 전송
      await _watch.sendMessage({'path': '/REACHED'});

      debugPrint('워치에 메시지 전송 완료');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('워치에 메시지를 전송했습니다.')),
      );
    } catch (e) {
      debugPrint('워치 메시지 전송 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('워치 메시지 전송 실패: $e')),
      );
    }
  }

  // 워치 연결 버튼 위젯
  Widget _buildWatchButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FloatingActionButton(
            heroTag: 'watchConnect',
            onPressed: _isCheckingWatch
                ? null
                : () async {
                    await _checkWatchConnection();
                    if (_isWatchPaired) {
                      _sendMessageToWatch();
                    }
                  },
            mini: true,
            backgroundColor: _isWatchPaired ? Colors.green : Colors.grey,
            child: Icon(
              _isWatchPaired ? Icons.watch : Icons.watch_outlined,
              color: Colors.white,
            ),
          ),
          // 워치 상태 표시
          if (_isCheckingWatch || _watchStatus.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isCheckingWatch ? '확인 중...' : _watchStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 토스트 메시지 표시 함수
  void _showToastMessage(String message, {bool isAhead = true}) {
    setState(() {
      _showToast = true;
      _toastMessage = message;
      _toastColor = isAhead ? Colors.green.shade700 : Colors.red.shade700;
    });

    // 이전 타이머 취소
    _toastTimer?.cancel();

    // 3초 후 토스트 메시지 숨기기
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showToast = false;
        });
      }
    });
  }
}
