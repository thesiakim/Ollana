// app_state.dart: 앱의 전역 상태를 관리하는 모델 클래스
// - ChangeNotifier를 상속하여 상태 변경 시 UI에 알림
// - 로그인 상태(isLoggedIn) 관리
// - 현재 페이지 인덱스(currentPageIndex) 관리
// - Provider 패턴을 사용하여 상태 관리 및 위젯 트리 전체에서 접근 가능

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/hiking_route.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

// 트래킹 단계를 나타내는 열거형
enum TrackingStage {
  search, // 산 검색 단계
  routeSelect, // 등산로 선택 단계
  modeSelect, // 모드 선택 단계
  tracking // 실시간 트래킹 단계
}

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  int _currentPageIndex = 0;

  // 트래킹 관련 상태
  TrackingStage _trackingStage = TrackingStage.search;
  bool _isTracking = false;
  String? _selectedMountain;
  HikingRoute? _selectedRoute;
  String? _selectedMode;

  // LiveTrackingScreen 데이터 유지를 위한 필드
  // 트래킹 경로 및 위치 데이터
  List<NLatLng> _routeCoordinates = [];
  final List<NLatLng> _userPath = [];
  double _currentLat = 37.5665;
  double _currentLng = 126.9780;
  double _currentAltitude = 120;

  // 트래킹 정보
  int _elapsedSeconds = 0;
  int _elapsedMinutes = 0;
  double _distance = 0.0;
  int _maxHeartRate = 0;
  int _avgHeartRate = 0;

  // 네비게이션 모드 설정
  bool _isNavigationMode = true;
  double _locationBearing = 0;

  // LiveTrackingScreen 데이터 getter
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
  double get locationBearing => _locationBearing;

  bool get isLoggedIn => _isLoggedIn;
  int get currentPageIndex => _currentPageIndex;

  // 트래킹 관련 getter
  TrackingStage get trackingStage => _trackingStage;
  bool get isTracking => _isTracking;
  String? get selectedMountain => _selectedMountain;
  HikingRoute? get selectedRoute => _selectedRoute;
  String? get selectedMode => _selectedMode;

  void toggleLogin() {
    try {
      _isLoggedIn = !_isLoggedIn;
      debugPrint('로그인 상태 변경: $_isLoggedIn');
      notifyListeners();
    } catch (e) {
      debugPrint('로그인 상태 변경 중 오류 발생: $e');
      // 오류 발생 시에도 UI가 중단되지 않도록 합니다
    }
  }

  void changePage(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  // 산 선택 시 호출
  void selectMountain(String name) {
    _selectedMountain = name;
    _trackingStage = TrackingStage.routeSelect;
    notifyListeners();
  }

  // 등산로 선택 시 호출
  void selectRoute(HikingRoute route) {
    _selectedRoute = route;
    _trackingStage = TrackingStage.modeSelect;
    notifyListeners();
  }

  // 등산로 미리 선택 (단계 전환 없이)
  void preSelectRoute(HikingRoute route) {
    _selectedRoute = route;
    // trackingStage는 변경하지 않음 (routeSelect 단계 유지)
    notifyListeners();
  }

  // 모드 선택 및 트래킹 시작 시 호출
  void startTracking(String mode) {
    _selectedMode = mode;
    _isTracking = true;
    _trackingStage = TrackingStage.tracking;

    // 초기화 (처음 시작할 때만)
    if (_elapsedSeconds == 0 && _elapsedMinutes == 0) {
      _resetTrackingData();

      // 선택된 경로 데이터가 있으면 좌표 변환 후 설정
      if (_selectedRoute != null && _selectedRoute!.path.isNotEmpty) {
        // 경로 데이터 NLatLng으로 변환
        final pathPoints = _selectedRoute!.path
            .map((coord) {
              final lat = coord['latitude'];
              final lng = coord['longitude'];
              if (lat != null && lng != null) {
                return NLatLng(lat, lng);
              }
              return null;
            })
            .where((point) => point != null)
            .cast<NLatLng>()
            .toList();

        if (pathPoints.isNotEmpty) {
          _routeCoordinates = pathPoints;
          debugPrint('AppState: 경로 좌표 데이터 설정 완료 (${pathPoints.length} 포인트)');
        }
      }
    }

    notifyListeners();
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
    double? locationBearing,
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

    if (locationBearing != null) {
      _locationBearing = locationBearing;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  // 트래킹 데이터 초기화
  void _resetTrackingData() {
    // _routeCoordinates = []; // 경로 좌표는 초기화하지 않음
    _userPath.clear();
    _elapsedSeconds = 0;
    _elapsedMinutes = 0;
    _distance = _selectedRoute?.distance ?? 0.0;
    _maxHeartRate = 0;
    _avgHeartRate = 0;

    // 시작 위치가 있으면 설정
    if (_selectedRoute != null && _selectedRoute!.path.isNotEmpty) {
      final firstPoint = _selectedRoute!.path.first;
      _currentLat = firstPoint['latitude'] ?? 37.5665;
      _currentLng = firstPoint['longitude'] ?? 126.9780;
      _userPath.add(NLatLng(_currentLat, _currentLng));
    }
  }

  // 트래킹 종료 시 호출
  void endTracking() {
    _isTracking = false;
    _trackingStage = TrackingStage.search;
    _selectedMountain = null;
    _selectedRoute = null;
    _selectedMode = null;

    // 트래킹 데이터 초기화
    _resetTrackingData();

    notifyListeners();
  }

  // 트래킹 단계 초기화 (뒤로가기 등)
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
      // 산과 등산로 정보는 유지
      notifyListeners();
    }
  }
}
