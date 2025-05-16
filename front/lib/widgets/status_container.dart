// status_container.dart
import 'package:flutter/material.dart';
import 'status_info_pages.dart';

class StatusContainer extends StatelessWidget {
  final PageController pageController;
  final int currentStatusPage;
  final Function(int) onPageChanged;

  const StatusContainer({
    super.key,
    required this.pageController,
    required this.currentStatusPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 전체 넓이 꽉, 높이 최소200 최대220
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 220),
      padding: const EdgeInsets.all(16), // 안쪽 여백
      margin: const EdgeInsets.only(top: 16), // 위쪽 바깥 여백
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─────────── 왼쪽 영역 (캐릭터 + 경험치) ───────────
          SizedBox(
            width: 80, // 고정 너비
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1) 캐릭터 이미지
                Container(
                  width: 70, height: 70, // 이미지 크기
                  decoration: BoxDecoration(
                    color: Colors.orange[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset('lib/assets/images/seed.png'),
                  ),
                ),

                const SizedBox(height: 12), // 이미지 ↔ 경험치 텍스트 간격

                // 2) 경험치 바
                Column(
                  children: [
                    const Text('경험치', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      height: 8, // 바 높이
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 35, // 현재 XP 비율에 맞춰 조절 가능
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.yellow[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('100xp', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16), // 왼쪽 ↔ 오른쪽 간격

          // ─────────── 오른쪽 영역 (PageView + 인디케이터) ───────────
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1) PageView 높이 지정
                SizedBox(
                  height: 140, // 실제 페이지 컨텐츠 높이
                  child: PageView(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    children: const [
                      FirstStatusInfo(),
                      SecondStatusInfo(),
                    ],
                  ),
                ),

                const SizedBox(height: 12), // PageView ↔ 인디케이터 간격

                // 2) 페이지 인디케이터
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentStatusPage == i
                            ? Colors.black
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
