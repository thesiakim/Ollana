import 'package:flutter/material.dart';
import '../screens/user/login_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Ollana'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: const Text(
            'Login',
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
        ),
      ],
    );
  }
}
