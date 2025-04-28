// mountain_route_screen.dart: 산 검색 및 등산로 선택 위젯
// - 산 검색 기능 제공
// - 선택된 산의 등산로 목록 표시
// - 등산로 선택 및 상세 정보 확인 기능

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../../models/mountain.dart';
import '../../models/hiking_route.dart';
import '../../models/app_state.dart';
import '../../services/mountain_service.dart';
import '../../utils/app_colors.dart';
// import 'route_painter.dart';

class MountainRouteScreen extends StatefulWidget {
  final Function(Mountain, HikingRoute) onRouteSelected;

  const MountainRouteScreen({
    super.key,
    required this.onRouteSelected,
  });

  @override
  State<MountainRouteScreen> createState() => _MountainRouteScreenState();
}

class _MountainRouteScreenState extends State<MountainRouteScreen> {
  final MountainService _mountainService = MountainService();
  final TextEditingController _searchController = TextEditingController();

  List<Mountain> _allMountains = [];
  List<Mountain> _filteredMountains = [];
  List<HikingRoute> _routes = [];

  Mountain? _selectedMountain;
  int _selectedRouteIndex = -1;

  bool _isSearching = false;
  bool _isLoading = true;
  bool _isLoadingRoutes = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 초기 데이터 로드
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final mountains = await _mountainService.getMountains();
      if (!mounted) return;

      // AppState를 통해 이전에 선택된 산이 있는지 확인
      final appState = Provider.of<AppState>(context, listen: false);
      final previouslySelectedMountainName = appState.selectedMountain;

      setState(() {
        _allMountains = mountains;
        _filteredMountains = mountains;
        _isLoading = false;

        // 이전에 선택된 산이 있으면 그 산을 찾아서 선택
        if (previouslySelectedMountainName != null) {
          try {
            final selectedMountain = mountains.firstWhere(
              (m) => m.name == previouslySelectedMountainName,
              orElse: () => mountains.first,
            );
            _selectedMountain = selectedMountain;
            _fetchRoutesForMountain(selectedMountain);
            return; // 이미 산을 선택했으므로 기본 산 선택 로직은 실행하지 않음
          } catch (e) {
            debugPrint('이전 선택 산 검색 오류: $e');
          }
        }

        // 기본으로 북한산 선택 (ID가 m1인 산을 찾음)
        if (mountains.isNotEmpty) {
          try {
            final defaultMountain = mountains.firstWhere(
              (m) => m.id == 'm1',
              orElse: () => mountains.first,
            );
            _selectedMountain = defaultMountain;
            _fetchRoutesForMountain(defaultMountain);
          } catch (e) {
            debugPrint('기본 산 선택 오류: $e');
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('산 데이터를 불러오는데 실패했습니다: $e')),
      );
    }
  }

