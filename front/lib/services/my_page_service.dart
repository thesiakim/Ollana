import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../models/user.dart';
import 'package:http_parser/http_parser.dart'; // 꼭 필요

class MyPageService {
  final String baseUrl = dotenv.get('BASE_URL');

  Future<User> fetchUserDetails(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/mypage'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        return User.fromJson(jsonData['data']);
      } else {
        throw Exception('API returned status false');
      }
    } else {
      throw Exception('Failed to load user details: ${response.statusCode}');
    }
  }

  Future<User> updateUserProfile(String token, String nickname, XFile? profileImage) async {
    try {
      final uri = Uri.parse('$baseUrl/user/mypage');
      
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // userData를 MultipartFile처럼 추가
      final userData = jsonEncode({"nickname": nickname});
      request.files.add(http.MultipartFile.fromString(
        'userData',
        userData,
        contentType: MediaType('application', 'json'),
      ));

      // 프로필 이미지 추가 (선택)
      if (profileImage != null) {
        final file = await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          contentType: MediaType('image', 'jpeg'), // png인 경우는 image/png
        );
        request.files.add(file);
      }
      
      // 요청 상세 로깅
      debugPrint('=============== REQUEST DETAILS ===============');
      debugPrint('URL: $uri');
      debugPrint('Method: PATCH');
      debugPrint('Headers: ${request.headers}');
      for (var field in request.fields.entries) {
        debugPrint('Field: ${field.key} = ${field.value}');
      }
      for (var file in request.files) {
        debugPrint('File: ${file.field} = ${file.filename} (${file.length} bytes)');
      }
      
      // 요청 전송
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // 응답 로깅
      debugPrint('=============== RESPONSE DETAILS ===============');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == true) {
          return User.fromJson(jsonData['data']);
        } else {
          throw Exception('API failed: ${jsonData['message']} (code: ${jsonData['code']})');
        }
      } else {
        final decodedBody = utf8.decode(response.bodyBytes); 
        throw Exception(decodedBody); 
      }
    } catch (e) {
      debugPrint('========= ERROR =========');
      debugPrint('$e');
      rethrow;
    }
  }

  Future<void> changePassword(String token, String currentPassword, String newPassword) async {
  // API 호출 로직
  // 예: await http.post(...)
  // 성공 시 아무것도 반환하지 않거나, 실패 시 예외 throw
}
}