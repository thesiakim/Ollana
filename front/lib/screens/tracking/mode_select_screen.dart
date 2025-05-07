// mode_select_screen.dart: 모드 선택 화면
// - 다양한 트래킹 모드 제공 (나 vs 나, 나 vs 친구, 나 vs AI추천, 일반 등산)
// - 모드 선택 후 실시간 트래킹 시작

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../services/mode_service.dart';

class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: AppBar(
            title: Text(
              '${appState.selectedMountain ?? '선택된 산 없음'} - ${appState.selectedRoute ?? '선택된 등산로 없음'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // 등산로 선택 화면으로 돌아가기 (산 정보 유지)
                appState.backToRouteSelect();
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            titleSpacing: 0,
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 산 및 등산로 정보는 이미 AppBar에 표시했으므로 제거
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: const Text(
                '어떤 모드로 등산하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 모드 선택 그리드
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 화면 크기에 따라 그리드 조정
                  final cardWidth = (constraints.maxWidth - 16) / 2;
                  final cardHeight = (constraints.maxHeight - 16) / 2;

                  return GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: cardWidth / cardHeight,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 나 vs 나 모드
                      _buildModeCard(
                        context,
                        '나 vs 나',
                        '과거의 나와 경쟁하며 등산해보세요! 이전 기록을 갱신할 수 있습니다.',
                        Icons.history,
                        Colors.blue,
                        () => _showMeVsMeModal(context, appState),
                      ),

                      // 나 vs 친구 모드
                      _buildModeCard(
                        context,
                        '나 vs 친구',
                        '친구와 경쟁하며 등산해보세요! 친구의 기록과 실시간으로 비교됩니다.',
                        Icons.people,
                        Colors.green,
                        () => appState.startTracking('나 vs 친구'),
                      ),

                      // 나 vs AI추천 모드
                      _buildModeCard(
                        context,
                        '나 vs AI추천',
                        'AI가 추천하는 페이스로 등산해보세요! 최적의 페이스로 등산할 수 있습니다.',
                        Icons.smart_toy,
                        Colors.purple,
                        () => appState.startTracking('나 vs AI추천'),
                      ),

                      // 일반 등산 모드
                      _buildModeCard(
                        context,
                        '일반 등산',
                        '경쟁 없이 편안하게 등산해보세요! 기본적인 등산 정보만 제공됩니다.',
                        Icons.directions_walk,
                        Colors.orange,
                        () => appState.startTracking('일반 등산'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 나 vs 나 모달 표시
  Future<void> _showMeVsMeModal(BuildContext context, AppState appState) async {
    final modeService = ModeService();

    try {
      // 로딩 표시
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      }

      // 이전 등산 기록 가져오기
      final mountainId = appState.selectedRoute?.mountainId ?? 0;
      final pathId = appState.selectedRoute?.id ?? 0;

      final previousRecord =
          await modeService.getMeVsMeRecord(mountainId, pathId);

      // 로딩 다이얼로그 닫기
      if (!mounted) return;
      if (context.mounted) Navigator.of(context).pop();

      if (previousRecord == null) {
        // 이전 기록이 없는 경우
        if (!mounted) return;
        if (context.mounted) {
          // 기록이 없는 경우와 동일한 UI 표시
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 상단 날짜 비교 부분
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 이전 날짜
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Text(
                                '이전 기록',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 정보 컨테이너
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Center(
                          child: Text(
                            '기록이 없습니다',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      // 시작하기 버튼
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            appState.startTracking('나 vs 나');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            '시작하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return;
      }

      // 이전 기록이 있는 경우 모달 표시
      if (!mounted) return;
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상단 날짜 비교 부분
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 이전 날짜
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              previousRecord.date,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 정보 컨테이너
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이전 등산 기록',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 등산 시간
                          Text(
                            '등반 시간 ${_formatMinutes(previousRecord.time)}',
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 심박수 정보
                          Text(
                            '평균 심박수 ${previousRecord.averageHeartRate.toStringAsFixed(0)}bpm',
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '최고 심박수 ${previousRecord.maxHeartRate}bpm',
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 시작하기 버튼
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          appState.startTracking('나 vs 나');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '시작하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      // 오류 처리
      debugPrint('MeVsMe 모달 표시 오류: $e');
      if (context.mounted) {
        // 기록이 없는 경우와 동일한 UI 표시
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상단 날짜 비교 부분
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 이전 날짜
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              '이전 기록',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 정보 컨테이너
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          '기록이 없습니다',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // 시작하기 버튼
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          appState.startTracking('나 vs 나');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '시작하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    }
  }

  // 분 형식 변환 (예: 72분 -> 1h 12m)
  String _formatMinutes(num minutes) {
    final int hrs = (minutes / 60).floor();
    final int mins = (minutes % 60).toInt();

    if (hrs > 0) {
      return '${hrs}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }

  Widget _buildModeCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    // 화면 크기 가져오기
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                decoration: BoxDecoration(
                  color: color.withAlpha(10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmallScreen ? 28.0 : 40.0,
                ),
              ),
              SizedBox(height: isSmallScreen ? 8.0 : 16.0),

              // 제목
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14.0 : 18.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 4.0 : 8.0),

              // 설명
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: isSmallScreen ? 10.0 : 12.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 화살표 아이콘
              SizedBox(height: isSmallScreen ? 4.0 : 8.0),
              Icon(
                Icons.arrow_forward,
                color: color,
                size: isSmallScreen ? 14.0 : 16.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
