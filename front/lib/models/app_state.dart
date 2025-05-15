// lib/models/app_state.dart
// AppState: 전역 상태 관리 (로그인, 페이지 인덱스, 트래킹 등)
import 'dart:convert'; // ▶ 추가: JSON 디코드용
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 🔥 secure storage
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ▶ 추가: 환경변수 읽기용
import 'package:http/http.dart' as http; // ▶ 추가: HTTP 요청용

import '../models/hiking_route.dart';
import '../services/mode_service.dart';
import './hiking_route.dart';
import './friend.dart';
import './mode_data.dart'; // ModeData 모델 임포트

enum TrackingStage { search, routeSelect, modeSelect, tracking }

class AppState extends ChangeNotifier {
  // 🔥 SecureStorage 인스턴스 (앱 전체에서 하나만 사용)
  static const _storage = FlutterSecureStorage();

  // 로그인 상태 및 토큰
  bool _isLoggedIn = false;
  String? _accessToken;
  String? _profileImageUrl;
  String? _nickname;
  bool? _social;
  String? _userId; // ▶ userId 추가
  bool _surveyCompleted = false; // ▶ 추가
  bool get surveyCompleted => _surveyCompleted; // ▶ 추가

  /// 클라이언트 단에서 설문 완료 상태 저장
  void setSurveyCompleted(bool completed) {
    _surveyCompleted = completed;
    notifyListeners();
  }

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

  // 모드 데이터 (API에서 받은 등산 시작 정보)
  ModeData? _modeData;

  // 생성자: 앱 시작 시 저장된 토큰 복원
  AppState() {
    _initAuth(); // 🔥 초기 인증 정보 로드
  }

