// mode_select_screen.dart: 모드 선택 화면
// - 다양한 트래킹 모드 제공 (나 vs 나, 나 vs 친구, 나 vs AI추천, 일반 등산)
// - 모드 선택 후 실시간 트래킹 시작

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

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
                        () => appState.startTracking('나 vs 나'),
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
