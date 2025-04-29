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
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ollana',
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
