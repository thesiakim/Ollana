// lib/models/app_state.dart
// AppState: 전역 상태 관리 (로그인, 페이지 인덱스, 트래킹 등)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 🔥 secure storage
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/hiking_route.dart';
import '../services/mode_service.dart';

enum TrackingStage { search, routeSelect, modeSelect, tracking }

class AppState extends ChangeNotifier {
  // 🔥 SecureStorage 인스턴스 (앱 전체에서 하나만 사용)
  static const _storage = FlutterSecureStorage();

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

  // 생성자: 앱 시작 시 저장된 토큰 복원
  AppState() {
    _initAuth(); // 🔥 초기 인증 정보 로드
  }

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

  // 🔥 앱 시작 시 SecureStorage에서 토큰을 읽어 로그인 상태 복원
  Future<void> _initAuth() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        _isLoggedIn = true;
        debugPrint('SecureStorage에서 토큰 복원: $_accessToken');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('토큰 복원 오류: $e');
    }
  }

  // 로그인 상태 토글 (UI용)
  void toggleLogin() {
    _isLoggedIn = !_isLoggedIn;
    debugPrint('로그인 상태 변경: $_isLoggedIn');
    notifyListeners();
  }

  // 🔥 토큰 설정 및 SecureStorage에 저장
  Future<void> setToken(String token) async {
    _accessToken = token;
    _isLoggedIn = true;
    debugPrint('토큰 저장: $_accessToken');
    try {
      await _storage.write(key: 'accessToken', value: token);
      debugPrint('SecureStorage에 토큰 저장 완료');
    } catch (e) {
      debugPrint('SecureStorage 저장 오류: $e');
    }
    notifyListeners();
  }

  // 🔥 로그아웃: 메모리와 SecureStorage에서 토큰 삭제
  Future<void> clearAuth() async {
    _accessToken = null;
    _isLoggedIn = false;
    debugPrint('클라이언트 인증 정보 초기화');
    try {
      await _storage.delete(key: 'accessToken');
      debugPrint('SecureStorage에서 토큰 삭제 완료');
    } catch (e) {
      debugPrint('SecureStorage 삭제 오류: $e');
    }
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
  Future<void> startTracking(String mode,
      {int? opponentId, int? recordId}) async {
    _selectedMode = mode;

    try {
      // 현재 위치, 산, 경로 데이터 확인
      if (_selectedRoute == null) {
        debugPrint('선택된 경로 없음');
        return;
      }

      // 모드 서비스 인스턴스 생성
      final modeService = ModeService();

      // 모드에 따른 파라미터 설정
      int modeRecordId = 0;
      if (mode == '나 vs 나' && recordId != null) {
        // 나 vs 나 모드에서는 비교할 이전 기록의 ID가 필요
        modeRecordId = recordId;
      }

      // 서버에 등산 시작 요청
      final result = await modeService.startTracking(
        mountainId: _selectedRoute!.mountainId.toInt(),
        pathId: _selectedRoute!.id.toInt(),
        mode: mode,
        opponentId: opponentId, // 나 vs 친구 모드에서만 사용
        recordId: modeRecordId,
        latitude: _currentLat,
        longitude: _currentLng,
        token: _accessToken ?? '',
      );

      // 트래킹 시작 상태로 변경
      _isTracking = true;
      _trackingStage = TrackingStage.tracking;

      // 트래킹 관련 데이터 초기화
      if (_elapsedSeconds == 0 && _elapsedMinutes == 0) {
        _resetTrackingData();

        // 서버에서 받은 경로 데이터가 있으면 사용, 없으면 기존 경로 사용
        if (result.path.path.isNotEmpty) {
          final pathPoints = result.path.path
              .map((coord) =>
                  NLatLng(coord['latitude'] ?? 0.0, coord['longitude'] ?? 0.0))
              .toList();
          if (pathPoints.isNotEmpty) {
            _routeCoordinates = pathPoints;
            debugPrint('경로 좌표 설정 완료 (${pathPoints.length} 포인트)');
          }
        } else if (_selectedRoute!.path.isNotEmpty) {
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
      debugPrint('트래킹 시작: $mode');
    } catch (e) {
      debugPrint('트래킹 시작 오류: $e');
      // 오류 발생 시 처리
    }
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
      notifyListeners();
    }
  }
}
