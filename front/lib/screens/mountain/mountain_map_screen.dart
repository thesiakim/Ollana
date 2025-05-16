// mountain_map_screen.dart: 산 지도 화면
// - 한국 전체 지도 표시
// - 산 위치에 난이도별 마커 표시
// - 로컬 저장소 활용한 데이터 캐싱

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/app_state.dart';
import '../../models/mountain_map.dart';
import '../../services/mountain_map_service.dart';
import '../../utils/app_colors.dart';
import 'mountain_detail_screen.dart'; // 산 상세 화면 import

class MountainMapScreen extends StatefulWidget {
  const MountainMapScreen({Key? key}) : super(key: key);

  @override
  State<MountainMapScreen> createState() => _MountainMapScreenState();
}

class _MountainMapScreenState extends State<MountainMapScreen> {
  final MountainMapService _mountainMapService = MountainMapService();
  NaverMapController? _mapController;
  List<MountainMap> _mountains = [];
  bool _isLoading = true;
  MountainMap? _selectedMountain;
  Map<String, NOverlayImage>? _iconCache; // 기본 크기 아이콘
  Map<String, NOverlayImage>? _largeIconCache; // 확대된 크기 아이콘
  Map<String, NMarker> _markerCache = {}; // 마커 캐시
  String? _lastTappedMarkerId; // 마지막으로 탭한 마커 ID

  // 지도/리스트 보기 토글 관련 변수
  bool _isMapView = true; // 초기값은 지도 보기

  // 리스트 데이터 관련 변수
  List<dynamic> _mountainList = [];
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  final int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMountains();
    _loadMountainList();

