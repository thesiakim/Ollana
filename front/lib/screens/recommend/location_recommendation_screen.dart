// lib/screens/recommend/location_recommendation_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart'; // 🔥 추가

class LocationRecommendationScreen extends StatelessWidget {
  const LocationRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(), // 🔥 CustomAppBar 적용
      body: const Center(
        child: Text(
          '사용자의 현재 위치를 기반으로 추천된 산 목록이 여기에 표시됩니다.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
