import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importa desde lib/screens/
import 'screens/chat_login_screen.dart';
import 'screens/client_panel_screen.dart';

Future<void> openClientPanelWithAuth(BuildContext context) async {
  final sp = await SharedPreferences.getInstance();
  final token = sp.getString('auth_token') ?? '';

  if (token.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientPanelScreen()),
    );
    return;
  }

  // 👉 usa LoginScreen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatLoginScreen(
        afterLogin: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ClientPanelScreen()),
          );
        },
      ),
    ),
  );
}