    // 스크롤 리스너 추가 (무한 스크롤용)
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 무한 스크롤 리스너
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd) {
      _loadMoreMountains();
    }
  }

  // 산 정보 로드 (로컬 또는 API)
  Future<void> _loadMountains() async {
    try {
      setState(() => _isLoading = true);

      // 앱 상태에서 토큰 가져오기
      final token = context.read<AppState>().accessToken ?? '';

      // 서비스를 통해 산 정보 가져오기
      final mountains = await _mountainMapService.getMountains(token);

      setState(() {
        _mountains = mountains;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('산 정보를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  // 산 리스트 데이터 로드 (API)
  Future<void> _loadMountainList({bool resetList = false}) async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      if (resetList) {
        _currentPage = 0;
        _mountainList = [];
        _hasReachedEnd = false;
      }
    });

    try {
      // 앱 상태에서 토큰과 baseUrl 가져오기
      final appState = context.read<AppState>();
      final token = appState.accessToken ?? '';
      final baseUrl = dotenv.env['BASE_URL'] ?? '';

      // API URL 구성
      String url = '$baseUrl/mountain/list?page=$_currentPage&size=$_pageSize';
      if (_searchQuery.isNotEmpty) {
        url = '$baseUrl/mountain/list?search=$_searchQuery';
      }

      // API 요청
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> dataMap = jsonDecode(decoded);

        if (dataMap['status'] == true) {
          if (_searchQuery.isNotEmpty) {
            // 검색 결과는 데이터 구조가 다름
            final List<dynamic> mountains = dataMap['data'];
            setState(() {
              _mountainList = mountains;
              _isLoadingMore = false;
              _hasReachedEnd = true; // 검색 결과는 페이징 없음
            });
          } else {
            // 일반 리스트 데이터 구조 처리
            final data = dataMap['data'];
            final List<dynamic> mountains = data['mountains'];

            setState(() {
              if (resetList) {
                _mountainList = mountains;
              } else {
                _mountainList.addAll(mountains);
              }

              _currentPage = data['currentPage'];
              _totalPages = data['totalPages'];
              _hasReachedEnd =
                  data['last'] ?? (_currentPage >= _totalPages - 1);
              _isLoadingMore = false;
              _currentPage++;
            });
          }
        } else {
          setState(() => _isLoadingMore = false);
          _showErrorSnackBar('데이터를 불러오는데 실패했습니다.');
        }
      } else {
        setState(() => _isLoadingMore = false);
        _showErrorSnackBar('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
      _showErrorSnackBar('데이터 로드 중 오류 발생: $e');
    }
  }

  // 더 많은 산 데이터 로드 (무한 스크롤)
  Future<void> _loadMoreMountains() async {
    if (_searchQuery.isNotEmpty) return; // 검색 중에는 추가 로드 안함
    await _loadMountainList();
  }

  // 검색 수행
  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query.trim();
      _isSearching = _searchQuery.isNotEmpty;
    });
    await _loadMountainList(resetList: true);
  }

  // 검색 취소
  void _cancelSearch() {
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _searchController.clear();
    });
    _loadMountainList(resetList: true);
  }

  // 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // 산 정보 강제 새로고침 (API에서 다시 가져오기)
  Future<void> _refreshMountainData() async {
    try {
      // 로딩 상태 표시
      setState(() => _isLoading = true);

      debugPrint('▶ start get token');
      // 앱 상태에서 토큰 가져오기
      final token = context.read<AppState>().accessToken ?? '';
      debugPrint('✔ get token done: ${token.length > 0 ? "토큰 있음" : "토큰 없음"}');

      debugPrint('▶ start clearLocalData');
      // 로컬 캐시 데이터 삭제
      await _mountainMapService.clearLocalData();
      debugPrint('✔ clearLocalData done');

      debugPrint('▶ start fetchMountainsFromApi');
      // API에서 데이터 다시 가져오기
      final mountains = await _mountainMapService.fetchMountainsFromApi(token);
      debugPrint('✔ fetchMountainsFromApi done: ${mountains.length}개 산 데이터 수신');

      debugPrint('▶ start setState');
      setState(() {
        _mountains = mountains;
        _isLoading = false;
      });
      debugPrint('✔ setState done');

      // 지도에 업데이트된 데이터 표시
      debugPrint('▶ start showMountainsOnMap');
      if (_mapController != null) {
        await _showMountainsOnMap();
      }
      debugPrint('✔ showMountainsOnMap done');

      // 성공 메시지 표시
      debugPrint('▶ start show SnackBar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('산 정보가 업데이트되었습니다.')),
        );
      }
      debugPrint('✔ show SnackBar done');

      // 리스트 데이터도 새로고침
      _loadMountainList(resetList: true);
    } catch (e) {
      debugPrint('❌ 에러 발생: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('산 정보 업데이트 실패: $e')),
        );
      }
    }
  }

  // 난이도에 따른 마커 색상 설정
  Color _getLevelColor(String level) {
    switch (level) {
      case 'H':
        return const Color.fromARGB(255, 222, 46, 33);
      case 'M':
        return const Color.fromARGB(255, 238, 216, 21);
      case 'L':
        return const Color.fromARGB(255, 41, 195, 46);
      default:
        return Colors.blue;
    }
  }

  // 레벨별 일반 크기 아이콘 캐싱 함수
  Future<Map<String, NOverlayImage>> _prepareLevelIcons(
      BuildContext ctx) async {
    // 이미 캐시가 있으면 반환
    if (_iconCache != null) {
      return _iconCache!;
    }

    debugPrint('▶ start prepare level icons');
    final levels = ['H', 'M', 'L', 'default'];
    final cache = <String, NOverlayImage>{};

    for (var level in levels) {
      final color = _getLevelColor(level);
      cache[level] = await NOverlayImage.fromWidget(
        widget: Stack(
          alignment: Alignment.center,
          children: [
            // 흰색 배경 원
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(75),
                    blurRadius: 2,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            // 컬러 아이콘
            FaIcon(
              FontAwesomeIcons.solidCircleDot,
              color: color,
              size: 16,
            ),
          ],
        ),
        size: const Size(30, 30),
        context: ctx,
      );
    }

    _iconCache = cache;
    debugPrint('✔ prepared level icons');
    return cache;
  }

  // 레벨별 큰 크기 아이콘 캐싱 함수 (애니메이션용)
  Future<Map<String, NOverlayImage>> _prepareLargeLevelIcons(
      BuildContext ctx) async {
    // 이미 캐시가 있으면 반환
    if (_largeIconCache != null) {
      return _largeIconCache!;
    }

    debugPrint('▶ start prepare large level icons');
    final levels = ['H', 'M', 'L', 'default'];
    final cache = <String, NOverlayImage>{};

    for (var level in levels) {
      final color = _getLevelColor(level);
      cache[level] = await NOverlayImage.fromWidget(
        widget: Stack(
          alignment: Alignment.center,
          children: [
            // 흰색 배경 원 (확대 크기)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(75),
                    blurRadius: 2,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            // 컬러 아이콘 (확대 크기)
            FaIcon(
              FontAwesomeIcons.solidCircleDot,
              color: color,
              size: 22,
            ),
          ],
        ),
        size: const Size(42, 42),
        context: ctx,
      );
    }

    _largeIconCache = cache;
    debugPrint('✔ prepared large level icons');
    return cache;
  }

  // 네이버 지도에 산 마커 일괄 표시
  Future<void> _showMountainsOnMap() async {
    debugPrint('▶ start showMountainsOnMap');
    if (_mapController == null || _mountains.isEmpty) {
      debugPrint('❌ mapController 또는 mountains가 없음');
      return;
    }

    try {
      // 1. 오버레이 초기화
      debugPrint('- 오버레이 초기화');
      await _mapController!.clearOverlays();
      _markerCache.clear();
      _lastTappedMarkerId = null;

      // 2. 아이콘 캐시 가져오기
      debugPrint('- 아이콘 캐시 가져오기');
      final iconCache = await _prepareLevelIcons(context);

      // 큰 아이콘도 미리 준비 (애니메이션용)
      await _prepareLargeLevelIcons(context);

      // 3. 모든 NMarker 객체 생성
      debugPrint('- ${_mountains.length}개 마커 생성 시작');
      final overlays = <NAddableOverlay>{};
      for (var mountain in _mountains) {
        final icon = iconCache[mountain.level] ?? iconCache['default']!;
        final markerId = 'mountain-${mountain.id}';

        final marker = NMarker(
          id: markerId,
          position: NLatLng(mountain.latitude, mountain.longitude),
          icon: icon,
          caption: NOverlayCaption(
            text: mountain.name,
            textSize: 12,
            color: Colors.black,
          ),
          anchor: const NPoint(0.5, 0.5), // 마커의 중심이 정확히 좌표에 위치하도록
        );

        // 마커 클릭 이벤트 설정
        marker.setOnTapListener((overlay) {
          // 마커 애니메이션 효과 적용
          _handleMarkerTap(markerId, mountain.level);

          // 산 정보 바텀시트 표시
          _onMarkerTap(mountain);
        });

        // 마커 캐시에 저장
        _markerCache[markerId] = marker;

        overlays.add(marker);
      }
      debugPrint('- 마커 생성 완료');

      // 4. 일괄 추가
      debugPrint('- 마커 일괄 추가 시작');
      await _mapController!.addOverlayAll(overlays);
      debugPrint('- 마커 일괄 추가 완료');

      // 5. 카메라 이동
      debugPrint('- 카메라 이동 시작');
      await _mapController!.updateCamera(
        NCameraUpdate.fitBounds(
          NLatLngBounds(
            southWest: const NLatLng(33.0, 125.0), // 한반도 남서쪽
            northEast: const NLatLng(38.5, 132.0), // 한반도 북동쪽
          ),
          padding: const EdgeInsets.all(20),
        ),
      );
      debugPrint('- 카메라 이동 완료');

      debugPrint('✔ showMountainsOnMap 완료');
    } catch (e) {
      debugPrint('❌ showMountainsOnMap 오류: $e');
    }
  }

  // 마커 클릭 시 애니메이션 처리
  Future<void> _handleMarkerTap(String markerId, String level) async {
    debugPrint('마커 클릭: $markerId');

    try {
      // 이전에 클릭한 마커가 있고 현재 클릭한 마커와 다른 경우
      if (_lastTappedMarkerId != null && _lastTappedMarkerId != markerId) {
        // 이전 마커를 원래 크기로 복원
        final previousMarker = _markerCache[_lastTappedMarkerId];
        if (previousMarker != null && _iconCache != null) {
          final prevMountainId = int.parse(_lastTappedMarkerId!.split('-')[1]);
          final prevMountain =
              _mountains.firstWhere((m) => m.id == prevMountainId);
          previousMarker.setIcon(
              _iconCache![prevMountain.level] ?? _iconCache!['default']!);
        }
      }

      // 클릭한 마커를 확대된 크기로 변경
      final marker = _markerCache[markerId];
      if (marker != null && _largeIconCache != null) {
        marker.setIcon(_largeIconCache![level] ?? _largeIconCache!['default']!);
      }

      // 현재 클릭한 마커 ID 저장
      _lastTappedMarkerId = markerId;
    } catch (e) {
      debugPrint('마커 애니메이션 처리 중 오류: $e');
    }
  }

  // 마커 탭 시 산 정보 표시
  void _onMarkerTap(MountainMap mountain) {
    setState(() {
      _selectedMountain = mountain;
      _isMapView = false; // 리스트 뷰로 전환
    });

    // 검색창에 산 이름 설정하고 검색 수행
    _searchController.text = mountain.name;
    _performSearch(mountain.name);
  }

  // 리스트 아이템에서 산 정보 표시
  void _onMountainItemTap(dynamic mountain) {
    // 상세 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MountainDetailScreen(mountainId: mountain['id']),
      ),
    );
  }

  // 산 정보 바텀 시트
  Widget _buildMountainDetailSheet(MountainMap mountain) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  mountain.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLevelColor(mountain.level).withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '난이도: ${mountain.level}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getLevelColor(mountain.level),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '고도: ${mountain.altitude}m',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            '설명',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                mountain.description,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 리스트 아이템에서 산 정보 표시
  Widget _buildMountainListItem(dynamic mountain) {
    final images = mountain['images'] as List<dynamic>;
    final hasImage = images.isNotEmpty;

    return InkWell(
      onTap: () => _onMountainItemTap(mountain),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 (있는 경우만)
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[0],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.terrain, color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.terrain, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              // 산 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mountain['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                _getLevelColor(mountain['level']).withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '난이도: ${mountain['level']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getLevelColor(mountain['level']),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '고도: ${mountain['altitude']}m',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mountain['location'],
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 리스트 화면 위젯
  Widget _buildListView() {
    return Column(
      children: [
        // 검색 바
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '산 이름으로 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _cancelSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onSubmitted: _performSearch,
          ),
        ),

        // 리스트 내용
        Expanded(
          child: _mountainList.isEmpty && !_isLoadingMore
              ? const Center(child: Text('산 정보가 없습니다.'))
              : RefreshIndicator(
                  onRefresh: () => _loadMountainList(resetList: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _mountainList.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _mountainList.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _buildMountainListItem(_mountainList[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // 토글 버튼 위젯
  Widget _buildToggleButton() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: Icon(
          _isMapView ? Icons.list : Icons.map,
          color: Colors.white,
        ),
        onPressed: () {
          setState(() {
            _isMapView = !_isMapView;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 산 지도'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // 데이터 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '산 정보 새로고침',
            onPressed: _isLoading ? null : _refreshMountainData,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 지도 또는 리스트 뷰 (토글에 따라 표시)
          _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('산 정보를 불러오는 중...',
                          style: TextStyle(color: Colors.grey))
                    ],
                  ),
                )
              : _isMapView
                  ? NaverMap(
                      options: NaverMapViewOptions(
                        initialCameraPosition: NCameraPosition(
                          target: const NLatLng(36.0, 128.0), // 한국 중앙 좌표
                          zoom: 6,
                        ),
                        mapType: NMapType.basic,
                        contentPadding: const EdgeInsets.all(0),
                        logoAlign: NLogoAlign.rightBottom,
                        activeLayerGroups: [
                          NLayerGroup.mountain,
                          NLayerGroup.building,
                          NLayerGroup.transit,
                        ],
                      ),
                      onMapReady: (controller) {
                        _mapController = controller;
                        // 지도가 준비되면 산 마커 표시
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            _showMountainsOnMap();
                          }
                        });
                      },
                    )
                  : _buildListView(),

          // 토글 버튼 (항상 표시)
          _buildToggleButton(),
        ],
      ),
    );
  }
}
