// home_body.dart: 메인 화면의 본문 영역 구현
// - HomeBody: 메인 화면의 콘텐츠 영역 구현 (추천 코스, 검색 바 등)
// - 로그인 여부에 따라 다른 UI 표시
// - 로그인 상태에서 사용자의 현재 상태 정보 표시
// - 추천 코스 목록 표시

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/course_data.dart';
import '../widgets/image_course_card.dart';
import '../widgets/status_container.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  // PageController 추가
  final PageController _pageController = PageController();
  int _currentStatusPage = 0;

  // CardData 리스트 생성
  final List<CardData> cards = List.generate(
    5,
    (i) => CardData(
      id: i + 1,
      gradient: [
        Colors.primaries[i * 2 % Colors.primaries.length].shade400,
        Colors.primaries[(i * 2 + 1) % Colors.primaries.length].shade300,
      ],
    ),
  );

  final double cardPaddingVertical = 4.0;
  final double cardPaddingHorizontal = 10.0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 로그인 여부에 따라 다른 컨테이너 표시
          appState.isLoggedIn
              ? StatusContainer(
                  pageController: _pageController,
                  currentStatusPage: _currentStatusPage,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStatusPage = index;
                    });
                  },
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withAlpha(30),
                      width: 1.5,
                    ),
                  ),
                  child: const Text(
                    '로그인을 하고 등산할 산과 코스를 추천받으세요!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '관심있는 산을 검색하세요.',
                      hintStyle:
                          TextStyle(color: Colors.grey[500], fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 1.0),
                  child: Text(
                    '추천 코스',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 이미지 카드 리스트를 보여줌
                Expanded(
                  child: ListView.builder(
                    itemCount: courseList.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      return ImageCourseCard(course: courseList[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