  // ▶ 추가: 로그인/복원 후 설문 여부 조회
  Future<void> fetchSurveyStatus() async {
    if (_accessToken == null || _userId == null) return;
    final url = '${dotenv.get('AI_BASE_URL')}/has_survey/$_userId';
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $_accessToken',
        },
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        _surveyCompleted = body['has_survey'] as bool;
        debugPrint('설문 상태: $_surveyCompleted'); // ▶ 디버그용
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ fetchSurveyStatus 오류: $e');
    }
  }

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get accessToken => _accessToken;
  String? get profileImageUrl => _profileImageUrl;
  String? get nickname => _nickname;
  bool? get social => _social;
  String? get userId => _userId; // ▶ userId getter

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
  bool get isNavigationMode => _isNavigationMode;
  double get deviceHeading => _deviceHeading;

  // 모드 데이터 Getter
  ModeData? get modeData => _modeData;

  // 🔥 앱 시작 시 SecureStorage에서 토큰과 userId를 읽어 로그인 상태 복원
  Future<void> _initAuth() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      final profileImage = await _storage.read(key: 'profileImageUrl');
      final nickname = await _storage.read(key: 'nickname');
      final social = await _storage.read(key: 'social');
      final storedUserId = await _storage.read(key: 'userId'); // ▶ 읽기

      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        _profileImageUrl = profileImage;
        _nickname = nickname;
        _social = social != null ? social.toLowerCase() == 'true' : null;
        _userId = storedUserId; // ▶ 복원
        _isLoggedIn = true;

        debugPrint('SecureStorage에서 토큰 복원: $_accessToken');
        debugPrint('SecureStorage에서 프로필 이미지 복원: $_profileImageUrl');
        debugPrint('SecureStorage에서 닉네임 복원: $_nickname');
        debugPrint('SecureStorage에서 소셜 복원: $_social');
        debugPrint('SecureStorage에서 userId 복원: $_userId'); // ▶ 로그
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

  // 🔥 토큰 및 userId 설정 및 SecureStorage에 저장
  Future<void> setToken(
    String token, {
    required String userId, // ▶ userId 파라미터 추가
    String? profileImageUrl,
    String? nickname,
    bool? social,
  }) async {
    _accessToken = token;
    _isLoggedIn = true;
    _profileImageUrl = profileImageUrl;
    _nickname = nickname;
    _social = social;
    _userId = userId; // ▶ 저장
    debugPrint('토큰 저장: $_accessToken');
    debugPrint('프로필 이미지 저장: $_profileImageUrl');
    debugPrint('닉네임 저장 : $_nickname');
    debugPrint('소셜 저장: $_social');
    debugPrint('userId 저장: $_userId'); // ▶ 로그

    try {
      await _storage.write(key: 'accessToken', value: token);
      await _storage.write(key: 'profileImageUrl', value: profileImageUrl);
      await _storage.write(key: 'nickname', value: nickname);
      await _storage.write(key: 'social', value: social?.toString());
      await _storage.write(key: 'userId', value: userId); // ▶ 쓰기
      debugPrint('SecureStorage에 인증 정보 저장 완료');
    } catch (e) {
      debugPrint('SecureStorage 저장 오류: $e');
    }
    // ▶ 수정: 토큰 설정 후 즉시 설문 여부 조회
    await fetchSurveyStatus();
    notifyListeners();
  }

  // 🔥 로그아웃: 메모리와 SecureStorage에서 인증 정보 삭제
  Future<void> clearAuth() async {
    _accessToken = null;
    _profileImageUrl = null;
    _nickname = null;
    _social = null;
    _userId = null; // ▶ 초기화
    _isLoggedIn = false;
    debugPrint('클라이언트 인증 정보 초기화');

    try {
      await _storage.delete(key: 'accessToken');
      await _storage.delete(key: 'profileImageUrl');
      await _storage.delete(key: 'nickname');
      await _storage.delete(key: 'social');
      await _storage.delete(key: 'userId'); // ▶ 삭제
      debugPrint('SecureStorage에서 인증 정보 삭제 완료');
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
    debugPrint(
        'AppState.selectRoute - 등산로 설정: id=${route.id}, mountainId=${route.mountainId}, name=${route.name}');
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
      int? modeRecordId; // null로 기본값 설정
      if (mode == '나 vs 나' && recordId != null) {
        // 나 vs 나 모드에서는 비교할 이전 기록의 ID가 필요
        modeRecordId = recordId;
      } else if (mode == '일반 등산') {
        // 일반 등산 모드에서는 recordId를 null로 명시적 설정
        modeRecordId = null;
      }

      // 모드 문자열을 서버에서 요구하는 값으로 변환
      String serverMode;
      switch (mode) {
        case '나 vs 나':
          serverMode = 'ME';
          break;
        case '나 vs 친구':
          serverMode = 'FRIEND';
          break;
        case '일반 등산':
          serverMode = 'GENERAL';
          break;
        default:
          serverMode = 'GENERAL'; // 기본값 설정
          break;
      }

      debugPrint('모드 변환: $mode -> $serverMode');

      // opponentId 설정
      int? modeOpponentId;
      if (mode == '나 vs 나') {
        // 나 vs 나 모드에서는 자신의 ID를 opponentId로 설정
        // 실제 ID는 서버에서 토큰을 통해 가져오므로 null 전달
        modeOpponentId = null;
      } else if (mode == '나 vs 친구') {
        // 나 vs 친구 모드에서는 선택한 친구의 ID를 사용
        modeOpponentId = opponentId;
      } else {
        // 일반 모드에서는 null 설정
        modeOpponentId = null;
      }

      debugPrint('opponentId 설정: $modeOpponentId');

      // 서버에 등산 시작 요청
      final result = await modeService.startTracking(
        mountainId: _selectedRoute!.mountainId.toInt(),
        pathId: _selectedRoute!.id.toInt(),
        mode: serverMode, // 변환된 모드값 사용
        opponentId: modeOpponentId, // 모드에 따라 다르게 설정
        recordId: modeRecordId,
        latitude: _currentLat,
        longitude: _currentLng,
        token: _accessToken ?? '',
      );

      // 모드 데이터 저장
      _modeData = result;
      debugPrint('모드 데이터 저장: ${result.mountain.name}, ${result.path.name}');
      if (result.opponent != null) {
        debugPrint('대결 상대: ${result.opponent!.nickname}');
      }

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

  // 앱 시작 시 등산 상태 확인
  Future<bool> checkTrackingStatus() async {
    try {
      if (_accessToken == null || _accessToken!.isEmpty) {
        debugPrint('트래킹 상태 확인: 토큰이 없습니다.');
        return false;
      }

      // 서버에서 현재 등산 상태 확인
      final modeService = ModeService();
      final trackingData = await modeService.checkActiveTracking(_accessToken!);

      // 등산 중인 상태가 아니면 반환
      if (trackingData == null) {
        debugPrint('트래킹 상태 확인: 활성화된, 등산이 없습니다.');
        return false;
      }

      // 등산 중인 상태면 데이터 복원
      debugPrint('트래킹 상태 확인: 활성화된 등산이 있습니다. 데이터 복원 시작');

      // 산과 등산로 정보 복원
      _selectedMountain = trackingData.mountain.name;
      _selectedRoute = trackingData.path;
      _modeData = trackingData;

      // 모드 정보 복원 (경쟁자 정보에 따라)
      if (trackingData.opponent != null) {
        if (trackingData.opponent?.opponentId == null) {
          _selectedMode = '나 vs 나';
        } else {
          _selectedMode = '나 vs 친구';
        }
      } else {
        _selectedMode = '일반 등산';
      }

      // 트래킹 상태로 변경
      _isTracking = true;
      _trackingStage = TrackingStage.tracking;

      // 등산로 좌표 설정
      if (trackingData.path.path.isNotEmpty) {
        final pathPoints = trackingData.path.path
            .map((coord) =>
                NLatLng(coord['latitude'] ?? 0.0, coord['longitude'] ?? 0.0))
            .toList();
        if (pathPoints.isNotEmpty) {
          _routeCoordinates = pathPoints;
        }
      }

      notifyListeners();
      debugPrint(
          '트래킹 상태 복원 완료: ${trackingData.mountain.name}, ${trackingData.path.name}');
      return true;
    } catch (e) {
      debugPrint('트래킹 상태 확인 오류: $e');
      return false;
    }
  }

  // 트래킹 종료
  void endTracking() {
    _isTracking = false;
    _trackingStage = TrackingStage.search;
    _selectedMountain = null;
    _selectedRoute = null;
    _selectedMode = null;
    _modeData = null; // 모드 데이터 초기화
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
