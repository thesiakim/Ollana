import 'dart:convert';
import 'package:flutter/foundation.dart';

void printFullBody(String body) {
  const int chunkSize = 800;
  for (var i = 0; i < body.length; i += chunkSize) {
    final end = (i + chunkSize < body.length) ? i + chunkSize : body.length;
    debugPrint(body.substring(i, end));
  }
}

Map<String, dynamic> parseJson(String body) {
  debugPrint('🔧 [parseJson] isolate 파싱 시작');
  final result = jsonDecode(body);
  debugPrint('🔧 [parseJson] isolate 파싱 완료');
  return result;
}

String? formatImageUrl(String? rawImg) {
  if (rawImg == null || rawImg.isEmpty) return null;
  return (rawImg.startsWith('http://') || rawImg.startsWith('https://')) 
      ? rawImg 
      : 'https://$rawImg';
}