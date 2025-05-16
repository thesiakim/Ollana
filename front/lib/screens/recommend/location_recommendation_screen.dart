// lib/screens/recommend/location_recommendation_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../utils/ai_utils.dart';
import '../../widgets/recommend/mountain_detail_dialog.dart';

Map<String, dynamic> _parseJson(String body) => jsonDecode(body);

class LocationRecommendationScreen extends StatefulWidget {
  const LocationRecommendationScreen({Key? key}) : super(key: key);

  @override
  _LocationRecommendationScreenState createState() =>
      _LocationRecommendationScreenState();
}

class _LocationRecommendationScreenState
    extends State<LocationRecommendationScreen> with SingleTickerProviderStateMixin {
  final List<String> _regions = [
    '서울',
    '경기',
    '강원',
    '충청',
    '경상',
    '전라',
  ]; // ▶ 사용자가 선택할 수 있는 지역 리스트

  String? _selectedRegion; // ▶ 사용자가 선택한 지역
  Future<Map<String, dynamic>>? _futureRecos; // ▶ API 결과 Future
  
  // 테마 색상
  final Color _primaryColor = const Color(0xFF52A486);
  final Color _secondaryColor = const Color(0xFF3D7A64);
  final Color _backgroundColor = const Color(0xFFF9F9F9);
  final Color _accentColor = const Color(0xFFFFA270);
  final Color _textColor = const Color(0xFF333333);
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedRegion = _regions.first; // ▶ 초기 선택값
    
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchByRegion(String region) async {
    final url = Uri.parse('${dotenv.get('AI_BASE_URL')}/recommend_by_region');
    
    try {
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'region': region}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('요청 시간이 초과되었습니다.'),
          );

      if (resp.statusCode != 200) {
        throw Exception('서버 오류 (${resp.statusCode})');
      }

      final bodyString = utf8.decode(resp.bodyBytes);
      final data = await compute(_parseJson, bodyString);
      data['recommendations'] ??= [];
      return data;
    } catch (e) {
      debugPrint('⚠️ _fetchByRegion 에러: $e');
      rethrow;
    }
  }

  void _onRecommendPressed() {
    if (_selectedRegion == null) return;
    setState(() {
      // ▶ 사용자가 선택한 지역으로 Future 재생성
      _futureRecos = _fetchByRegion(_selectedRegion!);
      _animationController.reset();
      _animationController.forward();
    });
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(_primaryColor),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '추천 산을 불러오는 중',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '잠시만 기다려주세요',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: _accentColor,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '오류가 발생했습니다',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _futureRecos = _fetchByRegion(_selectedRegion!);
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32, 
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 70,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '추천된 산이 없습니다',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                '다른 지역을 선택해보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 80,
            color: _primaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Text(
            '지역을 선택하고',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"추천 보기"를 눌러주세요',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF333333),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '지역별 추천',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ),
      body: Column(
        children: [
          // 선택 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.map_outlined,
                        size: 28,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '원하는 지역을 선택하세요',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '선택한 지역에 있는 산을 추천해드립니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // 커스텀 드롭다운 메뉴 표시
                              _showCustomDropdown(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedRegion ?? '지역 선택',
                                    style: TextStyle(
                                      color: _textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: _primaryColor,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _onRecommendPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20, 
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '추천 보기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 결과 영역
          Expanded(
            child: _futureRecos == null
                ? _buildInitialView()
                : FutureBuilder<Map<String, dynamic>>(
                    future: _futureRecos,
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return _buildLoadingView();
                      }
                      if (snap.hasError) {
                        return _buildErrorView(snap.error.toString());
                      }
                      final data = snap.data!;
                      final recs = data['recommendations'] as List<dynamic>;
                      if (recs.isEmpty) {
                        return _buildEmptyView();
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        itemCount: recs.length,
                        itemBuilder: (ctx, i) {
                          final rec = recs[i] as Map<String, dynamic>;
                          final name = rec['mountain_name'] as String? ?? '';
                          final desc = rec['mountain_description'] as String? ?? '';
                          final rawImg = rec['image_url'] as String?;
                          final imgUrl = formatImageUrl(rawImg);

                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    spreadRadius: 1,
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => MountainDetailDialog(
                                        mountain: rec,
                                        primaryColor: _primaryColor,
                                        textColor: _textColor,
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                        child: Stack(
                                          children: [
                                            imgUrl != null
                                                ? Image.network(
                                                    imgUrl,
                                                    height: 200,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (ctx, child, progress) {
                                                      if (progress == null) return child;
                                                      return Container(
                                                        height: 200,
                                                        width: double.infinity,
                                                        color: Colors.grey.shade200,
                                                        child: Center(
                                                          child: CircularProgressIndicator(
                                                            value: progress.expectedTotalBytes != null
                                                                ? progress.cumulativeBytesLoaded /
                                                                    progress.expectedTotalBytes!
                                                                : null,
                                                            valueColor:
                                                                AlwaysStoppedAnimation(_primaryColor),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (ctx, err, st) {
                                                      return Image.asset(
                                                        'lib/assets/images/mount_default.png',
                                                        height: 200,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                : Image.asset(
                                                    'lib/assets/images/mount_default.png',
                                                    height: 200,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                            // 산 이름 영역
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 8,
                                                ),
                                                child: Row(
                                                  children: [
                                                    // 아이콘에 테두리 효과 추가
                                                    Stack(
                                                      children: [
                                                        // 테두리를 위한 아이콘 (검은색)
                                                        const Icon(
                                                          Icons.terrain,
                                                          color: Colors.black,
                                                          size: 24, // 약간 더 크게 설정하여 테두리 효과
                                                        ),
                                                        // 원래 아이콘
                                                        const Icon(
                                                          Icons.terrain,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // 텍스트에 테두리 효과 추가
                                                    Expanded(
                                                      child: Stack(
                                                        children: [
                                                          // 테두리 효과를 위한 텍스트
                                                          Text(
                                                            name,
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                              foreground: Paint()
                                                                ..style = PaintingStyle.stroke
                                                                ..strokeWidth = 3
                                                                ..color = Colors.black,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          // 원래의 텍스트
                                                          Text(
                                                            name,
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                              shadows: [
                                                                Shadow(
                                                                  offset: Offset(1, 1),
                                                                  blurRadius: 3,
                                                                  color: Color.fromARGB(150, 0, 0, 0),
                                                                ),
                                                              ],
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              desc,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 16,
                                                height: 1.5,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) => MountainDetailDialog(
                                                        mountain: rec,
                                                        primaryColor: _primaryColor,
                                                        textColor: _textColor,
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.visibility),
                                                  label: const Text('자세히 보기'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: _primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

    // 커스텀 드롭다운 메뉴 표시
  void _showCustomDropdown(BuildContext context) {
    // 더 안정적인 방법으로 드롭다운 메뉴 구현
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '지역 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _regions.length,
                  itemBuilder: (context, index) {
                    final region = _regions[index];
                    final isSelected = region == _selectedRegion;
                    
                    return ListTile(
                      title: Text(
                        region,
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      leading: isSelected 
                          ? Icon(Icons.check_circle, color: _primaryColor) 
                          : const Icon(Icons.circle_outlined, color: Colors.grey),
                      onTap: () {
                        setState(() {
                          _selectedRegion = region;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}