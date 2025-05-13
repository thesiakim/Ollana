// lib/screens/recommend/ai_recommendation_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart'; // 🔥 추가

class AiRecommendationScreen extends StatelessWidget {
  const AiRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(), // 🔥 CustomAppBar 적용
      body: const Center(
        child: Text(
          'AI 알고리즘으로 추천된 산 목록이 여기에 표시됩니다.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
