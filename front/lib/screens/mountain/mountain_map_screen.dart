// mountain_map_screen.dart: 산 지도 화면
// - 한국 전체 지도 표시
// - 산 위치에 난이도별 마커 표시
// - 로컬 저장소 활용한 데이터 캐싱

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('산 정보를 불러오는데 실패했습니다: $e')),
        );
      }
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
    });

    // 바텀 시트로 산 정보 표시
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildMountainDetailSheet(mountain),
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
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('산 정보를 불러오는 중...', style: TextStyle(color: Colors.grey))
                ],
              ),
            )
          : NaverMap(
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
            ),
    );
  }
}
