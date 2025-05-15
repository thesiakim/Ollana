// lib/screens/recommend/ai_recommendation_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../models/app_state.dart';
import '../../widgets/custom_app_bar.dart';

class AiRecommendationScreen extends StatefulWidget {
  const AiRecommendationScreen({Key? key}) : super(key: key);

  @override
  _AiRecommendationScreenState createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen> {
  bool _loading = true;
  String? _error;
  int? _cluster;
  String? _name, _desc, _imgUrl;

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  Future<void> _fetchRecommendation() async {
    final app = context.read<AppState>();
    final userId = app.userId;
    final token = app.accessToken;
    if (userId == null || token == null) {
      setState(() {
        _error = '로그인 정보가 없습니다.';
        _loading = false;
      });
      return;
    }

    final url = Uri.parse('${dotenv.get('AI_BASE_URL')}/recommend/$userId');
    try {
      final resp = await http.post(url, headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) {
        throw Exception('서버 오류 (${resp.statusCode})');
      }

      final body = jsonDecode(utf8.decode(resp.bodyBytes));
      if (body['recommendations'] == null ||
          (body['recommendations'] as List).isEmpty) {
        setState(() {
          _error = body['message'] ?? '추천된 산이 없습니다.';
          _loading = false;
        });
        return;
      }

      final rec =
          (body['recommendations'] as List).first as Map<String, dynamic>;
      setState(() {
        _cluster = body['cluster'] as int?;
        _name = rec['mountain_name'] as String?;
        _desc = rec['mountain_description'] as String?;
        _imgUrl = rec['image_url'] as String?;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '오류가 발생했습니다: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(
          child: Text(
        _error!,
        style: const TextStyle(color: Colors.red, fontSize: 16),
        textAlign: TextAlign.center,
      ));
    } else {
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_imgUrl != null)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(_imgUrl!,
                      height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(_name ?? '',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_desc ?? '',
                          style: const TextStyle(fontSize: 16, height: 1.4)),
                    ]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: SafeArea(child: content),
    );
  }
}
