// lib/widgets/status_container.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP 요청
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // .env 읽기용

import '../models/app_state.dart';
import 'status_info_pages.dart';
import 'experience_bar.dart';

class StatusContainer extends StatefulWidget {
  final PageController pageController;
  final int currentStatusPage;
  final ValueChanged<int> onPageChanged;

  const StatusContainer({
    Key? key,
    required this.pageController,
    required this.currentStatusPage,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  _StatusContainerState createState() => _StatusContainerState();
}

class _StatusContainerState extends State<StatusContainer> {
  String _grade = 'SEED';
  int _exp = 0;

  @override
  void initState() {
    super.initState();
    _fetchFootprint();
  }

  Future<void> _fetchFootprint() async {
    try {
      final baseUrl = dotenv.env['BASE_URL']!;
      final url = Uri.parse('$baseUrl/footprint/main');
      final token = Provider.of<AppState>(context, listen: false).accessToken;

      final resp = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      });

      if (resp.statusCode == 200) {
        final body =
            json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        final user = body['data']?['user'] as Map<String, dynamic>?;
        if (user != null) {
          setState(() {
            _grade = user['grade'] as String? ?? 'SEED';
            _exp = (user['exp'] as num?)?.toInt() ?? 0;
          });
          debugPrint('▶ grade=$_grade, exp=$_exp');
        }
      } else {
        debugPrint('▶ Footprint API error: HTTP ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('▶ Footprint API exception: $e');
    }
  }

  String _assetForGrade(String grade) {
    switch (grade) {
      case 'SEED':
        return 'lib/assets/images/level_one.png';
      case 'SPROUT':
        return 'lib/assets/images/level_two.png';
      case 'TREE':
        return 'lib/assets/images/level_three.png';
      case 'FRUIT':
        return 'lib/assets/images/level_four.png';
      case 'MOUNTAIN':
        return 'lib/assets/images/level_five.png';
      default:
        return 'lib/assets/images/level_one.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeAsset = _assetForGrade(_grade);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8FCEC), // 연한 민트 그린
            Color(0xFFD6F9D9), // 좀 더 짙은 민트
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 왼쪽: 등급 배지 + ExperienceBar
            SizedBox(
              width: 120,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 뱃지
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(badgeAsset, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 경험치 바
                  ExperienceBar(currentXp: _exp, grade: _grade),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // 오른쪽: PageView + 인디케이터
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 140,
                      child: PageView(
                        controller: widget.pageController,
                        onPageChanged: widget.onPageChanged,
                        children: const [
                          FirstStatusInfo(),
                          SecondStatusInfo(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (i) {
                        final isActive = i == widget.currentStatusPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: isActive ? 12 : 8,
                          height: isActive ? 12 : 8,
                          decoration: BoxDecoration(
                            color:
                                isActive ? Colors.green[800] : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
