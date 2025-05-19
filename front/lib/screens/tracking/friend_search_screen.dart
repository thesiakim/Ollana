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
            // 검색창
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
                    hintText: '닉네임으로 검색해보세요',
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

            // 로딩 표시 또는 검색 결과
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
                                    // isPossible이 false인 경우 경고창 표시
                                    if (!isPossible) {
                                      _showNotPossibleDialog(context, friend.nickname);
                                      return;
                                    }

                                    // 친구 선택
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
                                        // 상단 부분 - 친구 정보
                                        Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // 프로필 아바타
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF52A486).withOpacity(0.1),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? Color(0xFF52A486)
                                                        : Colors.grey.shade200,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Center(
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
                                              SizedBox(width: 16),
                                              
                                              // 친구 정보
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          friend.nickname,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Color(0xFF333333),
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        if (!isPossible)
                                                          Container(
                                                            padding: EdgeInsets.symmetric(
                                                              horizontal: 8, 
                                                              vertical: 2
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Color(0xFFFFEFEF),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text(
                                                              '기록 없음',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w500,
                                                                color: Color(0xFFFF5151),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      _searchController.text,
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // 선택 표시 (오른쪽)
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isSelected
                                                      ? Color(0xFF52A486)
                                                      : Colors.transparent,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? Color(0xFF52A486)
                                                        : Colors.grey.shade300,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: isSelected
                                                    ? Icon(
                                                        Icons.check,
                                                        size: 16,
                                                        color: Colors.white,
                                                      )
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // 하단 부분 - 등산 가능 여부 표시 (조건부 표시)
                                        if (isPossible)
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF52A486).withOpacity(0.05),
                                              borderRadius: BorderRadius.vertical(
                                                bottom: Radius.circular(14),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_outline,
                                                  size: 14,
                                                  color: Color(0xFF52A486),
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  "함께 등산 가능",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF52A486),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFFEFEF),
                                              borderRadius: BorderRadius.vertical(
                                                bottom: Radius.circular(14),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  size: 14,
                                                  color: Color(0xFFFF5151),
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  "이 등산로에 기록이 없어요",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500, 
                                                    color: Color(0xFFFF5151),
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

            // 시작하기 버튼 (검색 결과가 있을 때만 표시)
            if (_searchResults.isNotEmpty)
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _selectedFriend != null && _selectedFriend!.isPossible
                        ? () async {
                            Navigator.of(context).pop();
                            await appState.startTracking(
                              '나 vs 친구',
                              opponentId: _selectedFriend!.id.toInt(),
                            );
                          }
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
                          '친구와 함께 등산하기',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
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

  // 친구 검색 API 호출
  Future<void> _searchFriends(String query, AppState appState) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _selectedFriend = null; // 새 검색 시 선택 초기화
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 등산 기록이 없는 친구 선택 시 표시할 다이얼로그
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
                // 상단 아이콘
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
                
                // 제목
                Text(
                  '등산 기록 없음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 12),
                
                // 내용
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
                
                // 확인 버튼
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