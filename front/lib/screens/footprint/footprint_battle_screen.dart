import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/app_state.dart';
import 'package:provider/provider.dart';
import '../../models/battle_result.dart';
import 'dart:convert';

class FootprintBattleScreen extends StatefulWidget {
  final String token;

  const FootprintBattleScreen({super.key, required this.token});

  @override
  State<FootprintBattleScreen> createState() => _FootprintBattleScreenState();
}

class _FootprintBattleScreenState extends State<FootprintBattleScreen> {
  final ScrollController _scrollController = ScrollController();
  List<BattleResult> _battleResults = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _lastPage = false;

  @override
  void initState() {
    super.initState();
    _fetchBattleResults();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.9 &&
          !_isLoading &&
          !_lastPage) {
        _fetchBattleResults(page: _currentPage + 1);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchBattleResults({int page = 0}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    final baseUrl = dotenv.get('BASE_URL');
    final uri = Uri.parse('$baseUrl/footprint/battle?page=$page');

    try {
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('대결 결과 API 응답 코드: ${res.statusCode}');
      debugPrint('대결 결과 API 응답 본문: ${res.body}');
      final decoded = utf8.decode(res.bodyBytes);

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(decoded);
        final data = jsonData['data'];
        final List<dynamic> list = data['list'];
        final bool isLast = data['last'];

        setState(() {
          if (page == 0) {
            _battleResults = list.map((e) => BattleResult.fromJson(e)).toList();
          } else {
            _battleResults.addAll(list.map((e) => BattleResult.fromJson(e)));
          }
          _currentPage = page;
          _lastPage = isLast;
        });
      }
    } catch (e) {
      debugPrint('대결 결과 API 호출 에러: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getResultText(String result) {
    switch (result) {
      case 'W':
        return '승리';
      case 'L':
        return '패배';
      case 'S':
        return '무승부';
      default:
        return '';
    }
  }

  Color _getResultColor(String result, bool isMe) {
    if (result == 'S') return const Color(0xFF52A486); // 무승부는 주 테마색
    if ((result == 'W' && isMe) || (result == 'L' && !isMe)) {
      return const Color(0xFF52A486); // 승리는 녹색
    }
    return Colors.grey.shade600; // 패배는 회색
  }

  @override
  Widget build(BuildContext context) {
    final myProfile = context.watch<AppState>().profileImageUrl;
    final nickname = context.watch<AppState>().nickname;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '대결 결과',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
      ),
      body: _battleResults.isEmpty && !_isLoading
          ? _buildEmptyState()
          : Column(
              children: [
                // 상단 요약 카드
                if (_battleResults.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatisticItem(
                              icon: Icons.emoji_events,
                              label: '승리',
                              value: _battleResults.where((r) => r.result == 'W').length.toString(),
                              color: const Color(0xFF52A486),
                            ),
                            _buildDivider(),
                            _buildStatisticItem(
                              icon: Icons.handshake,
                              label: '무승부',
                              value: _battleResults.where((r) => r.result == 'S').length.toString(),
                              color: const Color(0xFF6E85B7),
                            ),
                            _buildDivider(),
                            _buildStatisticItem(
                              icon: Icons.trending_down,
                              label: '패배',
                              value: _battleResults.where((r) => r.result == 'L').length.toString(),
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 대결 목록 타이틀
                if (_battleResults.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '대결 기록',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${_battleResults.length}개',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 대결 결과 목록
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF52A486),
                    onRefresh: () async {
                      setState(() {
                        _battleResults = [];
                        _currentPage = 0;
                        _lastPage = false;
                      });
                      await _fetchBattleResults();
                    },
                    child: _battleResults.isEmpty && !_isLoading
                        ? _buildEmptyList()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: _battleResults.length + (!_lastPage && _isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _battleResults.length && !_lastPage && _isLoading) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF52A486),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                );
                              }
                              final result = _battleResults[index];
                              return _buildBattleCard(result, myProfile, nickname);
                            },
                          ),
                  ),
                ),
                
                // 하단 메시지
                if (_battleResults.isNotEmpty && _lastPage)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    // child: Text(
                    //   '모든 대결 결과를 불러왔습니다',
                    //   style: TextStyle(
                    //     color: Colors.grey[600],
                    //     fontSize: 14,
                    //   ),
                    // ),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 대결 결과가 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 사람들과 등산 대결을 해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyList() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '대결 결과를 찾을 수 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [],
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildBattleCard(BattleResult result, String? myProfile, String? nickname) {
    final resultText = _getResultText(result.result);
    final myResultColor = _getResultColor(result.result, true);
    final opponentResultColor = _getResultColor(result.result, false);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 산 이름과 날짜
            Column(
              children: [
                Text(
                  result.mountainName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  result.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            
            // 대결 결과 표시
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: result.result == 'S' 
                    ? const Color(0xFF6E85B7).withOpacity(0.1) 
                    : result.result == 'W' 
                        ? const Color(0xFF52A486).withOpacity(0.1)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                resultText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: result.result == 'S' 
                      ? const Color(0xFF6E85B7) 
                      : result.result == 'W' 
                          ? const Color(0xFF52A486)
                          : Colors.grey[600],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 유저 대결 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 나의 프로필
                Column(
                  children: [
                    _circleAvatar(myProfile, result.result, isMe: true, resultColor: myResultColor),
                    const SizedBox(height: 8),
                    Text(
                      nickname ?? '나',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                
                // VS 표시
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[100],
                  ),
                  child: Center(
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                
                // 상대방 프로필
                Column(
                  children: [
                    _circleAvatar(result.opponentProfile, result.result, isMe: false, resultColor: opponentResultColor),
                    const SizedBox(height: 8),
                    Text(
                      result.opponentNickname,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleAvatar(String? url, String result, {required bool isMe, required Color resultColor}) {
    const double avatarRadius = 30;
    const double crownSize = 24;

    // 왕관 표시 조건
    bool showCrown = false;
    if (result == 'S') {
      // 무승부: 양쪽 모두 왕관 표시
      showCrown = true;
    } else if (result == 'W' && isMe) {
      // 내가 승리: 나에게 왕관 표시
      showCrown = true;
    } else if (result == 'L' && !isMe) {
      // 내가 패배: 상대방에게 왕관 표시
      showCrown = true;
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // 프로필 배경 원형 효과
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.white,
            backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
            child: url == null || url.isEmpty 
                ? Icon(Icons.person, size: 28, color: Colors.grey[400]) 
                : null,
          ),
        ),
        
        // 왕관 아이콘
        if (showCrown)
          Positioned(
            top: -crownSize * 0.75,
            child: Image.asset(
              'lib/assets/images/crown.png',
              width: crownSize,
              height: crownSize,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.emoji_events,
                  size: crownSize,
                  color: const Color(0xFFFFD700), // 금색
                );
              },
            ),
          ),
      ],
    );
  }
}