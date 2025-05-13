// lib/screens/recommend/theme_recommendation_screen.dart
import 'package:flutter/material.dart';

class ThemeRecommendationScreen extends StatelessWidget {
  const ThemeRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('테마별 등산 추천'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '테마를 선택하세요:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: 계곡 테마 선택 로직
              },
              child: const Text('계곡'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: 숲 테마 선택 로직
              },
              child: const Text('숲'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: 단풍 테마 선택 로직
              },
              child: const Text('단풍'),
            ),
          ],
        ),
      ),
    );
  }
}