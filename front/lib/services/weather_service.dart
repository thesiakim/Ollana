// services/weather_service.dart 수정
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/weather_data.dart';

class WeatherService {
  static const String CACHE_KEY_DATA = 'weather_data';
  static const String CACHE_KEY_DATE = 'weather_date';

  // 날씨 데이터 가져오기 - token을 nullable로 변경
  static Future<List<WeatherData>> fetchWeatherData(String? token, {bool forceRefresh = false}) async {
    // token이 null인 경우 빈 리스트 반환
    if (token == null) {
      return [];
    }

    // 현재 날짜 확인
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    
    // SharedPreferences 인스턴스 가져오기
    final prefs = await SharedPreferences.getInstance();
    
    // // 캐시된 데이터가 있고 강제 새로고침이 아닌 경우 확인
    // if (!forceRefresh) {
    //   final cachedDataStr = prefs.getString(CACHE_KEY_DATA);
    //   final cachedDateStr = prefs.getString(CACHE_KEY_DATE);
      
    //   // 오늘 날짜의 캐시된 데이터가 있는지 확인
    //   if (cachedDataStr != null && cachedDateStr == today) {
    //     // 캐시된 데이터 파싱
    //     final List<dynamic> cachedData = json.decode(cachedDataStr);
    //     List<WeatherData> weatherDataList = cachedData
    //         .map((data) => WeatherData.fromJson(data))
    //         .toList();
        
    //     // 현재 시간 이후의 데이터만 필터링
    //     weatherDataList = _filterFutureData(weatherDataList);
        
    //     // 데이터가 있으면 반환
    //     if (weatherDataList.isNotEmpty) {
    //       return weatherDataList;
    //     }
    //   }
    // }
    
    // 캐시된 데이터가 없거나 오늘 날짜가 아니면 API 호출
    final baseUrl = dotenv.env['AI_BASE_URL']!;
    final url = Uri.parse('$baseUrl/weather');
    
    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        // 응답 바이트를 utf8로 디코딩 처리
        final decodedResponse = utf8.decode(resp.bodyBytes);
        final data = json.decode(decodedResponse);
        final weatherList = data['today_weather'] as List<dynamic>;
        
        debugPrint('등산지수 조회 (디코딩 처리): $weatherList');
        
        // 날씨 데이터 파싱
        List<WeatherData> weatherDataList = weatherList
            .map((item) => WeatherData.fromJson(item))
            .toList();
        
        // 현재 시간 이후의 데이터만 필터링
        weatherDataList = _filterFutureData(weatherDataList);
        
        // 디코딩된 데이터 캐싱
        await prefs.setString(CACHE_KEY_DATA, decodedResponse); 
        await prefs.setString(CACHE_KEY_DATE, today);
        
        return weatherDataList;
      }
      
      // 오류 발생 시 빈 리스트 반환
      return [];
    } catch (e) {
      debugPrint('날씨 데이터 가져오기 오류: $e');
      return [];
    }
  }

  // 현재 시간 이후의 데이터만 필터링하는 함수
  static List<WeatherData> _filterFutureData(List<WeatherData> dataList) {
    return dataList.where((data) => data.isFutureOrCurrent()).toList();
  }

  // 캐시 삭제 함수
  static Future<void> clearCache() async {
    debugPrint('캐시 삭제');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(CACHE_KEY_DATA);
    await prefs.remove(CACHE_KEY_DATE);
  }

  // 캐싱된 데이터 확인 함수
  static Future<void> checkCachedData() async {
    // SharedPreferences 인스턴스 가져오기
    final prefs = await SharedPreferences.getInstance();
    
    // 캐시된 데이터와 날짜 가져오기
    final cachedDataStr = prefs.getString(CACHE_KEY_DATA);
    final cachedDateStr = prefs.getString(CACHE_KEY_DATE);
    
    if (cachedDataStr != null && cachedDateStr != null) {
      try {
        // 캐시된 데이터 파싱 - JSON 구조 확인
        final decodedData = json.decode(cachedDataStr);
        List<WeatherData> weatherDataList = [];
        
        // Map인 경우와 List인 경우 모두 처리
        if (decodedData is Map<String, dynamic> && decodedData.containsKey('today_weather')) {
          // Map에서 today_weather 키의 리스트 추출
          final weatherList = decodedData['today_weather'] as List<dynamic>;
          weatherDataList = weatherList
              .map((data) => WeatherData.fromJson(data))
              .toList();
        } else if (decodedData is List<dynamic>) {
          // 직접 리스트인 경우
          weatherDataList = decodedData
              .map((data) => WeatherData.fromJson(data))
              .toList();
        } else {
          debugPrint('캐시된 데이터 형식이 예상과 다릅니다: ${decodedData.runtimeType}');
        }
        
        // 현재 시간 이후의 데이터만 필터링
        weatherDataList = _filterFutureData(weatherDataList);
        
        // 디버그 출력 - 세부 데이터 포함
        debugPrint('캐시된 날짜: $cachedDateStr');
        debugPrint('캐시된 데이터:');
        for (var data in weatherDataList) {
          debugPrint('  시간: ${data.getFormattedTime()}');
          debugPrint('  등산지수: ${data.score}');
          debugPrint('  세부정보: ${data.details}');
        }
      } catch (e) {
        debugPrint('캐시된 데이터 파싱 오류: $e');
      }
    } else {
      debugPrint('캐시된 데이터가 없습니다.');
    }
  }
}