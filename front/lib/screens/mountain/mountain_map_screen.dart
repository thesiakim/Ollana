import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../../models/app_state.dart';
import '../../models/mountain_map.dart';
import '../../services/mountain_map_service.dart';
import '../../utils/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMountains();
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
        _showSnackBar('산 정보를 불러오는데 실패했습니다: $e');
      }
    }
  }

  // 스낵바 표시 함수
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
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
        _showSnackBar('산 정보가 업데이트되었습니다.');
      }
      debugPrint('✔ show SnackBar done');
    } catch (e) {
      debugPrint('❌ 에러 발생: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('산 정보 업데이트 실패: $e');
      }
    }
  }

  // 난이도에 따른 마커 색상 설정
  Color _getLevelColor(String level) {
    switch (level) {
      case 'H':
        return const Color(0xFFE63946); // 세련된 빨간색
      case 'M':
        return const Color(0xFFFFB703); // 세련된 노란색
      case 'L':
        return const Color(0xFF2A9D8F); // 세련된 녹색
      default:
        return const Color(0xFF457B9D); // 세련된 파란색
    }
  }

  // 난이도 텍스트 변환
  String _getLevelText(String level) {
    switch (level) {
      case 'H':
        return '어려움';
      case 'M':
        return '보통';
      case 'L':
        return '쉬움';
      default:
        return '보통';
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
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            // 컬러 아이콘
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
        size: const Size(32, 32),
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
            // 확대 애니메이션 효과 - 바깥 원
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
            // 흰색 배경 원 (확대 크기)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            // 컬러 아이콘 (확대 크기)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(100),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        size: const Size(48, 48),
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
            color: Colors.black87,
            haloColor: Colors.white,
            minZoom: 8,  // 일정 줌 레벨 이상에서만 이름 표시
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
    });

    // 바텀 시트로 산 정보 표시
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMountainDetailSheet(mountain),
    );
  }

  // 인포카드 위젯 생성 함수
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 산 정보 바텀 시트
  Widget _buildMountainDetailSheet(MountainMap mountain) {
    final levelColor = _getLevelColor(mountain.level);
    
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.1,
      ),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더 (이미지 제거하고 산 이름과 닫기 버튼만 유지)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Stack(
                      children: [
                        // 산 이름 및 아이콘
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: levelColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.terrain,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                mountain.name,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // 닫기 버튼
                        Positioned(
                          top: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black.withOpacity(0.1),
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.black54),
                              onPressed: () => Navigator.of(context).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 정보 카드 섹션
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // 고도 정보 카드
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.height,
                            title: '높이',
                            value: '${mountain.altitude}m',
                            color: levelColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 난이도 정보 카드
                        Expanded(
                          child: _buildInfoCard(
                            icon: _getDifficultyIcon(mountain.level),
                            title: '난이도',
                            value: _getLevelText(mountain.level),
                            color: levelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 설명 섹션
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '상세 설명',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            mountain.description,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.black87.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 하단 버튼
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // 지도에서 확인 버튼
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _moveToMountain(mountain);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: levelColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              '지도에서 확인하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 난이도에 따른 아이콘 선택
  IconData _getDifficultyIcon(String level) {
    switch (level) {
      case 'H':
        return Icons.trending_up;
      case 'M':
        return Icons.trending_flat;
      case 'L':
        return Icons.trending_down;
      default:
        return Icons.landscape;
    }
  }
  
  // 선택한 산으로 지도 카메라 이동
  void _moveToMountain(MountainMap mountain) {
    if (_mapController != null) {
      _mapController!.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: NLatLng(mountain.latitude, mountain.longitude),
          zoom: 13,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 네이버 지도
          _isLoading
              ? const SizedBox.expand()
              : NaverMap(
                  options: NaverMapViewOptions(
                    initialCameraPosition: NCameraPosition(
                      target: const NLatLng(36.0, 128.0), // 한국 중앙 좌표
                      zoom: 6,
                    ),
                    mapType: NMapType.basic,
                    contentPadding: const EdgeInsets.only(top: 100, bottom: 20),
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
                ),
          
          // 상단 앱바 (투명 배경 + 블러 효과)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      // 뒤로 가기 버튼
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black87,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: '뒤로 가기',
                          iconSize: 20,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // 제목
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '전체 산 지도',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${_mountains.isEmpty ? "로딩 중..." : "${_mountains.length}개의 산"} 표시',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 새로고침 버튼
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: _isLoading ? Colors.grey : AppColors.primary,
                          ),
                          onPressed: _isLoading ? null : _refreshMountainData,
                          tooltip: '산 정보 새로고침',
                          iconSize: 20,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 로딩 인디케이터
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.7),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '산 정보를 불러오는 중...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
          // 하단 범례
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('쉬움', _getLevelColor('L')),
                    _buildLegendItem('보통', _getLevelColor('M')),
                    _buildLegendItem('어려움', _getLevelColor('H')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 하단 범례 아이템
  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}