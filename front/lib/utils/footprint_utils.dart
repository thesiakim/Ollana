import '../../models/path_detail.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return '${date.year % 100}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

String formatDateForApi(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// String displayDate(DateTime? date) {
//   return date != null ? formatDateForApi(date) : '선택';
// }

String displayDate(DateTime? date) {
  if (date == null) return '선택';
  return DateFormat('yyyy-MM-dd').format(date);
}

double getMaxValue(PathDetail path) {
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

String formatGrowthStatus(String status) {
  switch (status) {
    case 'IMPROVING':
      return '기록이 성장했어요!';
    case 'DECLINING':
      return '기록이 부진해요!';
    case 'STABLE':
      return '기록이 비슷해요!';
    default:
      return status;
  }
}