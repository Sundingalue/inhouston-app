// lib/screens/chat_login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const String kApiBase = 'https://multi-bot-inteligente-v1.onrender.com/api/mobile';

class ChatLoginScreen extends StatefulWidget {
  final VoidCallback? afterLogin; // callback al completar login del Chat
  const ChatLoginScreen({super.key, this.afterLogin});

  @override
  State<ChatLoginScreen> createState() => _ChatLoginScreenState();
}

class _ChatLoginScreenState extends State<ChatLoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text;
    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = 'Completa usuario y contraseña');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$kApiBase/login');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'username': u, 'password': p}),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        String msg = 'Credenciales inválidas';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['error'] is String) {
            msg = body['error'];
          }
        } catch (_) {}
        setState(() {
          _error = msg;
          _loading = false;
        });
        return;
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['ok'] != true) {
        setState(() {
          _error = 'Credenciales inválidas';
          _loading = false;
        });
        return;
      }

      final token = (data['token'] ?? '').toString();

      // Puede venir "*" (string) o lista
      final botsField = data['bots'];
      List<String> bots;
      if (botsField == '*') {
        bots = const ['*'];
      } else if (botsField is List) {
        bots = botsField.map((e) => e.toString()).toList();
      } else {
        bots = const <String>[];
      }

      final sp = await SharedPreferences.getInstance();
      await sp.setString('auth_token', token);
      await sp.setStringList('allowed_bots', bots);

      if (!mounted) return;

      if (widget.afterLogin != null) {
        widget.afterLogin!.call();
      } else {
        Navigator.pop(context); // fallback
      }
    } catch (e) {
      setState(() {
        _error = 'Error de red';
      });
      // ignore: avoid_print
      print('Login error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xffF7BD02);
    return Scaffold(
      backgroundColor: brand,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: brand,                 // ← pinta flecha y título
        iconTheme: const IconThemeData(color: brand),
        centerTitle: true,
        title: const Text(
          'Acceso al Chat',
          style: TextStyle(color: brand, fontWeight: FontWeight.w900),
        ),
        // fuerza flecha y acción de volver
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Material(
              elevation: 14,
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Inicia sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: brand,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Usuario',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 46,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brand,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _loading ? '...' : 'Entrar',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
