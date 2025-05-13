// lib/widgets/home_body.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../widgets/status_container.dart';
import '../screens/recommend/ai_recommendation_screen.dart';
import '../screens/recommend/theme_recommendation_screen.dart';
import '../screens/recommend/location_recommendation_screen.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final PageController _pageController = PageController();
  int _currentStatusPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // 은은한 연두빛 계열 그라데이션 (모든 카테고리 동일)
    final softGreenGradient = const LinearGradient(
      colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (appState.isLoggedIn) ...[
            StatusContainer(
              pageController: _pageController,
              currentStatusPage: _currentStatusPage,
              onPageChanged: (i) => setState(() => _currentStatusPage = i),
            ),
            const SizedBox(height: 24),
            CategoryFrame(
              label: '내 맞춤 AI 산 추천',
              imagePath: 'lib/assets/images/ai_recommend.png',
              gradient: softGreenGradient, // 은은한 연두 그라데이션
              borderColor: Colors.grey.withOpacity(0.3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AiRecommendationScreen()),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 10.0, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withAlpha(30),
                  width: 1.5,
                ),
              ),
              child: const Text(
                '로그인을 하고 등산할 산과 코스를\n 추천 받으세요!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // 테마별 등산 추천 (항상 표시)
          CategoryFrame(
            label: '테마별 등산 추천',
            imagePath: 'lib/assets/images/theme_recommend.png',
            gradient: softGreenGradient, // 동일한 은은한 연두 그라데이션
            borderColor: Colors.grey.withOpacity(0.3),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ThemeRecommendationScreen()),
            ),
          ),

          // 현재 위치 등산 추천 (항상 표시)
          CategoryFrame(
            label: '현재 위치 등산 추천',
            imagePath: 'lib/assets/images/location_recommend.png',
            gradient: softGreenGradient,
            borderColor: Colors.grey.withOpacity(0.3),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const LocationRecommendationScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryFrame extends StatelessWidget {
  final String label;
  final String imagePath;
  final LinearGradient gradient;
  final Color borderColor;
  final VoidCallback onTap;

  const CategoryFrame({
    required this.label,
    required this.imagePath,
    required this.gradient,
    required this.borderColor,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2), // 테두리만
          // 그림자 제거
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // 텍스트 검정
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            ClipOval(
              child: Image.asset(
                imagePath,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
