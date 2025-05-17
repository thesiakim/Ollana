import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/compare_response.dart';
import '../../models/path_detail.dart';
import '../../services/my_footprint_service.dart';
import '../../utils/footprint_utils.dart';
import '../../widgets/footprint/footprint_detail_widgets.dart';
import './date_picker_modal.dart';

class FootprintDetailScreen extends StatefulWidget {
  final int footprintId;
  final String token;

  const FootprintDetailScreen({
    super.key,
    required this.footprintId,
    required this.token,
  });

  @override
  State<FootprintDetailScreen> createState() => _FootprintDetailScreenState();
}

class _FootprintDetailScreenState extends State<FootprintDetailScreen> {
  List<PathDetail> paths = [];
  String? mountainName;
  int _currentPage = 0;
  bool _isFetching = false;
  bool _hasNextPage = true;
  Map<int, Set<int>> _selectedRecordIdsByPath = {};
  Map<int, CompareResponse?> _compareDataByPath = {};
  Map<int, DateTime?> _startDatesByPath = {};
  Map<int, DateTime?> _endDatesByPath = {};
  bool _isTooltipVisible = false; // 툴팁 표시 여부를 관리하는 상태
  OverlayEntry? _overlayEntry; // 오버레이 엔트리

  @override
  void initState() {
    super.initState();
    _fetchFootprintDetail();
  }

  // dispose 메서드 추가
  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  // 툴팁 토글 함수
  void _toggleTooltip(BuildContext context) {
    setState(() {
      if (_isTooltipVisible) {
        _removeTooltip(); 
      } else {
        _showTooltip(context);
      }
    });
  }

  // 툴팁 표시 함수
  void _showTooltip(BuildContext context) {
    _removeTooltip(); // 기존 툴팁이 있다면 제거

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        right: 28, // 오른쪽에서의 거리
        bottom: 85, // 하단에서의 거리 (FAB 위에 위치하도록)
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 250,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '도움말',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '그래프의 날짜를 클릭해서\n상세 내역을 조회해보세요',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isTooltipVisible = true;
  }

