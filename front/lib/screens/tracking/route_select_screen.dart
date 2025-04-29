// route_select_screen.dart: 등산로 선택 화면
// - 네이버 지도에 등산로 표시
// - 하단에 등산로 목록 표시
// - 등산로 선택 시 모드 선택 화면으로 이동

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';

// 현재 flutter_naver_map 라이브러리가 설치되지 않아 임시 UI로 대체
// 실제 구현 시 아래 주석을 해제하고 사용
// import 'package:flutter_naver_map/flutter_naver_map.dart';

class RouteSelectScreen extends StatefulWidget {
  const RouteSelectScreen({super.key});

  @override
  State<RouteSelectScreen> createState() => _RouteSelectScreenState();
}

class _RouteSelectScreenState extends State<RouteSelectScreen> {
  // NaverMapController? _mapController;
  final List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  int _selectedRouteIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  // 등산로 데이터 로드 (임시 데이터 사용)
  void _loadRouteData() {
    // 실제로는 API 호출로 대체
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        final mountainName =
            Provider.of<AppState>(context, listen: false).selectedMountain;

        // 임시 등산로 데이터
        _routes.addAll([
          {
            'name': '$mountainName 정상 코스',
            'difficulty': '중',
            'distance': '7.5km',
            'time': '약 4시간',
            'start': {'lat': 37.5665, 'lng': 126.9780},
            'end': {'lat': 37.5760, 'lng': 126.9876},
            'path': [
              {'lat': 37.5665, 'lng': 126.9780},
              {'lat': 37.5690, 'lng': 126.9800},
              {'lat': 37.5720, 'lng': 126.9830},
              {'lat': 37.5760, 'lng': 126.9876},
            ]
          },
          {
            'name': '$mountainName 초보자 코스',
            'difficulty': '하',
            'distance': '4.2km',
            'time': '약 2시간',
            'start': {'lat': 37.5665, 'lng': 126.9780},
            'end': {'lat': 37.5730, 'lng': 126.9850},
            'path': [
              {'lat': 37.5665, 'lng': 126.9780},
              {'lat': 37.5685, 'lng': 126.9810},
              {'lat': 37.5730, 'lng': 126.9850},
            ]
          },
          {
            'name': '$mountainName 전문가 코스',
            'difficulty': '상',
            'distance': '12.3km',
            'time': '약 6시간',
            'start': {'lat': 37.5665, 'lng': 126.9780},
            'end': {'lat': 37.5800, 'lng': 126.9900},
            'path': [
              {'lat': 37.5665, 'lng': 126.9780},
              {'lat': 37.5700, 'lng': 126.9820},
              {'lat': 37.5740, 'lng': 126.9850},
              {'lat': 37.5770, 'lng': 126.9880},
              {'lat': 37.5800, 'lng': 126.9900},
            ]
          },
        ]);

        _isLoading = false;
      });
    });
  }

  // 지도에 등산로 표시 (네이버 지도 SDK 설치 후 사용)
  /*
  void _drawRouteOnMap(NaverMapController controller) {
    if (_routes.isEmpty) return;
    
    controller.clearOverlays();
    
    for (int i = 0; i < _routes.length; i++) {
      final route = _routes[i];
      final path = route['path'] as List<Map<String, dynamic>>;
      final coordinates = path.map((point) => 
        LatLng(point['lat'] as double, point['lng'] as double)
      ).toList();
      
      // 등산로 그리기
      controller.addOverlay(
        PathOverlay(
          PathOverlayId('route_$i'),
          coordinates,
          width: 5,
          color: i == _selectedRouteIndex 
              ? Colors.red 
              : Colors.blue.withOpacity(0.7),
          outlineColor: Colors.white,
        ),
      );
      
      // 시작점 마커
      controller.addOverlay(
        Marker(
          markerId: MarkerId('start_$i'),
          position: coordinates.first,
          icon: i == _selectedRouteIndex 
              ? OverlayImage.fromAssetImage('lib/assets/images/marker_start_selected.png') 
              : OverlayImage.fromAssetImage('lib/assets/images/marker_start.png'),
        ),
      );
      
      // 종점 마커
      controller.addOverlay(
        Marker(
          markerId: MarkerId('end_$i'),
          position: coordinates.last,
          icon: i == _selectedRouteIndex 
              ? OverlayImage.fromAssetImage('lib/assets/images/marker_end_selected.png') 
              : OverlayImage.fromAssetImage('lib/assets/images/marker_end.png'),
        ),
      );
    }
    
    // 선택된 루트가 있으면 해당 루트로 카메라 이동
    if (_selectedRouteIndex >= 0 && _selectedRouteIndex < _routes.length) {
      final path = _routes[_selectedRouteIndex]['path'] as List<Map<String, dynamic>>;
      final coordinates = path.map((point) => 
        LatLng(point['lat'] as double, point['lng'] as double)
      ).toList();
      
      controller.moveCamera(
        CameraUpdate.fitBounds(
          LatLngBounds.fromLatLngList(coordinates),
          padding: 50,
        ),
      );
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${appState.selectedMountain} 등산로'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 산 선택 화면으로 돌아가기
            appState.resetTrackingStage();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 네이버 지도 (등산로 표시) - 임시 이미지로 대체
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text(
                        '지도 영역\n(네이버 지도 SDK 설치 후 구현)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),

                // 등산로 선택 영역
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '등산로 선택',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _routes.length,
                            itemBuilder: (context, index) {
                              final route = _routes[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 8),
                                color: _selectedRouteIndex == index
                                    ? Colors.blue.shade50
                                    : Colors.white,
                                child: ListTile(
                                  title: Text(route['name']),
                                  subtitle: Text(
                                    '난이도: ${route['difficulty']} • 거리: ${route['distance']} • 소요시간: ${route['time']}',
                                  ),
                                  trailing: _selectedRouteIndex == index
                                      ? ElevatedButton(
                                          onPressed: () {
                                            // 선택한 등산로로 진행
                                            appState.selectRoute(route['name']);
                                          },
                                          child: const Text('선택'),
                                        )
                                      : const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    setState(() {
                                      _selectedRouteIndex = index;
                                      // 네이버 지도 SDK 설치 후 주석 해제
                                      // if (_mapController != null) {
                                      //   _drawRouteOnMap(_mapController!);
                                      // }
                                    });
                                  },
                                ),
                              );
                            },
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
}
