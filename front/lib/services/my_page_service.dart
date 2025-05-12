import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/user.dart'; 

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
}