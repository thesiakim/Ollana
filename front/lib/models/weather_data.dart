// models/weather_data.dart
import 'package:intl/intl.dart';

class WeatherData {
  final String time;
  final double score;
  final Map<String, String> details;

  WeatherData({
    required this.time,
    required this.score,
    required this.details,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    Map<String, String> details = {};
    json.forEach((key, value) {
      if (key != 'time' && key != 'score') {
        details[key] = value.toString();
      }
    });

    return WeatherData(
      time: json['time'],
      score: json['score']?.toDouble() ?? 0.0,
      details: details,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'time': time,
      'score': score,
    };
    json.addAll(details);
    return json;
  }

  // 시간 형식 변환 (2025-05-19 18:00 -> 18:00)
  String getFormattedTime() {
    final dateTime = DateFormat('yyyy-MM-dd HH:mm').parse(time);
    return DateFormat('HH:mm').format(dateTime);
  }

  // 날짜만 추출 (2025-05-19 18:00 -> 2025-05-19)
  String getFormattedDate() {
    final dateTime = DateFormat('yyyy-MM-dd HH:mm').parse(time);
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  // 날짜와 시간 객체로 변환
  DateTime getDateTime() {
    return DateFormat('yyyy-MM-dd HH:mm').parse(time);
  }

  // 현재 또는 미래 시간인지 확인
  bool isFutureOrCurrent() {
    final now = DateTime.now();
    final dataTime = getDateTime();
    return dataTime.isAfter(now) || isSameHour(dataTime, now);
  }

  // 같은 시간대인지 확인 (시, 분 비교)
  bool isSameHour(DateTime a, DateTime b) {
    return a.year == b.year && 
           a.month == b.month && 
           a.day == b.day && 
           a.hour == b.hour;
  }
}