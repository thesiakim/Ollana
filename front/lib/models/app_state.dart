// lib/models/app_state.dart
// AppState: 전역 상태 관리 (로그인, 페이지 인덱스, 트래킹 등)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/hiking_route.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

enum TrackingStage { search, routeSelect, modeSelect, tracking }

class AppState extends ChangeNotifier {
  // 로그인 상태 및 토큰
  bool _isLoggedIn = false;
  String? _accessToken;

  // 페이지 인덱스
  int _currentPageIndex = 0;

  // 트래킹 관련 상태
  TrackingStage _trackingStage = TrackingStage.search;
  bool _isTracking = false;
  String? _selectedMountain;
  HikingRoute? _selectedRoute;
  String? _selectedMode;

  // LiveTrackingScreen 데이터
  List<NLatLng> _routeCoordinates = [];
  final List<NLatLng> _userPath = [];
  double _currentLat = 37.5665;
  double _currentLng = 126.9780;
  double _currentAltitude = 120;
  int _elapsedSeconds = 0;
  int _elapsedMinutes = 0;
  double _distance = 0.0;
  int _maxHeartRate = 0;
  int _avgHeartRate = 0;
  bool _isNavigationMode = true;
  double _deviceHeading = 0;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get accessToken => _accessToken;
  int get currentPageIndex => _currentPageIndex;
  TrackingStage get trackingStage => _trackingStage;
  bool get isTracking => _isTracking;
  String? get selectedMountain => _selectedMountain;
  HikingRoute? get selectedRoute => _selectedRoute;
  String? get selectedMode => _selectedMode;

  List<NLatLng> get routeCoordinates => _routeCoordinates;
  List<NLatLng> get userPath => _userPath;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  double get currentAltitude => _currentAltitude;
  int get elapsedSeconds => _elapsedSeconds;
  int get elapsedMinutes => _elapsedMinutes;
  double get distance => _distance;
  int get maxHeartRate => _maxHeartRate;
  int get avgHeartRate => _avgHeartRate;
  bool get isNavigationMode => _isNavigationMode;
  double get deviceHeading => _deviceHeading;

  // 로그인 상태 토글
  void toggleLogin() {
    try {
      _isLoggedIn = !_isLoggedIn;
      debugPrint('로그인 상태 변경: $_isLoggedIn');
      notifyListeners();
    } catch (e) {
      debugPrint('로그인 상태 변경 중 오류 발생: $e');
    }
  }

  // 토큰 설정
  void setToken(String token) {
    _accessToken = token;
    debugPrint('토큰 저장: $_accessToken');
    notifyListeners();
  }

  // 클라이언트 인증 정보 초기화
  void clearAuth() {
    _accessToken = null;
    _isLoggedIn = false;
    debugPrint('클라이언트 인증 정보 초기화');
    notifyListeners();
  }

  // 페이지 변경
  void changePage(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  // 산 선택
  void selectMountain(String name) {
    _selectedMountain = name;
    _trackingStage = TrackingStage.routeSelect;
    notifyListeners();
  }

  // 등산로 선택 및 단계 전환
  void selectRoute(HikingRoute route) {
    _selectedRoute = route;
    _trackingStage = TrackingStage.modeSelect;
    notifyListeners();
  }

  // 등산로 미리 선택 (단계 전환 없이)
  void preSelectRoute(HikingRoute route) {
    _selectedRoute = route;
    debugPrint('사전 등산로 선택: ${route.name}');
    notifyListeners();
  }

  // 모드 선택 및 트래킹 시작
  void startTracking(String mode) {
    _selectedMode = mode;
    _isTracking = true;
    _trackingStage = TrackingStage.tracking;
    if (_elapsedSeconds == 0 && _elapsedMinutes == 0) {
      _resetTrackingData();
      if (_selectedRoute != null && _selectedRoute!.path.isNotEmpty) {
        final pathPoints = _selectedRoute!.path
            .map((coord) =>
                NLatLng(coord['latitude'] ?? 0.0, coord['longitude'] ?? 0.0))
            .toList();
        if (pathPoints.isNotEmpty) {
          _routeCoordinates = pathPoints;
          debugPrint('경로 좌표 설정 완료 (${pathPoints.length} 포인트)');
        }
      }
    }
    notifyListeners();
  }

  // 트래킹 데이터 초기화
  void _resetTrackingData() {
    _userPath.clear();
    _elapsedSeconds = 0;
    _elapsedMinutes = 0;
    _distance = _selectedRoute?.distance ?? 0.0;
    _maxHeartRate = 0;
    _avgHeartRate = 0;
    if (_selectedRoute != null && _selectedRoute!.path.isNotEmpty) {
      final first = _selectedRoute!.path.first;
      _currentLat = first['latitude'] ?? _currentLat;
      _currentLng = first['longitude'] ?? _currentLng;
      _userPath.add(NLatLng(_currentLat, _currentLng));
    }
  }

  // 트래킹 데이터 업데이트
  void updateTrackingData({
    List<NLatLng>? routeCoordinates,
    NLatLng? newUserPathPoint,
    double? currentLat,
    double? currentLng,
    double? currentAltitude,
    int? elapsedSeconds,
    double? distance,
    int? maxHeartRate,
    int? avgHeartRate,
    bool? isNavigationMode,
    double? deviceHeading,
  }) {
    bool changed = false;
    if (routeCoordinates != null) {
      _routeCoordinates = routeCoordinates;
      changed = true;
    }
    if (newUserPathPoint != null) {
      _userPath.add(newUserPathPoint);
      changed = true;
    }
    if (currentLat != null) {
      _currentLat = currentLat;
      changed = true;
    }
    if (currentLng != null) {
      _currentLng = currentLng;
      changed = true;
    }
    if (currentAltitude != null) {
      _currentAltitude = currentAltitude;
      changed = true;
    }
    if (elapsedSeconds != null) {
      _elapsedSeconds = elapsedSeconds;
      _elapsedMinutes = elapsedSeconds ~/ 60;
      changed = true;
    }
    if (distance != null) {
      _distance = distance;
      changed = true;
    }
    if (maxHeartRate != null) {
      _maxHeartRate = maxHeartRate;
      changed = true;
    }
    if (avgHeartRate != null) {
      _avgHeartRate = avgHeartRate;
      changed = true;
    }
    if (isNavigationMode != null) {
      _isNavigationMode = isNavigationMode;
      changed = true;
    }
    if (deviceHeading != null) {
      _deviceHeading = deviceHeading;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  // 트래킹 종료
  void endTracking() {
    _isTracking = false;
    _trackingStage = TrackingStage.search;
    _selectedMountain = null;
    _selectedRoute = null;
    _selectedMode = null;
    _resetTrackingData();
    notifyListeners();
  }

  // 뒤로가기 등 트래킹 단계 초기화
  void resetTrackingStage() {
    if (!_isTracking) {
      _trackingStage = TrackingStage.search;
      _selectedMountain = null;
      _selectedRoute = null;
      _selectedMode = null;
      notifyListeners();
    }
  }

  // 등산로 선택 화면으로 돌아가기 (산 정보 유지)
  void backToRouteSelect() {
    if (!_isTracking) {
      _trackingStage = TrackingStage.search;
      notifyListeners();
    }
  }
}
