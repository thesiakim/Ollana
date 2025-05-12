import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/app_state.dart';
import '../../services/my_page_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String nickname;
  final String imageUrl;

  const EditProfileScreen({
    Key? key,
    required this.nickname,
    required this.imageUrl,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nicknameController;
  late String _imageUrl;
  XFile? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.nickname);
    _imageUrl = widget.imageUrl;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
      debugPrint('Selected Image Path: ${pickedFile.path}');
    }
  }

  Future<void> _updateProfile() async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = context.read<AppState>();
      final userService = MyPageService();
      final token = appState.accessToken ?? '';
      debugPrint('Updating profile with nickname: ${_nicknameController.text}, image: ${_selectedImage?.path}');
      final updatedUser = await userService.updateUserProfile(
        token,
        _nicknameController.text.trim(),
        _selectedImage,
      );

      // 성공적으로 업데이트되면 이전 화면으로 돌아가며 결과를 전달
      Navigator.pop(context, updatedUser);
    } catch (e) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        Map<String, dynamic>? errorData;

        try {
          errorData = jsonDecode(errorMessage) as Map<String, dynamic>;
        } catch (_) {
          // JSON 파싱 실패
          errorData = null;
        }

        if (errorData != null) {
          final code = errorData['code'];
          final message = errorData['message']?.toString() ?? '알 수 없는 오류';

          if (code == 'U-002') {
            // 닉네임 중복 모달
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('닉네임 중복'),
                  content: Text(message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        } else {
          // JSON 파싱 실패 시 기본 에러 처리
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
      finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
        }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보 수정하기'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _selectedImage != null
                  ? FileImage(File(_selectedImage!.path)) as ImageProvider<Object>
                  : NetworkImage(_imageUrl) as ImageProvider<Object>,
              onBackgroundImageError: (_, __) => const AssetImage(
                  'lib/assets/images/alps.jpg'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('프로필 변경'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}