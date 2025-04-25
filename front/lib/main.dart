// main.dart: 앱의 진입점 및 기본 설정을 정의하는 파일

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'models/app_state.dart';
import 'screens/home_screen.dart';

void main() {
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
