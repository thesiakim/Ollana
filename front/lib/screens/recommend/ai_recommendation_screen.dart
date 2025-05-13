// lib/screens/recommend/ai_recommendation_screen.dart
import 'package:flutter/material.dart';

class AiRecommendationScreen extends StatelessWidget {
  const AiRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 맞춤형 산 추천'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'AI 알고리즘으로 추천된 산 목록이 여기에 표시됩니다.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
