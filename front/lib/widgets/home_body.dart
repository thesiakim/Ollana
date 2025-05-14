// lib/widgets/home_body.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../widgets/status_container.dart';
import '../screens/recommend/ai_recommendation_screen.dart';
import '../screens/recommend/theme_recommendation_screen.dart';
import '../screens/recommend/location_recommendation_screen.dart';
import '../screens/user/survey_screen.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final PageController _pageController = PageController();
  int _currentStatusPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchSurveyStatus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    
    // 앱의 주요 컬러 정의
    final primaryColor = const Color(0xFF52A486);
    final secondaryColor = const Color(0xFF7BBD9F);
    final backgroundColor = const Color(0xFFF9FCFA);
    
    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더 섹션
            if (appState.isLoggedIn) ...[
              // 상태 컨테이너 (기존 StatusContainer 위젯 활용)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: StatusContainer(
                    pageController: _pageController,
                    currentStatusPage: _currentStatusPage,
                    onPageChanged: (i) => setState(() => _currentStatusPage = i),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ] else ...[
              // 로그인 유도 카드
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.8), secondaryColor.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.01),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.nature_people,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '로그인을 하고 등산할 산과 코스를\n 추천 받으세요!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // 로그인 화면으로 이동하는 로직 추가
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '로그인하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // AI 추천 카드
            RecommendationCard(
              title: 'AI 맞춤 산 추천',
              description: '내 취향과 경험에 맞는 최적의 산을 찾아보세요',
              iconData: Icons.auto_awesome,
              iconBgColor: const Color(0xFF52A486),
              imagePath: 'lib/assets/images/ai_recommend.png',
              onTap: () {
                if (!appState.surveyCompleted) {
                  _showSurveyDialog(context, primaryColor);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiRecommendationScreen()),
                  );
                }
              },
            ),

            // 테마별 추천 카드
            RecommendationCard(
              title: '테마별 등산 추천',
              description: '계절, 난이도에 맞는 특별한 등산 코스를 찾아보세요',
              iconData: Icons.category,
              iconBgColor: const Color(0xFF5C8D89),
              imagePath: 'lib/assets/images/theme_recommend.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeRecommendationScreen()),
              ),
            ),

            // 현재 위치 추천 카드
            RecommendationCard(
              title: '현재 위치 등산 추천',
              description: '내 주변의 산과 등산로를 확인해보세요',
              iconData: Icons.location_on,
              iconBgColor: const Color(0xFF6A8EAE),
              imagePath: 'lib/assets/images/location_recommend.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationRecommendationScreen()),
              ),
            ),
            
            // 하단 여백
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSurveyDialog(BuildContext context, Color primaryColor) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note,
                  color: primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '설문 작성 안내',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '맞춤형 AI 추천을 받으려면 간단한 설문이 필요합니다. 당신의 등산 취향과 경험을 알려주세요!',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      '나중에 하기',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SurveyScreen()),
                      );
                    },
                    child: const Text(
                      '설문 시작하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecommendationCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData iconData;
  final Color iconBgColor;
  final String imagePath;
  final VoidCallback onTap;

  const RecommendationCard({
    required this.title,
    required this.description,
    required this.iconData,
    required this.iconBgColor,
    required this.imagePath,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 아이콘 섹션
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: iconBgColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              
              // 텍스트 섹션
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 화살표 아이콘
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}