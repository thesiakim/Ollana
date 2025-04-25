// custom_app_bar.dart: 앱 상단의 커스텀 앱바 위젯 구현
// - PreferredSizeWidget을 구현하여 AppBar 위치에 사용 가능
// - 로고 버튼과 로그인/로그아웃 버튼 배치
// - 앱의 브랜딩과 사용자 인증 상태를 표시하는 UI 컴포넌트
// - 스타일 속성으로 디자인 커스터마이징

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      height: kToolbarHeight + statusBarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: statusBarHeight),
          Expanded(
            child: Row(
              children: [
                _buildLogoButton(context),
                const Spacer(),
                _buildLoginButton(context, appState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: TextButton(
        onPressed: () {
          context.read<AppState>().changePage(0);
        },
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(Colors.black),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: const Text(
          "Ollana",
          style: TextStyle(
            overflow: TextOverflow.ellipsis,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: TextButton(
        onPressed: appState.toggleLogin,
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(Colors.black),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Text(appState.isLoggedIn ? "logout" : "login"),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
