import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/my_footprint_service.dart';
import '../../models/app_state.dart';
import 'footprint_battle_screen.dart';
import '../../models/footprint_mountain.dart';
import 'footprint_detail_screen.dart';

class MyFootprintScreen extends StatefulWidget {
  const MyFootprintScreen({super.key});

  @override
  State<MyFootprintScreen> createState() => _MyFootprintScreenState();
}

class _MyFootprintScreenState extends State<MyFootprintScreen> {
  List<footprintMountain> footprints = [];
  bool isLoading = true;

  int _currentPage = 0;
  bool _isFetching = false;
  bool _hasNextPage = true;
  double totalDistance = 0;
  
  @override
  void initState() {
    super.initState();

    // 첫 데이터 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AppState>(context, listen: false).accessToken ?? '';
      _fetchFootprints(token);
    });
  }

  Future<void> _fetchFootprints(String token) async {
    if (_isFetching || !_hasNextPage) {
      debugPrint('[발자취] 현재 데이터 요청 중이거나 더 이상 페이지가 없음');
      return;
    }

    debugPrint('[발자취] 데이터 요청 시작: 페이지 $_currentPage');
    setState(() => _isFetching = true);

    try {
      final service = MyFootprintService();
      final newResponse = await service.getFootprints(token, page: _currentPage);

      debugPrint('[발자취] currentPage: ${newResponse.currentPage}, last: ${newResponse.last}, mountains 개수: ${newResponse.mountains.length}');

      if (mounted) {
        setState(() {
          if (_currentPage == 0) {
            footprints = newResponse.mountains;
          } else {
            footprints.addAll(newResponse.mountains);
          }

          _hasNextPage = !newResponse.last;
          _currentPage++;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[발자취] 목록 로딩 중 에러 발생: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  void _loadMoreData() {
    debugPrint('[발자취] 추가 데이터 로드 요청');
    final token = Provider.of<AppState>(context, listen: false).accessToken ?? '';
    _fetchFootprints(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // 전체 Column을 중앙 정렬
                children: [
                  // 텍스트를 맨 위에 중앙 정렬
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      footprints.isEmpty
                          ? '아직 등산하신 적이 없어요'
                          : '총 ${totalDistance.toStringAsFixed(0)}m만큼 등산하셨어요!',
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // 대결 결과 버튼을 오른쪽 정렬
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        final token = Provider.of<AppState>(context, listen: false).accessToken ?? '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FootprintBattleScreen(token: token),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF714504),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        '대결 결과',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // 나머지 그리드 부분
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        // 스크롤이 하단에 도달하면 더 많은 데이터 로드
                        if (!_isFetching &&
                            _hasNextPage &&
                            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
                          debugPrint('[발자취] 스크롤 끝에 가까워짐: 다음 페이지 요청 시도');
                          _loadMoreData();
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        slivers: [
                          SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = footprints[index];
                                return InkWell(
                                  onTap: () async {
                                    try {
                                      final token = Provider.of<AppState>(context, listen: false).accessToken ?? '';
                                      final service = MyFootprintService();
                                      debugPrint('[발자취] 상세 정보 요청: footprintId=${item.footprintId}');
                                      await service.getFootprintDetail(token, item.footprintId);

                                      if (!mounted) {
                                        debugPrint('[발자취] 위젯이 마운트되지 않음: 네비게이션 취소');
                                        return;
                                      }

                                      debugPrint('[발자취] FootprintDetailScreen으로 이동: footprintId=${item.footprintId}');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FootprintDetailScreen(
                                            footprintId: item.footprintId,
                                            token: token,
                                          ),
                                        ),
                                      );
                                    } catch (e, stackTrace) {
                                      debugPrint('[발자취] 상세 정보 로드 중 에러: $e');
                                      debugPrint('[발자취] 스택 트레이스: $stackTrace');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('상세 정보를 불러오는 데 실패했습니다: $e')),
                                        );
                                      }
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: item.imgUrl.isNotEmpty
                                              ? Image.network(
                                                  item.imgUrl,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    debugPrint('[발자취] 이미지 로드 에러: ${error.toString()}');
                                                    return const Icon(Icons.broken_image, size: 80);
                                                  },
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                            ? loadingProgress.cumulativeBytesLoaded /
                                                                loadingProgress.expectedTotalBytes!
                                                            : null,
                                                        strokeWidth: 2.0,
                                                        color: Theme.of(context).primaryColor,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : const Icon(Icons.image_not_supported, size: 80),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.mountainName,
                                        style: const TextStyle(fontSize: 14),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                              childCount: footprints.length,
                            ),
                          ),
                          // 하단에 로딩 표시기 추가
                          SliverToBoxAdapter(
                            child: _isFetching
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : !_hasNextPage && footprints.isNotEmpty
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}