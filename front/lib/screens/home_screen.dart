// home_screen.dart: 앱의 메인 화면 구성 및 레이아웃 정의
// - HomeScreen: 앱 바, 바텀 내비게이션 바, 메인 콘텐츠 영역 구성
// - IndexedStack을 사용하여 탭 전환 시 상태 유지
// - 사용자 인터페이스의 주요 레이아웃과 기능을 구현하는 화면

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_footer.dart';
import '../widgets/home_body.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return IndexedStack(
            index: appState.currentPageIndex,
            children: [
              HomeBody(),
              Center(child: Text('트래킹 페이지')),
              Center(child: Text('산 정보 페이지')),
              Center(child: Text('나의 발자취 페이지')),
              Center(child: Text('마이페이지')),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomFooter(),
    );
  }
}
