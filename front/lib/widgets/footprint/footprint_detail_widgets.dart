import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/compare_response.dart';
import '../../models/record.dart';
import '../../utils/footprint_utils.dart';

Widget buildCompareResult(CompareResponse compareData) {
  final records = compareData.records;
  final result = compareData.result;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      const Divider(thickness: 1),
      Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: records.map((record) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF52A486),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        record.date,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildMetricCard(
                          '',
                          '${record.maxHeartRate}',
                          'bpm',
                          Colors.red[100]!,
                          Colors.red[700]!,
                          Icons.favorite,
                        ),
                        buildMetricCard(
                          '',
                          '${record.averageHeartRate.toStringAsFixed(1)}',
                          'bpm',
                          Colors.blue[100]!,
                          Colors.blue[700]!,
                          Icons.monitor_heart_outlined,
                        ),
                        buildMetricCard(
                          '',
                          '${record.time}',
                          '분',
                          Colors.green[100]!,
                          Colors.green[700]!,
                          Icons.timer,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      if (result != null) ...[
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                result.growthStatus == 'IMPROVING' ? Icons.emoji_events : Icons.trending_down,
                                size: 18,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formatGrowthStatus(result.growthStatus),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextSpan(
                        text: '',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: result.growthStatus == 'IMPROVING' ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                buildComparisonItemCute('최고 심박수', result.maxHeartRateDiff, 'bpm', result.maxHeartRateDiff <= 0, Icons.favorite),
                const SizedBox(height: 16),
                buildComparisonItemCute('평균 심박수', result.avgHeartRateDiff, 'bpm', result.avgHeartRateDiff <= 0, Icons.monitor_heart_outlined),
                const SizedBox(height: 16),
                buildComparisonItemCute('소요 시간', result.timeDiff, '분', result.timeDiff <= 0, Icons.timer),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      const Divider(thickness: 1),
    ],
  );
}

Widget buildMetricCard(String label, String value, String unit, Color bgColor, Color textColor, IconData icon) {
  return Container(
    width: 100,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 3,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: textColor, size: 22),
        const SizedBox(height: 8),
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget buildComparisonItemCute(String label, int diff, String unit, bool isPositive, IconData icon) {
  final sign = diff > 0 ? '+' : '';

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isPositive ? Colors.green[50] : Colors.red[50],
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isPositive ? Colors.green[600] : Colors.red[600],
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '이전 기록 대비',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                color: isPositive ? Colors.green[700] : Colors.red[700],
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$sign$diff $unit',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget legendItem(String label, Color color) {
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

LineChartBarData line(
  List<FlSpot> spots,
  Color color,
  String label,
  List<Record> records,
  int pathId,
  Map<int, Set<int>> selectedRecordIdsByPath,
) {
  final selectedRecordIds = selectedRecordIdsByPath[pathId] ?? {};
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