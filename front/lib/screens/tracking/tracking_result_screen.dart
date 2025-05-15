import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../utils/app_colors.dart';

class TrackingResultScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;
  final String? selectedMode;

  const TrackingResultScreen({
    super.key,
    required this.resultData,
    this.selectedMode,
  });

  @override
  State<TrackingResultScreen> createState() => _TrackingResultScreenState();
}

class _TrackingResultScreenState extends State<TrackingResultScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // 위젯에서 전달된 모드를 우선 사용하고, 없으면 AppState에서 가져옴
    final selectedMode = widget.selectedMode ?? appState.selectedMode;
    final isVsMode = selectedMode == '나 vs 나' || selectedMode == '나 vs 친구';

    // 디버깅을 위한 로그 추가
    debugPrint('TrackingResultScreen - 선택된 모드: $selectedMode');
    debugPrint('TrackingResultScreen - 결과 데이터: ${widget.resultData}');

    // 등산 결과 화면 렌더링
    return Scaffold(
      appBar: AppBar(
        title: Text('등산 결과', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildResultContent(selectedMode),
            ),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(String? selectedMode) {
    // 어떤 모드인지에 따라 다른 결과 화면 표시
    // 디버깅 로그 추가
    debugPrint('_buildResultContent - 모드: $selectedMode');

    if (selectedMode == '나 vs 나') {
      debugPrint('나 vs 나 결과 화면 빌드');
      return _buildVsMeResult();
    } else if (selectedMode == '나 vs 친구') {
      debugPrint('나 vs 친구 결과 화면 빌드');
      return _buildVsFriendResult();
    } else {
      debugPrint('일반 등산 결과 화면 빌드');
      return _buildGeneralResult();
    }
  }

  // 나 vs 나 모드 결과 화면
  Widget _buildVsMeResult() {
    final timeDiff = widget.resultData['timeDiff'];
    final String timeDiffText = timeDiff != null
        ? timeDiff < 0
            ? "${timeDiff.abs()}분 단축"
            : "$timeDiff분 증가"
        : "";

    // badge URL 가져오기
    final String badgeUrl = widget.resultData['badge'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'XX산 등반 결과',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          // 결과 요약 카드
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '나 vs 나',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),

                  // 이전 기록과 현재 기록 비교
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 이전 기록 부분
                      Column(
                        children: [
                          Text('이전 기록',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Container(
                            width: 120,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text('25.04.21',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700])),
                                SizedBox(height: 8),
                                Text('2h 22m',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.favorite,
                                        color: Colors.red, size: 16),
                                    SizedBox(width: 4),
                                    Text('최고 심박수',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                Text('158bpm',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.favorite_border,
                                        color: Colors.red, size: 16),
                                    SizedBox(width: 4),
                                    Text('평균 심박수',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                Text('121bpm',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // vs 구분선
                      Column(
                        children: [
                          Text('VS'),
                          SizedBox(height: 60),
                        ],
                      ),

                      // 현재 기록 부분
                      Column(
                        children: [
                          Text('오늘 기록',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Container(
                            width: 120,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text('25.04.28',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700])),
                                SizedBox(height: 8),
                                Text('2h 10m',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.favorite,
                                        color: Colors.red, size: 16),
                                    SizedBox(width: 4),
                                    Text('최고 심박수',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                Text(
                                    '${widget.resultData['maxHeartRate'] ?? 160}bpm',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.favorite_border,
                                        color: Colors.red, size: 16),
                                    SizedBox(width: 4),
                                    Text('평균 심박수',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                Text(
                                    '${widget.resultData['averageHeartRate'] ?? 118}bpm',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // 뱃지 이미지 표시
                  if (badgeUrl.isNotEmpty)
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Image.network(
                        badgeUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('이미지를 불러올 수 없습니다',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Icon(Icons.emoji_events, size: 100, color: Colors.amber),

                  SizedBox(height: 16),

                  // 시간 차이 메시지
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: timeDiff != null && timeDiff < 0
                          ? Colors.green[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '시간 $timeDiffText',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: timeDiff != null && timeDiff < 0
                            ? Colors.green[800]
                            : Colors.red[800],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // 등산 코멘트
                  Card(
                    color: Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[700]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '시간 12분 단축! 최고 심박수 2bpm 증가, 평균 심박수 3bpm 감소',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
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

  // 나 vs 친구 모드 결과 화면
  Widget _buildVsFriendResult() {
    final timeDiff = widget.resultData['timeDiff'];
    final String timeDiffText = timeDiff != null
        ? timeDiff < 0
            ? "${timeDiff.abs()}분 단축"
            : "$timeDiff분 증가"
        : "";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'XX산 등반 결과',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          // 결과 요약 카드
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '나 vs 친구',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),

                  // 캐릭터와 데이터 비교
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('내 기록',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: widget.resultData['badge'] != null
                                  ? Image.network(
                                      widget.resultData['badge'],
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                              Icons.person,
                                              size: 80,
                                              color: Colors.blue),
                                    )
                                  : Icon(Icons.person,
                                      size: 80, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),

                      // vs 구분선
                      Column(
                        children: [
                          Text('VS'),
                          SizedBox(height: 60),
                        ],
                      ),

                      // 친구 결과
                      Column(
                        children: [
                          Text('친구 기록',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Icon(Icons.person,
                                  size: 80, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // 결과 비교 데이터
                  Card(
                    color: Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // 시간 차이
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('시간 차이:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                timeDiffText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: timeDiff != null && timeDiff < 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),

                          Divider(height: 16),

                          // 심박수 정보
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('최고 심박수:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  '${widget.resultData['maxHeartRate'] ?? 0} bpm'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('평균 심박수:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  '${widget.resultData['averageHeartRate'] ?? 0} bpm'),
                            ],
                          ),
                        ],
                      ),
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

  // 일반 등산 모드 결과 화면
  Widget _buildGeneralResult() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'XX산 등반 결과',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          // 결과 요약 카드
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '등산 완료!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),

                  // 등산 결과
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.terrain, size: 80, color: Colors.green),
                        SizedBox(height: 8),
                        Text(
                          '총 등산 시간',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '2h 22m',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // 결과 데이터
                  Card(
                    color: Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // 심박수 정보
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('최고 심박수:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  '${widget.resultData['maxHeartRate'] ?? 0} bpm'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('평균 심박수:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  '${widget.resultData['averageHeartRate'] ?? 0} bpm'),
                            ],
                          ),

                          Divider(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('이동 거리:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('11.2 km'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('평균 속도:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('5.2 km/h'),
                            ],
                          ),
                        ],
                      ),
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

  // 확인 버튼
  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          // 홈 화면으로 이동
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '확인',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