  // 산 목록 필터링
  void _filterMountainList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMountains = _allMountains;
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredMountains = _allMountains
            .where((mountain) =>
                mountain.name.toLowerCase().contains(query.toLowerCase()) ||
                mountain.location.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // 산 선택 시 등산로 데이터 로드 (UI 업데이트 부분)
  void _loadRouteData(Mountain mountain) {
    setState(() {
      _isLoadingRoutes = true;
      _selectedMountain = mountain;
      _selectedRouteIndex = -1;
      _isSearching = false;
      _searchController.clear();
    });

    _fetchRoutesForMountain(mountain);
  }

  // 산의 등산로 데이터 비동기 로드 (분리된 비동기 함수)
  Future<void> _fetchRoutesForMountain(Mountain mountain) async {
    try {
      final routes = await _mountainService.getRoutes(mountain.id);
      if (!mounted) return;

      setState(() {
        _routes = routes;
        _isLoadingRoutes = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingRoutes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등산로 데이터를 불러오는데 실패했습니다: $e')),
      );
    }
  }

  // 등산로 선택 완료
  void _completeRouteSelection() {
    if (_selectedMountain != null &&
        _selectedRouteIndex >= 0 &&
        _selectedRouteIndex < _routes.length) {
      try {
        widget.onRouteSelected(
            _selectedMountain!, _routes[_selectedRouteIndex]);
      } catch (e) {
        debugPrint('등산로 선택 오류: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등산로 선택 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 난이도별 색상 설정
  Color _getRouteColor(String difficulty) {
    switch (difficulty) {
      case '상':
        return Colors.red;
      case '중':
        return Colors.orange;
      case '하':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  // 필터링된 산 목록을 표시하는 팝업 빌드
  void _showMountainSearchPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('산 선택'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '산 이름 또는 지역으로 검색',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _filterMountainList,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredMountains.isEmpty
                        ? const Center(child: Text('검색 결과가 없습니다.'))
                        : ListView.builder(
                            itemCount: _filteredMountains.length,
                            itemBuilder: (context, index) {
                              final mountain = _filteredMountains[index];
                              return ListTile(
                                title: Text(mountain.name),
                                subtitle: Text(mountain.location),
                                onTap: () {
                                  Navigator.pop(context);
                                  _loadRouteData(mountain);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(_selectedMountain?.name ?? '등산로 선택'),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showMountainSearchPopup,
              tooltip: '다른 산 검색하기',
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading || (_selectedMountain == null && !_isSearching)
          ? const Center(child: CircularProgressIndicator())
          : _isSearching && _selectedMountain == null
              ? _buildMountainList()
              : _buildRouteContent(),
    );
  }

  // 산 목록 화면
  Widget _buildMountainList() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _filteredMountains.isEmpty
            ? const Center(child: Text('검색 결과가 없습니다.'))
            : ListView.builder(
                itemCount: _filteredMountains.length,
                itemBuilder: (context, index) {
                  final mountain = _filteredMountains[index];
                  final isSelected = _selectedMountain?.id == mountain.id;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    child: ListTile(
                      title: Text(
                        mountain.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(mountain.location),
                      trailing: Text(
                        '${mountain.height}m',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withAlpha(20),
                      onTap: () {
                        _loadRouteData(mountain);
                      },
                    ),
                  );
                },
              );
  }

  // 등산로 목록 및 시각화 화면
  Widget _buildRouteContent() {
    return _isLoadingRoutes
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // 산 정보 헤더
              Container(
                padding: const EdgeInsets.all(16.0),
                color: AppColors.primary.withAlpha(10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedMountain?.name ?? '선택된 산 없음',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedMountain?.location ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_selectedMountain?.height ?? 0}m',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // 경로 시각화
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _routes.isEmpty
                    ? const Center(child: Text('등산로 정보가 없습니다.'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: NaverMap(
                          options: NaverMapViewOptions(
                            initialCameraPosition: NCameraPosition(
                              target: NLatLng(37.6584, 126.9443), // 북한산 좌표로 변경
                              zoom: 12.0, // 넓은 영역을 보기 위해 줌 레벨 조정
                            ),
                            mapType: NMapType.terrain,
                            contentPadding: const EdgeInsets.all(0),
                            logoAlign: NLogoAlign.rightBottom,
                            activeLayerGroups: [
                              NLayerGroup.mountain,
                              NLayerGroup.building,
                              NLayerGroup.transit,
                              NLayerGroup.bicycle,
                              NLayerGroup.cadastral,
                            ],
                          ),
                          onMapReady: (controller) {
                            debugPrint('네이버 지도가 준비되었습니다.');

                            // 테스트용 마커 추가
                            controller.addOverlay(
                              NMarker(
                                id: 'test-marker',
                                position: NLatLng(37.6584, 126.9443), // 북한산 좌표
                              ),
                            );
                          },
                        ),
                      ),
              ),

              // 등산로 목록
              Expanded(
                child: _routes.isEmpty
                    ? const Center(child: Text('등산로 정보가 없습니다.'))
                    : ListView.builder(
                        itemCount: _routes.length,
                        itemBuilder: (context, index) {
                          final route = _routes[index];
                          final isSelected = index == _selectedRouteIndex;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() => _selectedRouteIndex = index);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            route.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                _getRouteColor(route.difficulty)
                                                    .withAlpha(20),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '난이도: ${route.difficulty}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _getRouteColor(
                                                  route.difficulty),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '거리: ${route.distance}km • 예상 소요시간: ${route.estimatedTime}분',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      route.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // 선택 버튼
              if (_selectedRouteIndex >= 0)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _completeRouteSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '등산로 선택하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
  }
}
