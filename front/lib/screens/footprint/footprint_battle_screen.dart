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
  bool _lastPage = false; // last 필드를 추적

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
        final bool isLast = data['last']; // last 필드 추출

        setState(() {
          if (page == 0) {
            _battleResults = list.map((e) => BattleResult.fromJson(e)).toList();
          } else {
            _battleResults.addAll(list.map((e) => BattleResult.fromJson(e)));
          }
          _currentPage = page;
          _lastPage = isLast; // last 필드 업데이트
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

  @override
  Widget build(BuildContext context) {
    final myProfile = context.watch<AppState>().profileImageUrl;
    final nickname = context.watch<AppState>().nickname;

    return Scaffold(
      appBar: AppBar(title: const Text('대결 결과')),
      body: _battleResults.isEmpty && !_isLoading
          ? const Center(child: Text('대결 결과가 없습니다.'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: _battleResults.length + (!_lastPage && _isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _battleResults.length && !_lastPage && _isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final result = _battleResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                _circleAvatar(myProfile),
                                const SizedBox(height: 4),
                                Text(
                                  nickname ?? '나',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  result.mountainName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                _resultBadge(result.result),
                                const SizedBox(height: 6),
                                Text(
                                  result.date,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                _circleAvatar(result.opponentProfile),
                                const SizedBox(height: 4),
                                Text(
                                  result.opponentNickname,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _circleAvatar(String? url) {
  return CircleAvatar(
    radius: 28,
    backgroundImage: url != null && url.isNotEmpty
        ? NetworkImage(url)
        : null,
    child: url == null || url.isEmpty ? const Icon(Icons.person, size: 28) : null,
  );
}

  Widget _resultBadge(String code) {
    String text;
    Color color;

    switch (code) {
      case 'W':
        text = '승리';
        color = Colors.green;
        break;
      case 'S':
        text = '무승부';
        color = Colors.orange;
        break;
      case 'L':
        text = '패배';
        color = Colors.red;
        break;
      default:
        text = '알 수 없음';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }


  Color _resultColor(String code) {
    switch (code) {
      case 'W':
        return Colors.green;
      case 'S':
        return Colors.orange;
      case 'L':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }


}
