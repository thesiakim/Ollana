// status_info_pages.dart
// - 사용자 상태 정보 페이지 위젯들
// - FirstStatusInfo: 첫 번째 상태 정보 페이지 (등산 지수)
// - SecondStatusInfo: 두 번째 상태 정보 페이지 (한라산 성장 일지)

import 'package:flutter/material.dart';

class FirstStatusInfo extends StatelessWidget {
  const FirstStatusInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            '등산지수',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '78',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.green,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(2, 2),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SecondStatusInfo extends StatelessWidget {
  const SecondStatusInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // 사용 가능한 공간에 따라 크기 조절
      double fontSize = constraints.maxHeight < 150 ? 11.0 : 13.0;
      double spacing = constraints.maxHeight < 150 ? 2.0 : 2.0;
      double iconSize = constraints.maxHeight < 150 ? 8.0 : 10.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 등산 성장 일지 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                width: 80,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('등산 성장 일지 버튼 클릭');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    textStyle: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('등산 성장 일지'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 성장 정보
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '한라산',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    '(25.04.23)',
                    style: TextStyle(
                      fontSize: fontSize - 1,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: spacing),
                  const Text(
                    '걸린 시간',
                    style: TextStyle(color: Colors.red, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const Text(
                    '2h 26m → 2h 10m',
                    style: TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_upward,
                            color: Colors.green, size: iconSize),
                        const Flexible(
                          child: Text(
                            ' 16분 단축',
                            style: TextStyle(color: Colors.green, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing),
                  const Text(
                    '총 등반 거리',
                    style: TextStyle(color: Colors.blue, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const Text(
                    '8.3km',
                    style: TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
