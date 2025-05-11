// main.dart: 앱의 진입점 및 기본 설정을 정의하는 파일

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme.dart';
import 'models/app_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 1번코드
  await dotenv.load(fileName: ".env");

  // 네이버 지도 초기화 - NaverMapSdk는 deprecated지만 현재 가장 안정적으로 작동함
  // ignore: deprecated_member_use
  await FlutterNaverMap().init(
    clientId: dotenv.get('NAVER_MAP_CLIENT_ID'),
    onAuthFailed: (ex) {
      // ex는 NAuthFailedException
      debugPrint('Naver Map Auth Failed: $ex');
    },
  );

  // - SystemChrome.setSystemUIOverlayStyle: 상태 바 색상 및 아이콘 밝기 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.green,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    // - ChangeNotifierProvider: 앱 상태 관리를 위한 Provider 설정
    ChangeNotifierProvider(create: (_) => AppState(), child: const MyApp()),
  );
}

// - MyApp: 앱의 루트 위젯 정의 (테마 및 홈 화면 설정)
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isCheckingTrackingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkTrackingStatus();
  }

  // 앱 시작 시 등산 상태 확인
  Future<void> _checkTrackingStatus() async {
    // AppState 가져오기
    final appState = Provider.of<AppState>(context, listen: false);

    // 등산 상태 확인
    final hasActiveTracking = await appState.checkTrackingStatus();

    if (mounted) {
      setState(() {
        _isCheckingTrackingStatus = false;
      });

      if (hasActiveTracking) {
        debugPrint('활성화된 등산 발견: 등산 화면으로 이동합니다.');
        // 등산 화면으로 자동 이동하는 코드는 필요하지 않음
        // AppState의 상태 변경으로 자동으로 해당 화면이 표시됨
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 등산 상태 확인 중일 때 로딩 화면
    if (_isCheckingTrackingStatus) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Ollana',
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
