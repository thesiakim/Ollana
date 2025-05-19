// mode_select_screen.dart: 모드 선택 화면
// - 다양한 트래킹 모드 제공 (나 vs 나, 나 vs 친구, 나 vs AI추천, 일반 등산)
// - 모드 선택 후 실시간 트래킹 시작

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../services/mode_service.dart';
import 'friend_search_screen.dart';

class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  // 선택된 기록 ID
  int? _selectedRecordId;

  @override
  void dispose() {
    super.dispose();
  }

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
                  return ListView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 나 vs 나 모드
                      _buildModeCardVertical(
                        context: context,
                        title: '나 vs 나',
                        description: '과거의 나와 경쟁하며 등산해보세요! 이전 기록을 갱신할 수 있습니다.',
                        icon: Icons.history,
                        color: Colors.blue,
                        onTap: () =>
                            _showTrackingOptionsModal(context, appState),
                      ),

                      const SizedBox(height: 16),

                      // 나 vs 친구 모드
                      _buildModeCardVertical(
                        context: context,
                        title: '나 vs 친구',
                        description: '친구와 경쟁하며 등산해보세요! 친구의 기록과 실시간으로 비교됩니다.',
                        icon: Icons.people,
                        color: Colors.green,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FriendSearchScreen(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 일반 등산 모드
                      _buildModeCardVertical(
                        context: context,
                        title: '일반 등산',
                        description: '경쟁 없이 편안하게 등산해보세요! 기본적인 등산 정보만 제공됩니다.',
                        icon: Icons.directions_walk,
                        color: Colors.orange,
                        onTap: () async {
                          try {
                            await appState.startTracking(
                              '일반 등산',
                              recordId: null,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('등산 시작 중 오류가 발생했습니다: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
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

  // 이전 등산 기록 목록 모달 표시
  Future<void> _showTrackingOptionsModal(
      BuildContext context, AppState appState) async {
    final modeService = ModeService();
    _selectedRecordId = null;

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

      // 이전 등산 기록 목록 가져오기
      final mountainId = appState.selectedRoute?.mountainId ?? 0;
      final pathId = appState.selectedRoute?.id ?? 0;
      final token = appState.accessToken ?? '';

      final recordsList = await modeService.getMyTrackingOptions(
        mountainId: mountainId.toInt(),
        pathId: pathId.toInt(),
        token: token,
      );

      // 로딩 다이얼로그 닫기
      if (!mounted) return;
      if (context.mounted) Navigator.of(context).pop();

      if (recordsList.isEmpty) {
        // 이전 기록이 없는 경우
        if (!mounted) return;
        if (context.mounted) {
          _showNoRecordsDialog(context);
        }
        return;
      }

      // 이전 기록이 있는 경우 목록 표시
      if (!mounted) return;
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '이전 등산 기록',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: recordsList.length,
                            itemBuilder: (context, index) {
                              final record = recordsList[index];
                              final recordId = record['recordId'];
                              final date = record['date'];
                              final time = record['time'];
                              debugPrint('date: $date, time: $time');

                              final isSelected = _selectedRecordId == recordId;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedRecordId = recordId;
                                  });

                                  // 선택한 기록 정보 디버그 출력
                                  debugPrint('===== 선택한 과거 기록 정보 =====');
                                  debugPrint('기록 ID: $recordId');
                                  debugPrint('날짜: $date');
                                  debugPrint('시간(분): $time');
                                  debugPrint('시간(포맷): ${_formatMinutes(time)}');
                                  debugPrint('=============================');

                                  // 선택한 기록의 정보를 AppState에 저장
                                  appState.setPreviousRecordData(
                                    date: date,
                                    time: time,
                                  );
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 5),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      // 선택 여부 표시
                                      isSelected
                                          ? Icon(Icons.check_circle,
                                              color: Colors.blue)
                                          : Icon(Icons.circle_outlined,
                                              color: Colors.grey),
                                      SizedBox(width: 10),

                                      // 날짜와 시간 정보
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            date,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '등반 시간: ${_formatMinutes(time)}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 취소 버튼
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                '취소',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),

                            // 시작하기 버튼
                            ElevatedButton(
                              onPressed: _selectedRecordId != null
                                  ? () {
                                      Navigator.of(context).pop();

                                      // 선택된 최종 기록 정보 출력
                                      final recordId = _selectedRecordId;
                                      final selectedRecord =
                                          recordsList.firstWhere(
                                        (record) =>
                                            record['recordId'] == recordId,
                                        orElse: () => {
                                          'recordId': 0,
                                          'date': '알 수 없음',
                                          'time': 0
                                        },
                                      );

                                      debugPrint(
                                          '===== 시작하는 과거 기록 최종 정보 =====');
                                      debugPrint(
                                          '기록 ID: ${selectedRecord['recordId']}');
                                      debugPrint(
                                          '날짜: ${selectedRecord['date']}');
                                      debugPrint(
                                          '시간(분): ${selectedRecord['time']}');
                                      debugPrint(
                                          '시간(포맷): ${_formatMinutes(selectedRecord['time'])}');
                                      debugPrint('시작하는 모드: 나 vs 나');
                                      debugPrint(
                                          '====================================');

                                      appState.startTracking(
                                        '나 vs 나',
                                        recordId: _selectedRecordId,
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                disabledBackgroundColor: Colors.grey.shade400,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                              ),
                              child: Text(
                                '시작하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    } catch (e) {
      // 오류 처리
      debugPrint('등산 기록 목록 조회 오류: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showNoRecordsDialog(context);
      }
    }
  }

  // 기록이 없는 경우 표시할 다이얼로그
  void _showNoRecordsDialog(BuildContext context) {
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
                // 상단 제목
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: const Text(
                    '등산 기록 없음',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 정보 컨테이너
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade300, width: 1),
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.red.shade50,
                  ),
                  child: const Center(
                    child: Text(
                      '등산 기록이 없습니다.\n일반 모드를 선택해 주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                // 확인 버튼
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      '확인',
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

  // 분 형식 변환 (예: 72분 -> 1h 12m)
  String _formatMinutes(num minutes) {
    final int hrs = (minutes / 60).floor();
    final int mins = (minutes % 60).toInt();

    if (hrs > 0) {
      return '$hrs시간 $mins분';
    } else {
      return '$mins분';
    }
  }

  Widget _buildModeCardVertical({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 왼쪽: 아이콘
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  color: color.withAlpha(10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30.0,
                ),
              ),

              // 중앙: 제목과 설명
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 제목
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),

                    // 설명
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 오른쪽: 화살표 아이콘
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
