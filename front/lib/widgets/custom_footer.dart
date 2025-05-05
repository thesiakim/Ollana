// custom_footer.dart: 앱 하단의 네비게이션 바 위젯 구현
// - 홈, 검색, 프로필 등의 주요 페이지로 이동할 수 있는 탭 구성
// - 현재 선택된 탭을 색상으로 강조 표시
// - AppState를 통해 페이지 전환 상태 관리
// - 앱의 주요 화면 간 이동을 제공하는 네비게이션 컴포넌트

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/mountain_service.dart';
import 'package:geolocator/geolocator.dart';

class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 45 + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFooterButton(context, 0, Icons.home),
              _buildFooterButton(context, 1, Icons.approval_rounded),
              _buildFooterButton(context, 2, Icons.area_chart_rounded),
              _buildFooterButton(context, 3, FontAwesomeIcons.shoePrints),
              _buildFooterButton(context, 4, Icons.person),
            ],
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  // 위치 권한 확인 및 요청
  Future<bool> _handleLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 활성화되어 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;
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
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 거부되었습니다.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return false;
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
  Future<Position?> _getCurrentPosition(BuildContext context) async {
    final hasPermission = await _handleLocationPermission(context);
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('현재 위치를 가져오는데 실패했습니다: $e')),
      );
      return null;
    }
  }

  Widget _buildFooterButton(
    BuildContext context,
    int index,
    IconData icon,
  ) {
    final appState = context.watch<AppState>();
    final isSelected = appState.currentPageIndex == index;

    // 발자취 아이콘(shoePrints)인 경우에만 회전 적용
    Widget iconWidget = icon == FontAwesomeIcons.shoePrints
        ? Transform.rotate(
            angle: -1.7, // 약 28.6도 회전 (라디안 단위)
            child: Icon(
              icon,
              color: isSelected ? Colors.green : Colors.grey,
              size: 20.0, // 발자국 아이콘 크기 키움
            ),
          )
        : Icon(
            icon,
            color: isSelected ? Colors.green : Colors.grey,
            size: 24.0, // 다른 아이콘 일관된 크기 설정
          );

    return GestureDetector(
      onTap: () async {
        // 컨텍스트를 로컬 변수에 저장
        final currentContext = context;

        // 트래킹 탭(인덱스 1)을 클릭했을 때
        if (index == 1) {
          // 현재 트래킹 중인지 확인
          if (appState.isTracking ||
              appState.trackingStage == TrackingStage.tracking) {
            // 이미 트래킹 중이면 API 호출 없이 페이지 전환
            appState.changePage(index);
            return;
          }

          // 먼저 페이지 전환
          appState.changePage(index);

          // 데이터 로딩은 화면 전환 후에 백그라운드로 처리
          _loadMountainDataInBackground(currentContext, appState);
        } else {
          // 다른 탭의 경우 그냥 페이지 전환
          appState.changePage(index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
        ],
      ),
    );
  }

  // 백그라운드에서 산 데이터 로딩
  void _loadMountainDataInBackground(
      BuildContext context, AppState appState) async {
    try {
      // 현재 위치 가져오기
      final position = await _getCurrentPosition(context);
      if (position == null) {
        // 위치를 가져오지 못했을 경우 서울 중심부 좌표로 주변 산 정보 가져오기
        if (!context.mounted) return;

        final mountainService = MountainService();
        // 서울 중심부 좌표 (37.5665, 126.9780)
        final data =
            await mountainService.getNearbyMountains(37.5665, 126.9780);

        if (!context.mounted) return;

        final mountain = data.mountain;
        final routes = data.routes;

        if (routes.isNotEmpty) {
          // 앱 상태에 산과 첫 번째 등산로 정보 저장
          appState.selectMountain(mountain.name);
          appState.preSelectRoute(routes[0]);
        }
      } else {
        // 현재 위치 기반으로 주변 산 정보 가져오기
        final mountainService = MountainService();
        final data = await mountainService.getNearbyMountains(
            position.latitude, position.longitude);

        if (!context.mounted) return;

        final mountain = data.mountain;
        final routes = data.routes;

        if (routes.isNotEmpty) {
          // 앱 상태에 산과 첫 번째 등산로 정보 저장
          appState.selectMountain(mountain.name);
          appState.preSelectRoute(routes[0]);
        }
      }
    } catch (e) {
      // 오류 발생 시 처리 - mounted 체크 추가
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('산 데이터를 불러오는데 실패했습니다: $e')),
      );
    }
  }
}
