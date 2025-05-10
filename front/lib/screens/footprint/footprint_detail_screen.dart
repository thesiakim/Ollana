import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/path_detail.dart';
import '../../services/my_footprint_service.dart';
import 'dart:convert';
import '../../models/record.dart';

class CompareResponse {
  final List<CompareRecord> records;
  final CompareResult? result;

  CompareResponse({required this.records, this.result});

  factory CompareResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final records = (data['records'] as List)
        .map((e) => CompareRecord.fromJson(e))
        .toList();
    final resultJson = data['result'];
    return CompareResponse(
      records: records,
      result: resultJson != null ? CompareResult.fromJson(resultJson) : null,
    );
  }
}

class CompareRecord {
  final int recordId;
  final String date;
  final int maxHeartRate;
  final double averageHeartRate;
  final int time;

  CompareRecord({
    required this.recordId,
    required this.date,
    required this.maxHeartRate,
    required this.averageHeartRate,
    required this.time,
  });

  factory CompareRecord.fromJson(Map<String, dynamic> json) {
    return CompareRecord(
      recordId: json['recordId'],
      date: json['date'],
      maxHeartRate: json['maxHeartRate'],
      averageHeartRate: json['averageHeartRate'],
      time: json['time'],
    );
  }
}

class CompareResult {
  final String growthStatus;
  final int maxHeartRateDiff;
  final int avgHeartRateDiff;
  final int timeDiff;

  CompareResult({
    required this.growthStatus,
    required this.maxHeartRateDiff,
    required this.avgHeartRateDiff,
    required this.timeDiff,
  });

