import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/friend.dart';
import '../../services/mode_service.dart';
import '../../utils/app_colors.dart';

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Friend? _selectedFriend;
  List<Friend> _searchResults = [];
  bool _isSearching = false;
  int? _selectedRecordId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('나 vs 친구'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '닉네임으로 검색해보세요',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () =>
                      _searchFriends(_searchController.text, appState),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onSubmitted: (value) => _searchFriends(value, appState),
            ),
          ),

          // 로딩 표시 또는 검색 결과
          Expanded(
            child: _isSearching
                ? Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/no_result.png',
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                Icons.search_off,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '검색 결과가 없습니다...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        padding: EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final friend = _searchResults[index];
                          final isSelected = _selectedFriend?.id == friend.id;

                          return GestureDetector(
                            onTap: () {
                              // isPossible이 false인 경우 경고창 표시
                              if (!friend.isPossible) {
                                _showNotPossibleDialog(
                                    context, friend.nickname);
                                return;
                              }

                              // 친구 선택
                              setState(() {
                                _selectedFriend = friend;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '닉네임: ${friend.nickname}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // 시작하기 버튼 (검색 결과가 있을 때만 표시)
          if (_searchResults.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedFriend != null
                      ? () => _showFriendTrackingOptionsModal(context, appState)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    '시작하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 친구 검색 API 호출
  Future<void> _searchFriends(String query, AppState appState) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final modeService = ModeService();
      final token = appState.accessToken ?? '';
      final mountainId = appState.selectedRoute?.mountainId ?? 0;
      final pathId = appState.selectedRoute?.id ?? 0;

      final results = await modeService.searchFriends(
        query,
        token,
        mountainId: mountainId,
        pathId: pathId,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('친구 검색 오류: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 검색 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 친구의 이전 등산 기록 목록 모달 표시
  Future<void> _showFriendTrackingOptionsModal(
      BuildContext context, AppState appState) async {
    if (_selectedFriend == null) return;

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

      // 친구의 이전 등산 기록 목록 가져오기
      final mountainId = appState.selectedRoute?.mountainId ?? 0;
      final pathId = appState.selectedRoute?.id ?? 0;
      final token = appState.accessToken ?? '';
      final opponentId = _selectedFriend!.id.toInt();

      final recordsList = await modeService.getFriendTrackingOptions(
        mountainId: mountainId.toInt(),
        pathId: pathId.toInt(),
        opponentId: opponentId,
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
                          '${_selectedFriend!.nickname}님의 등산 기록',
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

                              final isSelected = _selectedRecordId == recordId;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedRecordId = recordId;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 5),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.green
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
                                              color: Colors.green)
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
                                      // 선택된 기록의 데이터를 AppState에 저장
                                      final selectedRecord =
                                          recordsList.firstWhere(
                                        (record) =>
                                            record['recordId'] ==
                                            _selectedRecordId,
                                      );

                                      appState.setOpponentRecordData(
                                        date: selectedRecord['date'],
                                        time: selectedRecord['time'],
                                        maxHeartRate:
                                            selectedRecord['maxHeartRate'],
                                        avgHeartRate:
                                            selectedRecord['averageHeartRate'],
                                      );

                                      Navigator.of(context).pop();
                                      Navigator.of(context)
                                          .pop(); // 친구 검색 화면도 닫기
                                      appState.startTracking(
                                        '나 vs 친구',
                                        opponentId: _selectedFriend!.id.toInt(),
                                        recordId: _selectedRecordId,
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
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
      debugPrint('친구 등산 기록 목록 조회 오류: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showNoRecordsDialog(context);
      }
    }
  }

  // 분 형식 변환 (예: 72분 -> 1시간 12분)
  String _formatMinutes(num minutes) {
    final int hrs = (minutes / 60).floor();
    final int mins = (minutes % 60).toInt();

    if (hrs > 0) {
      return '${hrs}시간 ${mins}분';
    } else {
      return '${mins}분';
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
                      '해당 산/등산로에 대한\n친구의 등산 기록이 없습니다.',
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
                      backgroundColor: Colors.green,
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

  // isPossible이 false인 경우 표시할 경고창
  void _showNotPossibleDialog(BuildContext context, String nickname) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('알림'),
        content: Text('$nickname님은 현재 산과 등산로에 기록이 없어 함께 등산할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }
}
