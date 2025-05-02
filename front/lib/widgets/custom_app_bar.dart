import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../screens/user/login_screen.dart';

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
          foregroundColor: MaterialStateProperty.all(Colors.black),
          padding: MaterialStateProperty.all(EdgeInsets.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
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
        onPressed: () {
          if (appState.isLoggedIn) {
            // 로그아웃 처리
            appState.toggleLogin();
          } else {
            // 로그인 페이지로 이동
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
            );
          }
        },
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(Colors.black),
          padding: MaterialStateProperty.all(EdgeInsets.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
        child: Text(
          appState.isLoggedIn ? "Logout" : "Login",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
