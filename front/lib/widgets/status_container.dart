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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      margin: const EdgeInsets.only(top: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽 영역 (상태 타이틀, 캐릭터, 경험치)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 캐릭터 이미지
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange[300]!, Colors.orange[100]!],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'lib/assets/images/seed.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 경험치 바
              SizedBox(
                width: 80,
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        // 배경 바
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // 채워진 바
                        Container(
                          width: 40, // 경험치 50% 가정
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber[300]!, Colors.amber[500]!],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '100/200 XP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),

          // 오른쪽 영역 (스와이프 정보)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 고정 높이 SizedBox 사용하여 PageView 높이 명시적 지정
                SizedBox(
                  height: 155,
                  child: PageView(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    children: [
                      FirstStatusInfo(),
                      SecondStatusInfo(),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 페이지 인디케이터 개선
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: currentStatusPage == 0 ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentStatusPage == 0 
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: currentStatusPage == 1 ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentStatusPage == 1
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
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