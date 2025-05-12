import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.nickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // TODO: 닉네임 및 이미지 업데이트 로직 (예: API 호출)
              Navigator.pop(context);
            },
            child: const Text('저장'),
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
              backgroundImage: NetworkImage(widget.imageUrl),
              onBackgroundImageError: (_, __) => const AssetImage(
                  'lib/assets/images/alps.jpg'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // TODO: 이미지 업로드 기능 추가 가능
            ElevatedButton(
              onPressed: () {
                // TODO: 이미지 업로드 및 변경 로직
              },
              child: const Text('프로필 이미지 변경'),
            ),
          ],
        ),
      ),
    );
  }
}