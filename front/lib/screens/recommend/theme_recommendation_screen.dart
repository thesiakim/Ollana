// lib/screens/recommend/theme_recommendation_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart'; // 🔥 추가

class ThemeRecommendationScreen extends StatelessWidget {
  const ThemeRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(), // 🔥 CustomAppBar 적용
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('테마를 선택하세요:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () {}, child: const Text('계곡')),
            ElevatedButton(onPressed: () {}, child: const Text('아름다운')),
            ElevatedButton(onPressed: () {}, child: const Text('단풍')),
          ],
        ),
      ),
    );
  }
}
