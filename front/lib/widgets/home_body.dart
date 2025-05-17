import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../models/app_state.dart';
import '../screens/recommend/ai_recommendation_screen.dart';
import '../screens/recommend/theme_recommendation_screen.dart';
import '../screens/recommend/location_recommendation_screen.dart';
import '../screens/user/survey_screen.dart';
import './status_container.dart';
import '../../screens/user/login_screen.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final PageController _pageController = PageController();
  int _currentStatusPage = 0;
  bool _isLoading = false;

  // HomeBody 클래스의 initState 메서드 수정 (등산지수 데이터 로드 추가)
@override
void initState() {
  super.initState();
  // 안전하게 비동기 작업 시작
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeData();
  });
}

// 데이터 초기화 메서드 수정
Future<void> _initializeData() async {
  // UI가 멈추지 않도록 지연 추가
  await Future.delayed(Duration.zero);

  if (!mounted) return;

  // 비동기 작업 시작
  setState(() {
    _isLoading = true;
  });

  try {
    final appState = context.read<AppState>();
    
    // 설문 상태 가져오기
    await Future.microtask(() => appState.fetchSurveyStatus());
    
    // 등산지수 가져오기 (로그인된 경우만)
    if (appState.isLoggedIn) {
      await Future.microtask(() => appState.fetchClimbingIndex());
      debugPrint('등산지수 로드 완료: ${appState.climbingIndex}');
    }
  } catch (e) {
    // 오류 처리
    debugPrint('데이터 초기화 실패: $e');
    if (mounted) {
      Future.microtask(() {
        _showErrorSnackBar('데이터를 불러오는 중 오류가 발생했습니다');
      });
    }
  } finally {
    // 작업 완료, 로딩 상태 해제
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // AI 추천 화면으로 이동하는 메서드
  Future<void> _navigateToAiRecommendation() async {
    if (!mounted) return;

    final appState = context.read<AppState>();

    // 설문 완료 여부 확인
    if (!appState.surveyCompleted) {
      _showSurveyDialog();
    } else {
      // 로딩 표시
      final loadingOverlay = _showLoadingOverlay(context);

      try {
        // 필요한 데이터 로드
        await Future.delayed(const Duration(milliseconds: 300));
        loadingOverlay.remove();

        if (mounted) {
          // 화면 전환
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AiRecommendationScreen()),
          );
        }
      } catch (e) {
        loadingOverlay.remove();
        if (mounted) {
          _showErrorSnackBar('추천 데이터를 불러오는 중 오류가 발생했습니다');
        }
      }
    }
  }

  // 로딩 오버레이 표시 메서드
  OverlayEntry _showLoadingOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.3),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Color(0xFF64B792),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '로딩중...',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    return overlayEntry;
  }

  // 설문 안내 다이얼로그 표시
  void _showSurveyDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 아이콘
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF64B792).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF64B792),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              
              // 제목
              const Text(
                '설문 작성 안내',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              
              // 내용
              const Text(
                '맞춤형 산 추천을 받으시려면\n간단한 설문이 필요합니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 24),
              
              // 버튼 영역
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF666666),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '나중에 할게요',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _navigateToSurvey();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64B792),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '설문하기',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 설문 화면으로 이동
  Future<void> _navigateToSurvey() async {
    if (!mounted) return;

    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SurveyScreen()),
      );

      // 설문이 완료되었으면 상태 갱신
      if (result == true && mounted) {
        // 로딩 표시
        final loadingOverlay = _showLoadingOverlay(context);

        try {
          // 설문 상태 다시 가져오기
          await Future.microtask(() async {
            await context.read<AppState>().fetchSurveyStatus();
          });

          loadingOverlay.remove();

          if (mounted && context.read<AppState>().surveyCompleted) {
            // 설문 완료 상태라면 바로 AI 추천 화면으로 이동
            await Future.delayed(const Duration(milliseconds: 300));
            _navigateToAiRecommendation();
          }
        } catch (e) {
          loadingOverlay.remove();
          if (mounted) {
            _showErrorSnackBar('설문 상태 업데이트 중 오류가 발생했습니다');
          }
        }
      }
    } catch (e) {
      debugPrint('설문 화면 이동 오류: $e');
      if (mounted) {
        _showErrorSnackBar('설문 화면을 불러오는 중 오류가 발생했습니다');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    debugPrint('HomeBody build: 등산지수 = ${appState.climbingIndex}');

    return Container(
      color: const Color(0xFFFAFAFA),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 영역
              _buildHeaderSection(appState),
              
              // 컨텐츠 영역
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (appState.isLoggedIn) ...[
                      const SizedBox(height: 24),
                      
                      // 상태 컨테이너
                      StatusContainer(
                        pageController: _pageController,
                        currentStatusPage: _currentStatusPage,
                        onPageChanged: (i) => setState(() => _currentStatusPage = i),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 맞춤형 추천 섹션
                      _buildSectionHeader(
                        title: '맞춤형 추천',
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFFF7043),
                      ),
                      const SizedBox(height: 16),
                      _buildRecommendationCard(
                        title: '나만의 맞춤 추천',
                        description: '취향에 맞는 완벽한 산을 찾아보세요',
                        image: 'lib/assets/images/ai_recommend.png',
                        backgroundColor: const Color(0xFF64B792),
                        onTap: _navigateToAiRecommendation,
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      _buildLoginPrompt(),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // 테마별 추천 섹션
                    _buildSectionHeader(
                      title: '주제별 추천',
                      icon: Icons.category_rounded,
                      color: const Color(0xFF42A5F5),
                    ),
                    const SizedBox(height: 16),
                    
                    // 테마별 카드 그리드
                    SizedBox(
                      height: 140, // 고정 높이
                      child: Row(
                        children: [
                          // 테마별 카드
                          Expanded(
                            child: _buildSmallRecommendationCard(
                              title: '테마별 산 추천',
                              icon: Icons.landscape_rounded,
                              backgroundColor: const Color(0xFF26A69A),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ThemeRecommendationScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // 지역별 카드
                          Expanded(
                            child: _buildSmallRecommendationCard(
                              title: '지역별 산 추천',
                              icon: Icons.map_rounded,
                              backgroundColor: const Color(0xFF5C6BC0),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LocationRecommendationScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 로딩 표시기
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF64B792),
                          ),
                        ),
                      ),
                    
                    // 여백
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeaderSection(AppState appState) {
    debugPrint('_buildHeaderSection: 등산지수 = ${appState.climbingIndex}');
    
    // 등산지수 메시지 관련 로직
    String _climateMessage = '';
    Color _climateMessageColor = Colors.grey;
    
    // 등산지수 값 가져오기
    final int _climbingIndex = appState.climbingIndex ?? 0;
    
    // 디버깅 출력
    debugPrint('등산지수 값: $_climbingIndex');
    
    // 점수에 따른 메시지와 색상 설정
    if (_climbingIndex > 0) {  // 등산지수가 있는 경우에만 메시지 설정
      if (_climbingIndex < 50) {
        _climateMessage = '오늘은 등산하기 좋지 않아요';
        _climateMessageColor = const Color(0xFFEF5350); // 빨강
      } else if (_climbingIndex < 80) {
        _climateMessage = '오늘은 적당한 등산 환경이에요';
        _climateMessageColor = const Color(0xFFFF9800); // 주황
      } else {
        _climateMessage = '오늘은 등산하기 좋은 날씨네요';
        _climateMessageColor = const Color(0xFF52A486); // 초록
      }
    }
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: appState.isLoggedIn
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 등산 관련 메시지
                Row(
                  children: [
                    const Icon(
                      Icons.hiking_rounded,
                      size: 18,
                      color: Color(0xFF64B792),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '어떤 산행을 계획하고 계신가요?',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF666666),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
                
                // 등산지수 메시지
                if (_climbingIndex > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _climateMessageColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _climbingIndex < 50
                              ? Icons.wb_cloudy_rounded
                              : _climbingIndex < 80
                                  ? Icons.cloud_queue_rounded
                                  : Icons.wb_sunny_rounded,
                          size: 20,
                          color: _climateMessageColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _climateMessage,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _climateMessageColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 비로그인 상태 메시지
                Row(
                  children: [
                    const Icon(
                      Icons.hiking_rounded,
                      size: 18,
                      color: Color(0xFF64B792),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '어떤 산행을 계획하고 계신가요?',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF666666),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
  
  Widget _buildSectionHeader({
    required String title, 
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoginPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF64B792).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.login_rounded,
              color: Color(0xFF64B792),
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '로그인을 하고\n맞춤형 산 추천을 받아보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.5,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64B792),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '로그인',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationCard({
    required String title,
    required String description,
    required String image,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Ink(
            height: 160,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // 배경 패턴
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      Icons.terrain,
                      size: 150,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // 내용
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                'AI 추천',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: Text(
                                description,
                                style: TextStyle(
                                  fontSize: 12, // 글자 크기를 14에서 12로 줄임
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.3, // 줄 간격도 약간 줄임
                                ),
                                maxLines: 1, // 한 줄로만 표시
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: backgroundColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
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
  }

  Widget _buildSmallRecommendationCard({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // 배경 패턴
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      icon,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // 내용
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            '자세히 보기',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 12,
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
  }
}