  // 툴팁 제거 함수
  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isTooltipVisible = false;
  }

  Future<void> _fetchFootprintDetail({int? pathId}) async {
    if (_isFetching || (!_hasNextPage && pathId == null)) return;

    setState(() => _isFetching = true);

    try {
      final service = MyFootprintService();
      if (pathId != null) {
        final startDate = _startDatesByPath[pathId];
        final endDate = _endDatesByPath[pathId];
        final detailResponse = await service.getFootprintPathDetail(
          widget.token,
          widget.footprintId,
          pathId,
          start: startDate,
          end: endDate,
        );

        setState(() {
          final index = paths.indexWhere((p) => p.pathId == pathId);
          if (index != -1) {
            if (detailResponse.records.isNotEmpty) {
              paths[index] = PathDetail(
                pathId: pathId,
                pathName: paths[index].pathName,
                records: detailResponse.records,
                isExceed: detailResponse.isExceed,
              );
              _selectedRecordIdsByPath[pathId] = {};
              _compareDataByPath[pathId] = null;
            }
          } else if (!detailResponse.records.isEmpty) {
            paths.add(detailResponse);
          }
        });

        if (detailResponse.isExceed) {
          _showSnackBar('설정하신 기간의 등산 기록이 5개를 초과하여 최근 5개만 확인 가능합니다');
        } else if (detailResponse.records.isEmpty) {
          _showSnackBar('설정하신 기간의 등산 기록이 존재하지 않습니다');
        }
      } else {
        final detailResponse = await service.getFootprintDetail(
          widget.token,
          widget.footprintId,
          page: _currentPage,
        );

        setState(() {
          mountainName ??= detailResponse.mountainName;
          paths.addAll(detailResponse.paths);
          for (var path in detailResponse.paths) {
            _selectedRecordIdsByPath[path.pathId] ??= {};
            _compareDataByPath[path.pathId] ??= null;
            _startDatesByPath[path.pathId] ??= null;
            _endDatesByPath[path.pathId] ??= null;
          }
          _currentPage++;
          _hasNextPage = !detailResponse.last;
        });
      }
    } catch (e) {
      _showSnackBar('등산 상세 결과를 불러오지 못했습니다.');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _fetchCompareData(int pathId) async {
    final selectedRecordIds = _selectedRecordIdsByPath[pathId] ?? {};
    if (selectedRecordIds.isEmpty) {
      setState(() {
        _compareDataByPath[pathId] = null;
      });
      return;
    }

    try {
      final service = MyFootprintService();
      final compareResponse = await service.getCompareData(
        widget.token,
        widget.footprintId,
        selectedRecordIds,
      );

      setState(() {
        _compareDataByPath[pathId] = compareResponse;
      });
    } catch (e) {
      _showSnackBar('비교 데이터를 불러오지 못했습니다.');
      setState(() {
        _compareDataByPath[pathId] = null;
      });
    }
  }

  void _toggleRecordSelection(int pathId, int recordId) {
    setState(() {
      final selectedRecordIds = _selectedRecordIdsByPath[pathId] ?? {};
      if (selectedRecordIds.contains(recordId)) {
        selectedRecordIds.remove(recordId);
      } else if (selectedRecordIds.length < 2) {
        selectedRecordIds.add(recordId);
      }
      _selectedRecordIdsByPath[pathId] = selectedRecordIds;
    });
    _fetchCompareData(pathId);
  }

  Future<void> _showDatePickerModal(int pathId, bool isStartDate) async {
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => DatePickerModal(
        initialDate: isStartDate
            ? _startDatesByPath[pathId] ?? DateTime.now()
            : _endDatesByPath[pathId] ?? DateTime.now(),
      ),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDatesByPath[pathId] = selectedDate;
          if (_endDatesByPath[pathId] != null &&
              _endDatesByPath[pathId]!.isBefore(selectedDate)) {
            _endDatesByPath[pathId] = null;
          }
        } else {
          if (_startDatesByPath[pathId] == null) {
            _showSnackBar('시작일을 선택해주세요.');
            return;
          }
          if (selectedDate.isBefore(_startDatesByPath[pathId]!)) {
            _showSnackBar('종료일은 시작일 이후여야 합니다.');
            return;
          }
          _endDatesByPath[pathId] = selectedDate;
        }
      });

      if (_startDatesByPath[pathId] != null && _endDatesByPath[pathId] != null) {
        await _fetchFootprintDetail(pathId: pathId);
      }
    }
  }

  // 레전드 아이템 위젯
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // 라인 차트용 LineChartBarData 생성
  LineChartBarData _buildLineChartBarData(
    List<FlSpot> spots,
    Color color,
    double strokeWidth,
  ) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      barWidth: strokeWidth,
      color: color,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF52A486),
        title: Text(
          mountainName != null ? '$mountainName 발자취' : '발자취',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      // 물음표 아이콘을 위한 FloatingActionButton 추가
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () {
            _toggleTooltip(context);
          },
          backgroundColor: const Color(0xFF52A486),
          child: Icon(
            _isTooltipVisible ? Icons.close : Icons.help_outline,
            color: Colors.white,
          ),
          mini: true, // 좀 더 작은 크기로 설정
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('최고 심박수', Colors.red),
                const SizedBox(width: 20),
                _buildLegendItem('평균 심박수', Colors.blue),
                const SizedBox(width: 20),
                _buildLegendItem('소요 시간(분)', Colors.green),
              ],
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (!_isFetching &&
                    _hasNextPage &&
                    scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent * 0.8) {
                  _fetchFootprintDetail();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 16),
                itemCount: paths.length + (_isFetching ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= paths.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: Color(0xFF52A486),
                        ),
                      ),
                    );
                  }

                  final path = paths[index];
                  final compareData = _compareDataByPath[path.pathId];

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.route,
                                color: Color(0xFF52A486),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  path.pathName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          AspectRatio(
                            aspectRatio: 1.7,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 16.0, top: 8.0, bottom: 8.0),
                              child: LineChart(
                                LineChartData(
                                  minX: 0,
                                  maxX: path.records.isEmpty
                                      ? 0
                                      : path.records.length - 1.0,
                                  minY: 0,
                                  maxY: path.records.isEmpty
                                      ? 100
                                      : getMaxValue(path) * 1.1,
                                  lineTouchData: LineTouchData(
                                    enabled: true,
                                    touchTooltipData: LineTouchTooltipData(
                                      tooltipBgColor: Colors.white.withOpacity(0.8),
                                      tooltipRoundedRadius: 8,
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((touchedSpot) {
                                          final String title;
                                          final Color textColor;

                                          if (touchedSpot.barIndex == 0) {
                                            title =
                                                '최고 심박수: ${touchedSpot.y.toInt()}';
                                            textColor = Colors.black;
                                          } else if (touchedSpot.barIndex == 1) {
                                            title =
                                                '평균 심박수: ${touchedSpot.y.toInt()}';
                                            textColor = Colors.black;
                                          } else {
                                            title =
                                                '소요 시간: ${touchedSpot.y.toInt()}분';
                                            textColor = Colors.black;
                                          }

                                          return LineTooltipItem(
                                            title,
                                            TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                    touchCallback:
                                        (FlTouchEvent event, LineTouchResponse? touchResponse) {
                                      if (event is FlTapUpEvent &&
                                          touchResponse != null &&
                                          touchResponse.lineBarSpots != null) {
                                        final spot = touchResponse.lineBarSpots!.first;
                                        final index = spot.x.toInt();
                                        if (index >= 0 &&
                                            index < path.records.length) {
                                          final recordId =
                                              path.records[index].recordId;
                                          _toggleRecordSelection(
                                              path.pathId, recordId);
                                        }
                                      }
                                    },
                                    getTouchedSpotIndicator:
                                        (barData, spotIndexes) {
                                      return spotIndexes.map((index) {
                                        return TouchedSpotIndicatorData(
                                          FlLine(color: Colors.orange, strokeWidth: 2),
                                          FlDotData(
                                            show: true,
                                            getDotPainter:
                                                (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 6,
                                                color: Colors.orange,
                                                strokeWidth: 2,
                                                strokeColor: Colors.white,
                                              );
                                            },
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withOpacity(0.3),
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withOpacity(0.3),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 35,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 &&
                                              index < path.records.length) {
                                            final date = path.records[index].date;
                                            final recordId =
                                                path.records[index].recordId;
                                            final selectedRecordIds =
                                                _selectedRecordIdsByPath[path.pathId] ??
                                                    {};
                                            final isSelected =
                                                selectedRecordIds.contains(recordId);

                                            return GestureDetector(
                                              onTap: () {
                                                _toggleRecordSelection(
                                                    path.pathId, recordId);
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  formatDate(date),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected
                                                        ? Colors.orange
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                      axisNameWidget: const Padding(
                                        padding: EdgeInsets.only(top: 15),
                                        child: Text(
                                          '날짜',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 35,
                                        getTitlesWidget: (value, meta) {
                                          if (value == 0) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 4),
                                            child: Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.5),
                                        width: 1),
                                  ),
                                  lineBarsData: [
                                    // 최고 심박수 라인
                                    _buildLineChartBarData(
                                      path.records.isEmpty
                                          ? [FlSpot(0, 0)]
                                          : path.records.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final record = entry.value;
                                              return FlSpot(
                                                  idx.toDouble(),
                                                  record.maxHeartRate.toDouble());
                                            }).toList(),
                                      Colors.red,
                                      2.5,
                                    ),
                                    // 평균 심박수 라인
                                    _buildLineChartBarData(
                                      path.records.isEmpty
                                          ? [FlSpot(0, 0)]
                                          : path.records.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final record = entry.value;
                                              return FlSpot(
                                                  idx.toDouble(), record.averageHeartRate);
                                            }).toList(),
                                      Colors.blue,
                                      2.5,
                                    ),
                                    // 소요 시간 라인
                                    _buildLineChartBarData(
                                      path.records.isEmpty
                                          ? [FlSpot(0, 0)]
                                          : path.records.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final record = entry.value;
                                              return FlSpot(
                                                  idx.toDouble(), record.time.toDouble());
                                            }).toList(),
                                      Colors.green,
                                      2.5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF52A486),
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(120, 36),
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onPressed: () =>
                                      _showDatePickerModal(path.pathId, true),
                                  child: Text(
                                    _startDatesByPath[path.pathId] == null
                                        ? '시작일 선택'
                                        : displayDate(_startDatesByPath[path.pathId]),
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                              if (_startDatesByPath[path.pathId] != null &&
                                  _endDatesByPath[path.pathId] != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '~',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Flexible(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF52A486),
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(120, 36),
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onPressed: _startDatesByPath[path.pathId] == null
                                      ? null
                                      : () =>
                                          _showDatePickerModal(path.pathId, false),
                                  child: Text(
                                    _endDatesByPath[path.pathId] == null
                                        ? '종료일 선택'
                                        : displayDate(_endDatesByPath[path.pathId]),
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (compareData != null && compareData.records.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            buildCompareResult(compareData),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

    // 도움말 메시지를 표시하는 함수 추가
  void _showHelpMessage(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.fromLTRB(16, 0, 16, 70), // 하단에 충분한 여백을 두어 FloatingActionButton과 겹치지 않도록 설정
        backgroundColor: Colors.black.withOpacity(0.8),
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
    @override
    Path getClip(Size size) {
      final path = Path();
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
      path.close();
      return path;
    }

    @override
    bool shouldReclip(CustomClipper<Path> oldClipper) => false;
  }
