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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '친구 검색',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF52A486)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF52A486).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF52A486).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xFF52A486).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people,
                      color: Color(0xFF52A486),
                      size: 14,
                    ),
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.selectedMountain ?? '선택된 산 없음',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1),
                        Text(
                          appState.selectedRoute?.name ?? '선택된 등산로 없음',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '닉네임을 검색해보세요',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFF52A486),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Color(0xFF52A486).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF52A486),
                          size: 16,
                        ),
                      ),
                      onPressed: () => _searchFriends(_searchController.text, appState),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                  onSubmitted: (value) => _searchFriends(value, appState),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: _isSearching
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52A486)),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF52A486).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_off,
                                    size: 40,
                                    color: Color(0xFF52A486),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '검색 결과가 없습니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '다른 닉네임으로 검색해보세요',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            physics: BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final friend = _searchResults[index];
                              final isSelected = _selectedFriend?.id == friend.id;
                              final isPossible = friend.isPossible;

                              return Container(
                                margin: EdgeInsets.only(bottom: 16),
                                child: InkWell(
                                  onTap: () {
                                    if (!isPossible) {
                                      _showNotPossibleDialog(context, friend.nickname);
                                      return;
                                    }
                                    setState(() {
                                      _selectedFriend = friend;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: EdgeInsets.all(0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? Color(0xFF52A486).withOpacity(0.15)
                                              : Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                          spreadRadius: isSelected ? 2 : 0,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: isSelected
                                            ? Color(0xFF52A486)
                                            : Colors.grey.shade200,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF52A486).withOpacity(0.1),
                                                  border: Border.all(
                                                    color: Colors.grey.shade200,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(24),
                                                  child: friend.profileImg != null && friend.profileImg!.isNotEmpty
                                                      ? Image.network(
                                                          friend.profileImg!,
                                                          width: 48,
                                                          height: 48,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Center(
                                                              child: Text(
                                                                friend.nickname.isNotEmpty
                                                                    ? friend.nickname[0].toUpperCase()
                                                                    : "?",
                                                                style: TextStyle(
                                                                  color: Color(0xFF52A486),
                                                                  fontSize: 20,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) {
                                                              return child;
                                                            }
                                                            return Center(
                                                              child: CircularProgressIndicator(
                                                                color: Color(0xFF52A486),
                                                                strokeWidth: 2,
                                                                value: loadingProgress.expectedTotalBytes != null
                                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                                        loadingProgress.expectedTotalBytes!
                                                                    : null,
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      : Center(
                                                          child: Text(
                                                            friend.nickname.isNotEmpty
                                                                ? friend.nickname[0].toUpperCase()
                                                                : "?",
                                                            style: TextStyle(
                                                              color: Color(0xFF52A486),
                                                              fontSize: 20,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      friend.nickname,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        color: Color(0xFF333333),
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    isPossible
                                                        ? Container(
                                                            padding: EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Color(0xFFEBF7F3),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text(
                                                              '등산 기록 있음',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w500,
                                                                color: Color(0xFF52A486),
                                                              ),
                                                            ),
                                                          )
                                                        : Container(
                                                            padding: EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Color(0xFFFFEFEF),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text(
                                                              '등산 기록 없음',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w500,
                                                                color: Color(0xFFFF5151),
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
                              );
                            },
                          ),
              ),
            ),
            if (_searchResults.isNotEmpty)
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _selectedFriend != null && _selectedFriend!.isPossible
                        ? () => _showFriendTrackingOptionsModal(context, appState)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF52A486),
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '선택 완료',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
          SnackBar(
            content: Text('친구 검색 중 오류가 발생했습니다'),
            backgroundColor: Color(0xFFFF5151),
          ),
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
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52A486)),
              ),
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
                            color: Color(0xFF333333),
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
                                        ? Color(0xFF52A486).withOpacity(0.1)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? Color(0xFF52A486)
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      isSelected
                                          ? Icon(Icons.check_circle,
                                              color: Color(0xFF52A486))
                                          : Icon(Icons.circle_outlined,
                                              color: Colors.grey),
                                      SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            date,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF333333),
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
                            ElevatedButton(
                              onPressed: _selectedRecordId != null
                                  ? () {
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
                                backgroundColor: Color(0xFF52A486),
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
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFFF5151).withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.circular(15),
                    color: Color(0xFFFFEFEF),
                  ),
                  child: const Center(
                    child: Text(
                      '해당 산/등산로에 대한\n친구의 등산 기록이 없습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF333333),
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
                      backgroundColor: Color(0xFF52A486),
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
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF3F3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF5151),
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '등산 기록 없음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '$nickname님은 선택하신 곳의\n등산 기록이 없네요\n다른 친구를 검색해보세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF52A486),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
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
