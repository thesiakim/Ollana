// lib/widgets/home_body.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../widgets/status_container.dart';
import '../screens/recommend/ai_recommendation_screen.dart';
import '../screens/recommend/theme_recommendation_screen.dart';
import '../screens/recommend/location_recommendation_screen.dart';
import '../screens/user/survey_screen.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final PageController _pageController = PageController();
  int _currentStatusPage = 0;
  bool _isLoading = false; // 로딩 상태 추가

  @override
  void initState() {
    super.initState();
    // 안전하게 비동기 작업 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  // 데이터 초기화 메서드 분리
  Future<void> _initializeData() async {
    // UI가 멈추지 않도록 지연 추가
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    // 비동기 작업 시작
    setState(() {
      _isLoading = true;
    });

    try {
      // 설문 상태 가져오기 (Future.microtask로 감싸서 UI 스레드 차단 방지)
      await Future.microtask(
          () => context.read<AppState>().fetchSurveyStatus());
    } catch (e) {
      // 오류 처리
      debugPrint('설문 상태 가져오기 실패: $e');
      // 사용자에게 오류 표시 (UI 차단 방지를 위해 microtask 사용)
      if (mounted) {
        Future.microtask(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다. 다시 시도해주세요.')),
          );
        });
      }
    } finally {
      // 작업 완료, 로딩 상태 해제 (지연을 통해 UI 스레드 차단 방지)
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // AI 추천 화면으로 이동하는 메서드
  Future<void> _navigateToAiRecommendation() async {
    // UI 스레드 차단 방지를 위한 지연
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    final appState = context.read<AppState>();

    // 설문 완료 여부 다시 확인 (최신 상태)
    if (!appState.surveyCompleted) {
      _showSurveyDialog();
    } else {
      // 로딩 표시 (별도 위젯으로 표시하여 UI 차단 방지)
      final loadingOverlay = _showLoadingOverlay(context);

      try {
        // compute를 사용하여 무거운 데이터 로딩 작업을 별도 isolate에서 수행
        // await compute(_preloadData, null); // 필요한 경우 compute 사용

        // 필요한 데이터 미리 로드 (비동기적으로)
        await Future.microtask(() async {
          // await appState.preloadRecommendationData(); // 필요하다면 AppState에 이 메서드 추가

          // 화면 전환 전 약간의 지연 (UI 렌더링 문제 방지)
          await Future.delayed(const Duration(milliseconds: 100));
        });

        // 로딩 오버레이 제거
        loadingOverlay.remove();

        if (mounted) {
          // 화면 전환 (화면 전환 지연 방지)
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const AiRecommendationScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
      } catch (e) {
        // 로딩 오버레이 제거
        loadingOverlay.remove();

        // 오류 처리 (UI 차단 방지를 위해 microtask 사용)
        if (mounted) {
          Future.microtask(() {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('추천 데이터를 불러오는 중 오류가 발생했습니다. 다시 시도해주세요.')),
            );
          });
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
        child: const Center(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: Color(0xFF52A486),
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
    // UI 스레드 차단 방지를 위해 microtask 사용
    Future.microtask(() {
      showDialog(
        context: context,
        barrierDismissible: true, // 바깥 클릭으로 닫히도록 설정
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.edit, color: Color(0xFF52A486)),
              SizedBox(width: 8),
              Text(
                '설문 작성 안내',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          content: const Text(
            '설문을 작성하고 AI 추천을 받아보세요 !',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52A486),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _navigateToSurvey();
              },
              child: const Text('설문하기'),
            ),
          ],
        ),
      );
    });
  }

  // 설문 화면으로 이동
  Future<void> _navigateToSurvey() async {
    // UI 스레드 차단 방지를 위한 지연
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SurveyScreen()),
      );

      // 설문이 완료되었으면 상태 갱신
      if (result == true && mounted) {
        // 로딩 표시 (별도 위젯으로 표시하여 UI 차단 방지)
        final loadingOverlay = _showLoadingOverlay(context);

        try {
          // 약간의 지연을 두어 UI 업데이트 안정화
          await Future.delayed(const Duration(milliseconds: 200));

          // 설문 상태 다시 가져오기 (별도 isolate에서 실행하는 것이 좋음)
          await Future.microtask(() async {
            await context.read<AppState>().fetchSurveyStatus();
          });

          loadingOverlay.remove();

          // 상태 확인 후 화면 전환
          await Future.delayed(const Duration(milliseconds: 100));

          if (mounted && context.read<AppState>().surveyCompleted) {
            // 설문 완료 상태라면 바로 AI 추천 화면으로 이동
            _navigateToAiRecommendation();
          }
        } catch (e) {
          loadingOverlay.remove();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('설문 상태 업데이트 중 오류가 발생했습니다. 다시 시도해주세요.')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('설문 화면 이동 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설문 화면을 불러오는 중 오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final softGreenGradient = const LinearGradient(
      colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (appState.isLoggedIn) ...[
            StatusContainer(
              pageController: _pageController,
              currentStatusPage: _currentStatusPage,
              onPageChanged: (i) => setState(() => _currentStatusPage = i),
            ),
            const SizedBox(height: 24),
            CategoryFrame(
              label: '내 맞춤 AI 산 추천',
              imagePath: 'lib/assets/images/ai_recommend.png',
              gradient: softGreenGradient,
              borderColor: Colors.grey.withOpacity(0.3),
              onTap: _navigateToAiRecommendation,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 10.0, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withAlpha(30),
                  width: 1.5,
                ),
              ),
              child: const Text(
                '로그인을 하고 등산할 산과 코스를\n 추천 받으세요!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // 테마별 등산 추천
          CategoryFrame(
            label: '테마별 등산 추천',
            imagePath: 'lib/assets/images/theme_recommend.png',
            gradient: softGreenGradient,
            borderColor: Colors.grey.withOpacity(0.3),
            onTap: () {
              // 화면 이동 시 UI 차단 방지
              Future.microtask(() {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const ThemeRecommendationScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              });
            },
          ),

          // 현재 위치 등산 추천
          CategoryFrame(
            label: '현재 위치 등산 추천',
            imagePath: 'lib/assets/images/location_recommend.png',
            gradient: softGreenGradient,
            borderColor: Colors.grey.withOpacity(0.3),
            onTap: () {
              // 화면 이동 시 UI 차단 방지
              Future.microtask(() {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LocationRecommendationScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              });
            },
          ),

          // 로딩 표시기 (오버레이 대신 인라인 표시)
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF52A486),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryFrame extends StatelessWidget {
  final String label;
  final String imagePath;
  final LinearGradient gradient;
  final Color borderColor;
  final VoidCallback onTap;

  const CategoryFrame({
    required this.label,
    required this.imagePath,
    required this.gradient,
    required this.borderColor,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            ClipOval(
              child: Image.asset(
                imagePath,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
