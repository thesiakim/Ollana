// lib/widgets/experience_bar.dart - 원래 조건 유지, 디자인만 변경
import 'package:flutter/material.dart';

/// 등급별 레벨업에 필요한 EXP - 원래 값 그대로 유지
const _xpThresholds = {
  'SEED': 100,
  'SPROUT': 300,
  'TREE': 500,
  'FRUIT': 800,
  'MOUNTAIN': 1000,
};

class ExperienceBar extends StatelessWidget {
  final int currentXp;
  final String grade;

  const ExperienceBar({
    Key? key,
    required this.currentXp,
    required this.grade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final xpForNext = _xpThresholds[grade] ?? 100; // 원래 값 사용
    final progress = (currentXp / xpForNext).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 프로그레스 바
            Stack(
              children: [
                // 배경
                Container(
                  width: fullWidth,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9), // 연한 녹색 배경
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                // 채움
                Container(
                  width: fullWidth * progress,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8BC34A), Color(0xFF4CAF50)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            
            // 목표 XP - 프로세스바 아래에 배치
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end, // 오른쪽 정렬
                children: [
                  Text(
                    '${xpForNext}xp',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}