  factory CompareResult.fromJson(Map<String, dynamic> json) {
    return CompareResult(
      growthStatus: json['growthStatus'],
      maxHeartRateDiff: json['maxHeartRateDiff'],
      avgHeartRateDiff: json['avgHeartRateDiff'],
      timeDiff: json['timeDiff'],
    );
  }
}

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

  String formatDate(DateTime date) {
    final shortYear = date.year % 100;
    return '${shortYear.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  double _getMaxValue(PathDetail path) {
    double maxHeartRate = 0;
    double maxTime = 0;

    for (var record in path.records) {
      if (record.maxHeartRate > maxHeartRate) {
        maxHeartRate = record.maxHeartRate.toDouble();
      }
      if (record.time > maxTime) {
        maxTime = record.time.toDouble();
      }
    }

    return maxHeartRate > maxTime ? maxHeartRate : maxTime;
  }

  @override
  void initState() {
    super.initState();
    _fetchFootprintDetail();
  }

  Future<void> _fetchFootprintDetail() async {
    if (_isFetching || !_hasNextPage) return;

    setState(() => _isFetching = true);

    try {
      final service = MyFootprintService();
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
        }
        _currentPage++;
        _hasNextPage = !detailResponse.last;
      });
    } catch (e) {
      debugPrint('상세 조회 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등산 상세 결과를 불러오지 못했습니다.')),
      );
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _fetchCompareData(int pathId) async {
    final selectedRecordIds = _selectedRecordIdsByPath[pathId] ?? {};
    if (selectedRecordIds.isEmpty) {
      setState(() {
        _compareDataByPath[pathId] = null;
      });
      return;
    }

    final baseUrl = dotenv.get('BASE_URL');
    final recordIdsQuery = selectedRecordIds
        .map((id) => 'recordIds=$id')
        .join('&');
    final uri = Uri.parse('$baseUrl/footprint/${widget.footprintId}/compare?$recordIdsQuery');

    try {
      debugPrint('API 호출 URI: $uri');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('비교 API 응답 코드: ${res.statusCode}');
      debugPrint('비교 API 응답 본문: ${res.body}');
      final decoded = utf8.decode(res.bodyBytes);

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(decoded);
        debugPrint('비교 API 응답 데이터: ${jsonData.toString()}');
        setState(() {
          _compareDataByPath[pathId] = CompareResponse.fromJson(jsonData);
        });
      } else {
        throw Exception('비교 데이터 로드 실패: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('비교 API 호출 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비교 데이터를 불러오지 못했습니다.')),
      );
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
      debugPrint('Path $pathId selected recordIds: $selectedRecordIds');
    });
    _fetchCompareData(pathId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mountainName != null ? '$mountainName 등산 상세 결과' : '등산 상세 결과'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem('최고 심박수', Colors.red),
                const SizedBox(width: 15),
                _legendItem('평균 심박수', Colors.blue),
                const SizedBox(width: 15),
                _legendItem('소요 시간(분)', Colors.green),
              ],
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (!_isFetching &&
                    _hasNextPage &&
                    scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
                  _fetchFootprintDetail();
                }
                return false;
              },
              child: ListView.builder(
                itemCount: paths.length + (_isFetching ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= paths.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final path = paths[index];
                  final compareData = _compareDataByPath[path.pathId];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path.pathName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(right: 24.0),
                          child: SizedBox(
                            height: 250,
                            child: LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: path.records.length - 1 > 0 ? path.records.length - 1.0 : 0,
                                minY: 0,
                                maxY: _getMaxValue(path) * 1.1,
                                lineBarsData: [
                                  _line(
                                    path.records.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final record = entry.value;
                                      return FlSpot(idx.toDouble(), record.maxHeartRate.toDouble());
                                    }).toList(),
                                    Colors.red,
                                    '최고 심박수',
                                    path.records,
                                    path.pathId,
                                  ),
                                  _line(
                                    path.records.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final record = entry.value;
                                      return FlSpot(idx.toDouble(), record.averageHeartRate);
                                    }).toList(),
                                    Colors.blue,
                                    '평균 심박수',
                                    path.records,
                                    path.pathId,
                                  ),
                                  _line(
                                    path.records.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final record = entry.value;
                                      return FlSpot(idx.toDouble(), record.time.toDouble());
                                    }).toList(),
                                    Colors.green,
                                    '소요 시간',
                                    path.records,
                                    path.pathId,
                                  ),
                                ],
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 35,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < path.records.length) {
                                          final date = path.records[index].date;
                                          final recordId = path.records[index].recordId;
                                          final selectedRecordIds = _selectedRecordIdsByPath[path.pathId] ?? {};
                                          final isSelected = selectedRecordIds.contains(recordId);
                                          return GestureDetector(
                                            onTap: () {
                                              debugPrint('Tapped date: ${formatDate(date)}, recordId: $recordId, pathId: ${path.pathId}');
                                              _toggleRecordSelection(path.pathId, recordId);
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                formatDate(date),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? Colors.orange : Colors.black,
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
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                    axisNameWidget: const Padding(
                                      padding: EdgeInsets.only(bottom: 10),
                                      child: Text(
                                        '심박수/시간',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: const FlGridData(show: true),
                                borderData: FlBorderData(show: true),
                                lineTouchData: LineTouchData(
                                  enabled: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((touchedSpot) {
                                        final String title;
                                        final Color textColor;

                                        if (touchedSpot.barIndex == 0) {
                                          title = '최고 심박수: ${touchedSpot.y.toInt()}';
                                          textColor = Colors.red;
                                        } else if (touchedSpot.barIndex == 1) {
                                          title = '평균 심박수: ${touchedSpot.y.toInt()}';
                                          textColor = Colors.blue;
                                        } else {
                                          title = '소요 시간: ${touchedSpot.y.toInt()}분';
                                          textColor = Colors.green;
                                        }

                                        return LineTooltipItem(
                                          title,
                                          TextStyle(color: textColor, fontWeight: FontWeight.bold),
                                        );
                                      }).toList();
                                    },
                                  ),
                                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                                    debugPrint('Touch event: $event, Response: $touchResponse');
                                    if (event is FlTapUpEvent && touchResponse != null && touchResponse.lineBarSpots != null) {
                                      final spot = touchResponse.lineBarSpots!.first;
                                      final index = spot.x.toInt();
                                      debugPrint('Tapped spot: index=$index, x=${spot.x}, y=${spot.y}, pathId: ${path.pathId}');
                                      if (index >= 0 && index < path.records.length) {
                                        final recordId = path.records[index].recordId;
                                        debugPrint('Selected recordId: $recordId');
                                        _toggleRecordSelection(path.pathId, recordId);
                                      }
                                    }
                                  },
                                  getTouchedSpotIndicator: (barData, spotIndexes) {
                                    return spotIndexes.map((index) {
                                      return TouchedSpotIndicatorData(
                                        FlLine(color: Colors.orange, strokeWidth: 2),
                                        FlDotData(
                                          show: true,
                                          getDotPainter: (spot, percent, barData, index) {
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
                              ),
                            ),
                          ),
                        ),
                        if (compareData != null && compareData.records.isNotEmpty)
                          _buildCompareResult(compareData),
                      ],
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

  Widget _buildCompareResult(CompareResponse compareData) {
    final records = compareData.records;
    final result = compareData.result;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: records.map((record) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${record.date}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text('최고 심박수: ${record.maxHeartRate} bpm'),
                          Text('평균 심박수: ${record.averageHeartRate.toStringAsFixed(1)} bpm'),
                          Text('소요 시간: ${record.time} 분'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (result != null) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '비교 결과',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '성장 상태: ${_formatGrowthStatus(result.growthStatus)}',
                      style: TextStyle(
                        color: result.growthStatus == 'IMPROVING' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('최고 심박수 변화:'),
                    Text(
                      '${result.maxHeartRateDiff > 0 ? '+' : ''}${result.maxHeartRateDiff} bpm',
                      style: TextStyle(
                        color: result.maxHeartRateDiff <= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('소요 시간 변화:'),
                    Text(
                      '${result.timeDiff > 0 ? '+' : ''}${result.timeDiff} 분',
                      style: TextStyle(
                        color: result.timeDiff <= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatGrowthStatus(String status) {
    switch (status) {
      case 'IMPROVING':
        return '향상';
      case 'DECLINING':
        return '악화';
      default:
        return status;
    }
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color, String label, List<Record> records, int pathId) {
    final selectedRecordIds = _selectedRecordIdsByPath[pathId] ?? {};
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          final recordId = records[index].recordId;
          return FlDotCirclePainter(
            radius: selectedRecordIds.contains(recordId) ? 6 : 4,
            color: selectedRecordIds.contains(recordId) ? Colors.orange : color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      color: color,
      barWidth: 2,
      belowBarData: BarAreaData(
        show: true,
        color: color.withAlpha(25),
      ),
    );
  }
}