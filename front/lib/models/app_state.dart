// app_state.dart: 앱의 전역 상태를 관리하는 모델 클래스
// - ChangeNotifier를 상속하여 상태 변경 시 UI에 알림
// - 로그인 상태(isLoggedIn) 관리
// - 현재 페이지 인덱스(currentPageIndex) 관리
// - Provider 패턴을 사용하여 상태 관리 및 위젯 트리 전체에서 접근 가능

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/hiking_route.dart';

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

  // 모드 선택 및 트래킹 시작 시 호출
  void startTracking(String mode) {
    _selectedMode = mode;
    _isTracking = true;
    _trackingStage = TrackingStage.tracking;
    notifyListeners();
  }

  // 트래킹 종료 시 호출
  void endTracking() {
    _isTracking = false;
    _trackingStage = TrackingStage.search;
    _selectedMountain = null;
    _selectedRoute = null;
    _selectedMode = null;
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
