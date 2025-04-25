// custom_footer.dart: 앱 하단의 네비게이션 바 위젯 구현
// - 홈, 검색, 프로필 등의 주요 페이지로 이동할 수 있는 탭 구성
// - 현재 선택된 탭을 색상으로 강조 표시
// - AppState를 통해 페이지 전환 상태 관리
// - 앱의 주요 화면 간 이동을 제공하는 네비게이션 컴포넌트

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 45 + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFooterButton(context, 0, Icons.home),
              _buildFooterButton(context, 1, Icons.approval_rounded),
              _buildFooterButton(context, 2, Icons.area_chart_rounded),
              _buildFooterButton(context, 3, FontAwesomeIcons.shoePrints),
              _buildFooterButton(context, 4, Icons.person),
            ],
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildFooterButton(
    BuildContext context,
    int index,
    IconData icon,
  ) {
    final appState = context.watch<AppState>();
    final isSelected = appState.currentPageIndex == index;

    // 발자취 아이콘(shoePrints)인 경우에만 회전 적용
    Widget iconWidget = icon == FontAwesomeIcons.shoePrints
        ? Transform.rotate(
            angle: -1.7, // 약 28.6도 회전 (라디안 단위)
            child: Icon(icon, color: isSelected ? Colors.green : Colors.grey),
          )
        : Icon(icon, color: isSelected ? Colors.green : Colors.grey);

    return GestureDetector(
      onTap: () => appState.changePage(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
        ],
      ),
    );
  }
}
