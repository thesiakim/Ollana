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
import 'package:geolocator/geolocator.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<Mountain> _allMountains = [];
  List<Mountain> _filteredMountains = [];
  List<HikingRoute> _routes = [];

  Mountain? _selectedMountain;
  int _selectedRouteIndex = -1;

  bool _isSearching = false;
  bool _isLoading = true;
  bool _isLoadingRoutes = false;
  bool _isDataFromApi = false;

  // NaverMap 위젯이 다시 생성되도록 지도 상태를 관리하는 키
  // 타입 오류 해결: 정확한 타입 지정 대신 일반 GlobalKey 사용
  final GlobalKey _mapKey = GlobalKey();
  bool _shouldRebuildMap = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupSearchListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 선택된 산이 있으면 검색 필드에 표시
    if (_selectedMountain != null && _searchController.text.isEmpty) {
      _searchController.text = _selectedMountain!.name;
    }

    // AppState에서 산과 등산로 정보 확인
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.selectedMountain != null &&
        appState.selectedRoute != null &&
        !_isDataFromApi) {
      setState(() {
        _isDataFromApi = true;
      });

      // 이미 AppState에 데이터가 있으면 그것을 사용
      // _setMountainAndRouteFromAppState(appState);
    }
  }

  // AppState에서 선택된 산과 등산로 정보 가져오기
  // void _setMountainAndRouteFromAppState(AppState appState) {
  //   if (appState.selectedMountain != null && appState.selectedRoute != null) {
  //     // 산 정보 설정
  //     final mountain = Mountain(
  //       id: appState.selectedRoute!.mountainId,
  //       name: appState.selectedMountain!,
  //       location: '',
  //       height: 0.0,
  //     );

  //     setState(() {
  //       _selectedMountain = mountain;
  //       _routes = [appState.selectedRoute!];
  //       _selectedRouteIndex = 0; // 첫 번째 등산로 선택
  //       _isLoading = false;
  //       _isLoadingRoutes = false;
  //       _searchController.text = mountain.name;
  //     });
  //   }
  // }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    // 오버레이 제거
    _removeOverlay();
    super.dispose();
  }

  // 위치 권한 확인 및 요청
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 활성화되어 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.'),
        ),
      );
      return false;
    }

    // 위치 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 거부되었습니다.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 변경해주세요.'),
        ),
      );
      return false;
    }

    return true;
  }

  // 현재 위치 가져오기
  Future<Position?> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('현재 위치를 가져오는데 실패했습니다: $e')),
      );
      return null;
    }
  }

  // 초기 데이터 로드
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // 현재 위치 가져오기
      Position? position = await _getCurrentPosition();

      // 위치를 가져오지 못한 경우 서울 중심부 좌표 사용
      double latitude = position?.latitude ?? 37.5665;
      double longitude = position?.longitude ?? 126.9780;

      // 현재 위치 기반으로 주변 산 정보 가져오기
      final data =
          await _mountainService.getNearbyMountains(latitude, longitude);
      if (!mounted) return;

      // 하나의 산과 해당 산의 등산로만 표시
      final mountain = data.mountain;
      final routes = data.routes;

      if (!mounted) return;

      // 데이터가 로드되면 로딩 상태 종료
      setState(() {
        // 단일 산만 처리하도록 변경
        _allMountains = [mountain];
        _filteredMountains = [mountain];
        _isLoading = false;
        _selectedMountain = mountain;
        _routes = routes;

        // 선택된 산 이름을 검색창에 표시
        _searchController.text = mountain.name;

        // 기본적으로 첫 번째 등산로 선택
        if (_routes.isNotEmpty) {
          _selectedRouteIndex = 0;
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

  // 검색 리스너 설정
  void _setupSearchListener() {
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        // 포커스 얻으면 빈 검색어로 시작
        setState(() {
          _filteredMountains = _allMountains;
          _isSearching = true;
        });
        _showSearchResults();
      } else {
        // 포커스 잃으면 오버레이 제거
        _removeOverlay();
      }
    });

    _searchController.addListener(() {
      _searchMountains(_searchController.text);

      // 검색어 입력 중에 포커스가 있으면 오버레이 표시
      if (_searchFocusNode.hasFocus) {
        _showSearchResults();
      }
    });
  }

  // 서버에서 산 검색
  void _searchMountains(String query) async {
    if (query.isEmpty) {
      setState(() => _filteredMountains = _allMountains);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ★ AppState에서 토큰 꺼내기
      final token = context.read<AppState>().accessToken ?? '';

      // ★ 수정된 서비스 호출: query와 token 전달
      final mountains = await _mountainService.searchMountains(query, token);

      if (!mounted) return;
      setState(() {
        _filteredMountains = mountains;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('산 검색 오류: $e');
      if (mounted)
        setState(() {
          _filteredMountains = [];
          _isLoading = false;
        });
    }
  }

  // 검색 결과 오버레이 표시
  void _showSearchResults() {
    _removeOverlay(); // 기존 오버레이 제거

    // 검색창의 RenderBox를 찾아 크기와 위치 정보 가져오기
    final RenderBox? renderBox =
        _searchFocusNode.context?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 오버레이 외부 영역에 대한 GestureDetector (오버레이 닫기용)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _searchFocusNode.unfocus();
                _removeOverlay();
              },
              // 완전 투명한 배경
              child: Container(color: Colors.transparent),
            ),
          ),
          // 실제 검색 결과 오버레이
          Positioned(
            top: position.dy + size.height + 10,
            left: 12.0,
            right: 12.0,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _filteredMountains.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        child: const Text('검색 결과가 없습니다.'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredMountains.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final mountain = _filteredMountains[index];
                          return ListTile(
                            title: Text(
                              mountain.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            trailing: Text(
                              '${mountain.height}m',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            dense: true,
                            onTap: () {
                              _selectMountain(mountain);
                            },
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // 오버레이 업데이트
  void _updateOverlay() {
    _removeOverlay();
    _showSearchResults();
  }

  // 오버레이 제거
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // 산 선택 처리
  void _selectMountain(Mountain mountain) {
    _searchController.text = mountain.name;
    _searchFocusNode.unfocus();
    _removeOverlay();

    // 검색 결과에서 선택한 산의 상세 정보 가져오기
    _loadSelectedMountainData(mountain.name);
  }

  // 검색 결과에서 선택한 산의 상세 정보 가져오기
  Future<void> _loadSelectedMountainData(String mountainName) async {
    // 지도를 다시 생성하기 위한 설정
    _shouldRebuildMap = true;

    // 로딩 상태 설정
    setState(() {
      _isLoadingRoutes = true;
      _isSearching = false;
      _routes = []; // 기존 경로 초기화
    });

    try {
      // 선택한 산의 상세 정보를 새 API로 가져오기
      final data = await _mountainService.getMountainByName(mountainName);
      debugPrint(
          '산 데이터 수신 성공: ${data.mountain.name}, 등산로 수: ${data.routes.length}');

      if (!mounted) return;

      // 산과 등산로 정보 유효성 검사 - 산 이름만 있으면 표시
      // 빈 ID도 허용하도록 수정
      if (data.mountain.name.isEmpty) {
        throw Exception('산 이름 정보가 없습니다');
      }

      debugPrint(
          '산 데이터 수신 성공: ${data.mountain.name}, 등산로 수: ${data.routes.length}');

      // 산과 등산로 정보 업데이트
      setState(() {
        _selectedMountain = data.mountain;
        _routes = data.routes;
        _isLoadingRoutes = false;

        // 첫 번째 등산로 선택
        if (_routes.isNotEmpty) {
          _selectedRouteIndex = 0;
          debugPrint('첫번째 등산로 선택: ${_routes[0].name}');
        } else {
          _selectedRouteIndex = -1;
          debugPrint('사용 가능한 등산로가 없습니다');
        }
      });
    } catch (e) {
      debugPrint('산 상세 정보 로드 오류: $e');

      if (!mounted) return;

      // 오류 발생 시 처리
      setState(() {
        _isLoadingRoutes = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('산 상세 정보를 불러오는데 실패했습니다: $e')),
      );

      // 오류 발생 시 기존 방식으로 데이터 로드 시도
      _loadRouteData(Mountain(
        id: '',
        name: mountainName,
        location: '',
        height: 0,
      ));
    }
  }

  // 산 선택 시 등산로 데이터 로드 (UI 업데이트 부분)
  void _loadRouteData(Mountain mountain) {
    // 지도를 완전히 다시 생성하도록 설정
    _shouldRebuildMap = true;

    setState(() {
      _isLoadingRoutes = true;
      _selectedMountain = mountain;
      _selectedRouteIndex = -1;
      _isSearching = false;

      // 선택한 산 이름을 검색 필드에 설정
      _searchController.text = mountain.name;

      // 이전 경로 데이터 초기화 (산이 변경되었을 때 기존 경로 데이터 지우기)
      _routes = [];
    });

    _fetchRoutesForMountain(mountain);
  }

  // 산의 등산로 데이터 비동기 로드 (분리된 비동기 함수)
  Future<void> _fetchRoutesForMountain(Mountain mountain) async {
    setState(() {
      _isLoadingRoutes = true;
    });

    try {
      // 현재 위치 가져오기
      Position? position = await _getCurrentPosition();

      // 위치를 가져오지 못한 경우 서울 중심부 좌표 사용
      double latitude = position?.latitude ?? 37.5665;
      double longitude = position?.longitude ?? 126.9780;

      debugPrint("위치 좌표: $latitude, $longitude");

      // 현재 위치 기반으로 주변 산 정보 가져오기
      final result =
          await _mountainService.getNearbyMountains(latitude, longitude);
      if (!mounted) return;

      // 모든 등산로 정보를 미리 처리
      final List<HikingRoute> processedRoutes = [...result.routes];

      // 안전하게 상태 업데이트 (모든 데이터 처리 후 한 번에 업데이트)
      if (mounted) {
        setState(() {
          _routes = processedRoutes;
          _isLoadingRoutes = false;

          // 검색창에 선택된 산 이름 표시 확인
          if (_searchController.text != mountain.name) {
            _searchController.text = mountain.name;
          }

          // 기본적으로 첫 번째 등산로 선택 (경로가 있는 경우에만)
          if (_routes.isNotEmpty) {
            _selectedRouteIndex = 0;
          } else {
            debugPrint("사용 가능한 등산로가 없습니다");
          }
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint("등산로 데이터 로드 오류: $e");
      setState(() => _isLoadingRoutes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등산로 데이터를 불러오는데 실패했습니다: $e')),
      );
    }
  }

  // 등산로 선택 시 맵 업데이트
  void _updateMapWithSelectedRoute(int index) {
    // 안전하게 상태에 접근
    if (_mapKey.currentContext != null) {
      // 위젯 트리에서 RouteMapWidget의 상태를 찾음
      final state = (_mapKey.currentContext!
          .findAncestorStateOfType<_RouteMapWidgetState>());
      if (state != null) {
        state.updateSelectedRoute(index);
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

  @override
  Widget build(BuildContext context) {
    // 지도를 다시 생성해야 하는 경우 키를 변경
    if (_shouldRebuildMap) {
      _shouldRebuildMap = false;
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: AppBar(
            title: Row(
              children: [
                Expanded(
                  child: CompositedTransformTarget(
                    link: _layerLink,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: '산 이름 검색...',
                        hintStyle: TextStyle(
                          color: Colors.white.withAlpha(70),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Padding(
                          padding: EdgeInsets.zero,
                          child: Icon(
                            Icons.search,
                            color: Colors.white.withAlpha(70),
                            size: 20,
                          ),
                        ),
                        prefixIconConstraints: BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textInputAction: TextInputAction.search,
                      onTap: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(100),
              ),
            ),
            elevation: 0,
            titleSpacing: 10,
            toolbarHeight: kToolbarHeight - 8,
          ),
        ),
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
              // 경로 시각화
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        child: RouteMapWidget(
                          // 산이 변경될 때만 키를 변경 (경로 변경 시에는 변경 안함)
                          key: _mapKey,
                          mountain: _selectedMountain,
                          routes: _routes,
                          selectedRouteIndex: _selectedRouteIndex,
                        ),
                      ),
              ),

              // 등산로 목록
              Expanded(
                child: _isLoadingRoutes
                    ? const Center(child: CircularProgressIndicator())
                    : _routes.isEmpty
                        ? const Center(child: Text('등산로 정보가 없습니다.'))
                        : ListView(
                            children: _routes.map((route) {
                              final index = _routes.indexOf(route);
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
                                    // 경로 선택 시 지도 업데이트
                                    _updateMapWithSelectedRoute(index);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 6.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                route.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getRouteColor(
                                                        route.difficulty)
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
                                        const SizedBox(height: 4),
                                        Text(
                                          '거리: ${route.distance}km • 예상 소요시간: ${route.estimatedTime}분',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
              ),

              // 선택 버튼
              if (_selectedRouteIndex >= 0)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _proceedToModeSelect,
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

  // 선택한 산과 등산로 정보를 AppState에 저장하고 다음 단계로 진행
  void _proceedToModeSelect() {
    if (_selectedRouteIndex >= 0 && _selectedRouteIndex < _routes.length) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.selectMountain(_selectedMountain!.name);
      appState.selectRoute(_routes[_selectedRouteIndex]);
    }
  }
}

// 경로 지도 표시를 위한 별도의 StatefulWidget
class RouteMapWidget extends StatefulWidget {
  final Mountain? mountain;
  final List<HikingRoute> routes;
  final int selectedRouteIndex;

  const RouteMapWidget({
    super.key,
    required this.mountain,
    required this.routes,
    required this.selectedRouteIndex,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  NaverMapController? _mapController;
  int _currentSelectedRouteIndex = -1;

  @override
  void initState() {
    super.initState();
    _currentSelectedRouteIndex = widget.selectedRouteIndex;
  }

  @override
  void didUpdateWidget(RouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 선택된 경로가 변경된 경우에만 지도 업데이트
    if (widget.selectedRouteIndex != _currentSelectedRouteIndex) {
      _currentSelectedRouteIndex = widget.selectedRouteIndex;
      if (_mapController != null) {
        _showAllRoutesOnMap();
      }
    }
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  // 외부에서 선택된 경로를 업데이트할 수 있는 메서드
  void updateSelectedRoute(int index) {
    if (mounted) {
      setState(() {
        _currentSelectedRouteIndex = index;
      });
      if (_mapController != null) {
        _showAllRoutesOnMap();
      }
    }
  }

  // 산별 초기 지도 위치 설정
  NLatLng _getInitialMapPosition() {
    if (widget.mountain == null) {
      // 기본 위치 (북한산)
      return NLatLng(37.6584, 126.9443);
    }

    // 산 ID에 따라 다른 초기 위치 반환
    switch (widget.mountain!.id) {
      case 'm1': // 북한산
        return NLatLng(37.6584, 126.9443);
      case 'm2': // 설악산
        return NLatLng(38.1200, 128.4700);
      case 'm3': // 지리산
        return NLatLng(35.3300, 127.7200);
      default:
        // 기본 위치 (서울)
        return NLatLng(37.5665, 126.9780);
    }
  }

  void _showAllRoutesOnMap() {
    if (_mapController == null || widget.routes.isEmpty) {
      return;
    }

    try {
      // 기존 오버레이 삭제
      _mapController!.clearOverlays();

      // 모든 등산로의 경로 표시
      List<NLatLng> allPoints = [];

      for (int i = 0; i < widget.routes.length; i++) {
        final route = widget.routes[i];
        // 경로 데이터 유효성 검사
        if (route.path.isEmpty) {
          debugPrint('경로 ${route.name}에 유효한 경로 데이터가 없습니다.');
          continue;
        }

        try {
          // 경로 좌표를 NLatLng 리스트로 변환
          final path = route.path.map((coord) {
            // null 체크 추가
            final lat = coord['latitude'];
            final lng = coord['longitude'];
            if (lat == null || lng == null) {
              throw Exception('경로 좌표에 null 값이 있습니다');
            }
            return NLatLng(lat, lng);
          }).toList();

          if (path.isEmpty) {
            debugPrint('경로 ${route.name}의 좌표 변환 결과가 비어있습니다.');
            continue;
          }

          allPoints.addAll(path);

          // 경로 오버레이 추가 (선택되지 않은 경로는 회색으로 표시)
          _mapController!.addOverlay(
            NPathOverlay(
              id: 'route-path-$i',
              coords: path,
              color: i == _currentSelectedRouteIndex
                  ? AppColors.primary
                  : Colors.grey.withAlpha(70),
              width: i == _currentSelectedRouteIndex ? 5 : 3,
              outlineWidth: i == _currentSelectedRouteIndex ? 2 : 1,
              outlineColor: Colors.white,
            ),
          );

          // 시작점과 종점 마커 추가 (선택된 경로만)
          if (i == _currentSelectedRouteIndex && path.isNotEmpty) {
            _mapController!.addOverlay(
              NMarker(
                id: 'start-point-$i',
                position: path.first,
                caption: const NOverlayCaption(
                  text: '시작점',
                  textSize: 12,
                ),
              ),
            );

            _mapController!.addOverlay(
              NMarker(
                id: 'end-point-$i',
                position: path.last,
                caption: const NOverlayCaption(
                  text: '종점',
                  textSize: 12,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('경로 ${route.name} 처리 중 오류 발생: $e');
          continue; // 오류가 있는 경로는 건너뛰고 계속 진행
        }
      }

      // 모든 경로가 보이도록 카메라 이동 (경로가 있는 경우)
      if (allPoints.isNotEmpty) {
        try {
          // 모든 경로의 바운딩 박스 계산
          double minLat = double.infinity;
          double maxLat = -double.infinity;
          double minLng = double.infinity;
          double maxLng = -double.infinity;

          for (var point in allPoints) {
            minLat = point.latitude < minLat ? point.latitude : minLat;
            maxLat = point.latitude > maxLat ? point.latitude : maxLat;
            minLng = point.longitude < minLng ? point.longitude : minLng;
            maxLng = point.longitude > maxLng ? point.longitude : maxLng;
          }

          // 지도 카메라 업데이트
          _mapController!.updateCamera(
            NCameraUpdate.fitBounds(
              NLatLngBounds(
                southWest: NLatLng(minLat, minLng),
                northEast: NLatLng(maxLat, maxLng),
              ),
              padding: const EdgeInsets.all(50),
            ),
          );
        } catch (e) {
          debugPrint('카메라 업데이트 중 오류 발생: $e');
        }
      }
    } catch (e) {
      debugPrint('지도에 경로 표시 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: _getInitialMapPosition(),
          zoom: 12.0,
        ),
        mapType: NMapType.terrain,
        contentPadding: const EdgeInsets.all(0),
        logoAlign: NLogoAlign.rightBottom,
        activeLayerGroups: [
          NLayerGroup.mountain,
          NLayerGroup.building,
          NLayerGroup.transit,
          NLayerGroup.cadastral,
        ],
      ),
      onMapReady: (controller) {
        _mapController = controller;

        // 지도 준비가 완료된 후 약간의 지연을 주고 경로 표시
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showAllRoutesOnMap();
          }
        });
      },
    );
  }
}
