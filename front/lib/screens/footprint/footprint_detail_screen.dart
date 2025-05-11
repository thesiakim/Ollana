import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/path_detail.dart';
import '../../services/my_footprint_service.dart';
import 'dart:convert';
import '../../models/record.dart';
import './date_picker_modal.dart';

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
  Map<int, DateTime?> _startDatesByPath = {};
  Map<int, DateTime?> _endDatesByPath = {};

  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String displayDate(DateTime? date) {
    return date != null ? formatDate(date) : '날짜 선택';
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

  Future<void> _fetchFootprintDetail({int? pathId}) async {
    if (_isFetching || (!_hasNextPage && pathId == null)) return;

    debugPrint('Fetching footprint detail for pathId: $pathId');
    setState(() => _isFetching = true);

    try {
      final service = MyFootprintService();
      if (pathId != null) {
        debugPrint('Fetching path detail for pathId: $pathId');
        final startDate = _startDatesByPath[pathId];
        final endDate = _endDatesByPath[pathId];
        final detailResponse = await service.getFootprintPathDetail(
          widget.token,
          widget.footprintId,
          pathId,
          start: startDate != null ? formatDate(startDate) : null,
          end: endDate != null ? formatDate(endDate) : null,
        );

        setState(() {
          final index = paths.indexWhere((p) => p.pathId == pathId);
          if (index != -1) {
            debugPrint('Updating path at index: $index, isExceed: ${detailResponse.isExceed}, records: ${detailResponse.records.length}');
            if (detailResponse.records.isEmpty) {
              // records가 비어 있으면 기존 records 유지
              debugPrint('Empty records, keeping existing records');
            } else {
              // records가 있으면 업데이트
              paths[index] = PathDetail(
                pathId: pathId,
                pathName: paths[index].pathName,
                records: detailResponse.records,
                isExceed: detailResponse.isExceed,
              );
              _selectedRecordIdsByPath[pathId] = {};
              _compareDataByPath[pathId] = null;
            }
          } else {
            debugPrint('Path with pathId $pathId not found, adding new path, isExceed: ${detailResponse.isExceed}, records: ${detailResponse.records.length}');
            if (!detailResponse.records.isEmpty) {
              paths.add(detailResponse);
            }
          }
        });

        // isExceed가 true인 경우
        if (detailResponse.isExceed) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              key: Key('isExceed_$pathId'),
              content: Text('설정하신 기간의 등산 기록이 5개를 초과하여 최근 5개만 확인 가능합니다'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        // records가 비어 있는 경우
        else if (detailResponse.records.isEmpty) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              key: Key('emptyRecords_$pathId'),
              content: Text('설정하신 기간의 등산 기록이 존재하지 않습니다'),
              duration: Duration(seconds: 3),
            ),
          );
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
          debugPrint('Fetched paths: ${paths.length}');
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
      debugPrint('상세 조회 에러: $e');
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
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
          // 종료일이 시작일보다 빠르면 초기화
          if (_endDatesByPath[pathId] != null &&
              _endDatesByPath[pathId]!.isBefore(selectedDate)) {
            _endDatesByPath[pathId] = null;
          }
        } else {
          if (_startDatesByPath[pathId] == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('시작일을 선택해주세요.')),
            );
            return;
          }
          if (selectedDate.isBefore(_startDatesByPath[pathId]!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('종료일은 시작일 이후여야 합니다.')),
            );
            return;
          }
          _endDatesByPath[pathId] = selectedDate;
        }
      });

      // 시작일과 종료일이 모두 선택된 경우에만 API 호출
      if (_startDatesByPath[pathId] != null && _endDatesByPath[pathId] != null) {
        await _fetchFootprintDetail(pathId: pathId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // SnackBar로 인한 레이아웃 이동 방지
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
                      mainAxisSize: MainAxisSize.min,
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
                                maxX: path.records.isEmpty ? 0 : path.records.length - 1.0,
                                minY: 0,
                                maxY: path.records.isEmpty ? 100 : _getMaxValue(path) * 1.1,
                                lineBarsData: [
                                  _line(
                                    path.records.isEmpty
                                        ? [FlSpot(0, 0)] // 빈 데이터일 때 기본 점
                                        : path.records.asMap().entries.map((entry) {
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
                                    path.records.isEmpty
                                        ? [FlSpot(0, 0)]
                                        : path.records.asMap().entries.map((entry) {
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
                                    path.records.isEmpty
                                        ? [FlSpot(0, 0)]
                                        : path.records.asMap().entries.map((entry) {
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
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _showDatePickerModal(path.pathId, true),
                              child: Text('시작일 ${displayDate(_startDatesByPath[path.pathId])}'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _startDatesByPath[path.pathId] == null
                                  ? null
                                  : () => _showDatePickerModal(path.pathId, false),
                              child: Text('종료일 ${displayDate(_endDatesByPath[path.pathId])}'),
                            ),
                          ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
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
            ),
          ),
        ),
        if (result != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        Text('평균 심박수 변화:'),
                        Text(
                          '${result.avgHeartRateDiff > 0 ? '+' : ''}${result.avgHeartRateDiff} bpm',
                          style: TextStyle(
                            color: result.avgHeartRateDiff <= 0 ? Colors.green : Colors.red,
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
                ),
              ),
            ),
          ),
        ],
      ],
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