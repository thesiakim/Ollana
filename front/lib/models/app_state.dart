// app_state.dart: 앱의 전역 상태를 관리하는 모델 클래스
// - ChangeNotifier를 상속하여 상태 변경 시 UI에 알림
// - 로그인 상태(isLoggedIn) 관리
// - 현재 페이지 인덱스(currentPageIndex) 관리
// - Provider 패턴을 사용하여 상태 관리 및 위젯 트리 전체에서 접근 가능

import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  int _currentPageIndex = 0;

  bool get isLoggedIn => _isLoggedIn;
  int get currentPageIndex => _currentPageIndex;

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
}
