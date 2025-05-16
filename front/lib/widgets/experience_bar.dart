// lib/widgets/experience_bar.dart
import 'package:flutter/material.dart';

/// 등급별 레벨업에 필요한 EXP
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
    final xpForNext = _xpThresholds[grade] ?? 100;
    final progress = (currentXp / xpForNext).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 이 constraints.maxWidth 만큼만 차지
        final fullWidth = constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress 텍스트
            Row(
              children: [
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {}, // 닫기 로직
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ▼ 이 부분이 실제 프로그레스 바
            Stack(
              children: [
                // 배경 바
                Container(
                  width: fullWidth,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                // 채워진 바
                Container(
                  width: fullWidth * progress,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // 필요 XP
            Row(
              children: [
                const Spacer(),
                Text(
                  '목표 ${xpForNext}xp',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // 현재 XP
            Text(
              '현재 ${currentXp}xp',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        );
      },
    );
  }
}
