import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import '../../utils/app_colors.dart';

class MountainDetailScreen extends StatefulWidget {
  final int mountainId;

  const MountainDetailScreen({Key? key, required this.mountainId})
      : super(key: key);

  @override
  State<MountainDetailScreen> createState() => _MountainDetailScreenState();
}

class _MountainDetailScreenState extends State<MountainDetailScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _mountainData = {};
  int _currentImageIndex = 0;
  NaverMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadMountainDetail();
  }

  // 산 상세 정보 로드
  Future<void> _loadMountainDetail() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? '';
      final url = Uri.parse('$baseUrl/mountain/detail/${widget.mountainId}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decoded);

        if (data['status'] == true) {
          setState(() {
            _mountainData = data['data'];
            _isLoading = false;
          });

          // 데이터 디버깅
          print('산 상세 데이터 로드 완료: ${_mountainData['name']}');
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = '데이터를 불러오는데 실패했습니다.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '서버 오류: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '데이터 로드 중 오류 발생: $e';
      });
      print('산 상세 정보 로드 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingView()
          : _hasError
              ? _buildErrorView()
              : _buildDetailListView(),
    );
  }

  // 로딩 화면
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('산 정보를 불러오는 중...'),
        ],
      ),
    );
  }

  // 오류 화면
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMountainDetail,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  // 상세 정보 화면
  Widget _buildDetailListView() {
    final List<dynamic> images = _mountainData['images'] ?? [];
    return ListView(
      children: [
        // 이미지 슬라이더
        Container(
          width: double.infinity,
          height: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              images.isNotEmpty
                  ? CarouselSlider.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index, realIndex) {
                        final imageUrl = images[index];
                        final safeUrl = getImageUrl(imageUrl);
                        return Image.network(
                          safeUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.grey),
                              ),
                            );
                          },
                        );
                      },
                      options: CarouselOptions(
                        height: 300,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        enableInfiniteScroll: images.length > 1,
                        autoPlay: false,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        scrollPhysics: const BouncingScrollPhysics(),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child:
                            Icon(Icons.landscape, size: 64, color: Colors.grey),
                      ),
                    ),
              // 이미지 위에 그라데이션 효과
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // 이미지 인디케이터
              if (images.length > 1)
                Positioned(
                  bottom: 16.0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => Container(
                        width: index == _currentImageIndex ? 16 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index == _currentImageIndex
                              ? Colors.white
                              : Colors.white54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              // 뒤로가기 버튼
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: ClipOval(
                  child: Material(
                    color: Colors.black.withOpacity(0.3),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: '뒤로가기',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 아래 정보들
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildWeatherInfo(),
              const SizedBox(height: 24),
              _buildPathMapSection(),
              const SizedBox(height: 24),
              _buildDescriptionSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  // 기본 정보 섹션
  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 산 이름 및 난이도
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _mountainData['name'] ?? '산 이름',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    _getLevelColor(_mountainData['level'] ?? 'M').withAlpha(50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '난이도: ${_mountainData['level'] ?? '-'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(_mountainData['level'] ?? 'M'),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 위치
        Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _mountainData['location'] ?? '위치 정보 없음',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // 고도
        Row(
          children: [
            const Icon(Icons.height, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '해발 ${_mountainData['altitude']?.toStringAsFixed(1) ?? '0'}m',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),

        // 일출/일몰 정보 (있는 경우만)
        if (_mountainData['weather']?['sunrise'] != null &&
            _mountainData['weather']?['sunset'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny, size: 18, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '일출 ${_mountainData['weather']?['sunrise'] ?? '-'} / 일몰 ${_mountainData['weather']?['sunset'] ?? '-'}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 날씨 정보 섹션
  Widget _buildWeatherInfo() {
    final List<dynamic> dailyWeather =
        _mountainData['weather']?['dailyWeather'] ?? [];

    if (dailyWeather.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '날씨 정보',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // 날씨 카드 목록
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(4),
            itemCount:
                dailyWeather.length > 5 ? 5 : dailyWeather.length, // 최대 5일치만 표시
            itemBuilder: (context, index) {
              final weather = dailyWeather[index];
              final date = weather['date'] ?? '';
              final minTemp =
                  weather['temperatureMin']?.toStringAsFixed(1) ?? '-';
              final maxTemp =
                  weather['temperatureMax']?.toStringAsFixed(1) ?? '-';
              final weatherIcon = weather['weather']?['icon'] ?? '01d';
              final weatherDesc = weather['weather']?['description'] ?? '';

              // 날짜 포맷팅
              String dayText = '오늘';
              if (date.isNotEmpty) {
                final dateTime = DateTime.parse(date);
                final today = DateTime.now();
                final difference = dateTime.difference(today).inDays;

                if (difference == 0) {
                  dayText = '오늘';
                } else if (difference == 1) {
                  dayText = '내일';
                } else {
                  // 요일 구하기 (0: 월, 1: 화, ... 6: 일)
                  final weekday = dateTime.weekday;
                  switch (weekday) {
                    case 1:
                      dayText = '월';
                      break;
                    case 2:
                      dayText = '화';
                      break;
                    case 3:
                      dayText = '수';
                      break;
                    case 4:
                      dayText = '목';
                      break;
                    case 5:
                      dayText = '금';
                      break;
                    case 6:
                      dayText = '토';
                      break;
                    case 7:
                      dayText = '일';
                      break;
                  }
                }
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Image.network(
                        'https://openweathermap.org/img/wn/$weatherIcon@2x.png',
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.cloud, size: 40);
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$minTemp° / $maxTemp°',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 등산로 지도 섹션
  Widget _buildPathMapSection() {
    final List<dynamic> paths = _mountainData['paths'] ?? [];

    if (paths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '등산로',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // 등산로 탭
        DefaultTabController(
          length: paths.length,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                tabs: paths.map<Widget>((path) {
                  return Tab(
                    text: path['pathName'] ?? '등산로',
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: paths.map<Widget>((path) {
                    final List<dynamic> route = path['route'] ?? [];
                    final pathName = path['pathName'] ?? '등산로';
                    final pathTime = path['pathTime'] ?? '0';

                    // 경로 좌표 변환
                    final List<NLatLng> routeCoords =
                        route.map<NLatLng>((coord) {
                      return NLatLng(
                        coord['latitude'] ?? 0.0,
                        coord['longitude'] ?? 0.0,
                      );
                    }).toList();

                    return Column(
                      children: [
                        // 등산로 정보
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '소요 시간: 약 $pathTime분',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 네이버 지도
                        SizedBox(
                          height: 220,
                          child: routeCoords.isNotEmpty
                              ? NaverMap(
                                  options: NaverMapViewOptions(
                                    mapType: NMapType.basic,
                                    activeLayerGroups: [
                                      NLayerGroup.mountain,
                                      NLayerGroup.building,
                                      NLayerGroup.transit,
                                    ],
                                  ),
                                  onMapReady: (controller) async {
                                    _mapController = controller;

                                    // 경로 표시
                                    if (routeCoords.length >= 2) {
                                      // 경로 오버레이 추가
                                      controller.addOverlay(
                                        NPathOverlay(
                                          id: 'path-${path['pathId']}',
                                          coords: routeCoords,
                                          color: AppColors.primary,
                                          width: 5,
                                          outlineWidth: 1,
                                          outlineColor: Colors.white,
                                          patternInterval: 15,
                                        ),
                                      );

                                      // 시작점/도착점 마커 추가
                                      controller.addOverlay(
                                        NMarker(
                                          id: 'start-${path['pathId']}',
                                          position: routeCoords.first,
                                          caption: const NOverlayCaption(
                                            text: '시작',
                                            textSize: 12,
                                          ),
                                        ),
                                      );

                                      controller.addOverlay(
                                        NMarker(
                                          id: 'end-${path['pathId']}',
                                          position: routeCoords.last,
                                          caption: const NOverlayCaption(
                                            text: '도착',
                                            textSize: 12,
                                          ),
                                        ),
                                      );

                                      // 카메라 이동 - 경로의 경계 구하기
                                      double minLat = double.infinity;
                                      double maxLat = -double.infinity;
                                      double minLng = double.infinity;
                                      double maxLng = -double.infinity;

                                      for (var point in routeCoords) {
                                        minLat =
                                            math.min(minLat, point.latitude);
                                        maxLat =
                                            math.max(maxLat, point.latitude);
                                        minLng =
                                            math.min(minLng, point.longitude);
                                        maxLng =
                                            math.max(maxLng, point.longitude);
                                      }

                                      // 경계를 이용하여 카메라 이동
                                      controller.updateCamera(
                                        NCameraUpdate.fitBounds(
                                          NLatLngBounds(
                                            southWest: NLatLng(minLat, minLng),
                                            northEast: NLatLng(maxLat, maxLng),
                                          ),
                                          padding: const EdgeInsets.all(30),
                                        ),
                                      );
                                    }
                                  },
                                )
                              : const Center(child: Text('등산로 정보가 없습니다.')),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 상세 설명 섹션
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상세 설명',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _mountainData['description'] ?? '상세 설명이 없습니다.',
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // 난이도에 따른 색상
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

  // 이미지 URL 안전 처리 함수 추가
  String getImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://$url';
  }
}
