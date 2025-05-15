// status_container.dart
// - 로그인 상태 사용자의 상태 정보 컨테이너 위젯
// - 캐릭터 이미지, 경험치 바, 상태 정보 표시
// - PageView를 통한 상태 정보 페이지 스와이프 기능 제공

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
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 10.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽 영역 (상태 타이틀, 캐릭터, 경험치)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 캐릭터 이미지
              Container(
                width: 70, // 크기 축소
                height: 70, // 크기 축소
                decoration: BoxDecoration(
                  color: Colors.orange[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset('lib/assets/images/seed.png'),
                ),
              ),

              const SizedBox(height: 16),

              // 경험치 바
              SizedBox(
                width: 70, // 캐릭터 이미지와 동일한 너비
                child: Column(
                  children: [
                    const Text('경험치', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      height: 10, // 높이 줄임
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 35, // 경험치 바 크기 조정
                            height: 10, // 높이 줄임
                            decoration: BoxDecoration(
                              color: Colors.yellow[300],
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('100xp', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(width: 12), // 좌우 간격 줄임

          // 오른쪽 영역 (스와이프 정보)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 고정 높이 SizedBox 사용하여 PageView 높이 명시적 지정
                SizedBox(
                  height: 160, // 높이 줄임
                  child: PageView(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    children: [
                      FirstStatusInfo(),
                      SecondStatusInfo(),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 페이지 인디케이터
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentStatusPage == 0
                            ? Colors.black
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentStatusPage == 1
                            ? Colors.black
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
