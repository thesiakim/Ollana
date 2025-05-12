import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../models/app_state.dart';
import '../../models/user.dart';
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
      // 실패 응답 처리
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.contains('이미 사용중인 닉네임입니다')) {
        errorMessage = '이미 사용 중인 닉네임입니다. 다른 닉네임을 입력해주세요.';
      } else if (errorMessage.contains('Failed to update user profile: 500')) {
        errorMessage = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
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
              child: const Text('프로필 이미지 변경'),
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