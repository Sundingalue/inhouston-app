import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstagramScreen extends StatefulWidget {
  const InstagramScreen({Key? key}) : super(key: key);

  @override
  State<InstagramScreen> createState() => _InstagramScreenState();
}

class _InstagramScreenState extends State<InstagramScreen> {
  bool isBotEnabled = false;
  bool isLoading = true;
  String? userId; // 🔹 Guardaremos aquí el user_id de Instagram

  final String baseUrl =
            "https://multi-bot-inteligente-v1-production.up.railway.app/api/instagram_bot";

  @override
  void initState() {
    super.initState();
    _loadUserId().then((_) {
      if (userId != null) {
        fetchBotStatus();
      } else {
        setState(() => isLoading = false);
      }
    });
  }

  /// 📥 Cargar user_id desde almacenamiento local
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("ig_user_id");
  }

  /// 💾 Guardar user_id después del login
  Future<void> _saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("ig_user_id", id);
    setState(() {
      userId = id;
    });
  }

  /// 📥 Obtener estado ON/OFF desde backend (multiusuario)
  Future<void> fetchBotStatus() async {
    if (userId == null) return;
    try {
      final response = await http.get(Uri.parse("$baseUrl/status/$userId"));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          isBotEnabled = jsonResponse['enabled'] ?? false;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  /// 🔄 Cambiar estado ON/OFF en backend (multiusuario)
  Future<void> toggleBotStatus() async {
    if (userId == null) return;
    final newStatus = !isBotEnabled;
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/toggle"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": userId,
          "enabled": newStatus,
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() => isBotEnabled = newStatus);
      }
    } catch (_) {}
  }

  /// 🔗 Abrir perfil público de Instagram
  Future<void> openInstagramProfile() async {
    final profileUrl = Uri.parse('https://www.instagram.com/inhoustontexas/');
    if (await canLaunchUrl(profileUrl)) {
      await launchUrl(profileUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// ✅ Login OAuth con Instagram
  Future<void> loginWithInstagram() async {
    final clientId = '279917021820450'; // App oficial IN Houston Texas
    final redirectUri = 'https://inhoustontexas.us/ig_auth_redirect';

    final scope =
        'instagram_basic,instagram_manage_messages,pages_manage_metadata';

    final url = Uri.https(
      'www.facebook.com',
      '/v21.0/dialog/oauth',
      {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scope,
      },
    );

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'inhoustontexas',
      );

      final code = Uri.parse(result).queryParameters['code'];

      if (code != null) {
        print('✅ Código de autorización Instagram: $code');

        // 🔹 Enviar `code` a tu backend para intercambiarlo por access_token y obtener user_id
        final resp = await http.post(
          Uri.parse("$baseUrl/exchange_code"),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "code": code,
            "redirect_uri": redirectUri,
          }),
        );

        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          final id = data["user_id"];
          if (id != null) {
            await _saveUserId(id);
            fetchBotStatus();
            print("✅ Guardado user_id: $id");
          }
        } else {
          print("❌ Error en backend al intercambiar code: ${resp.body}");
        }
      } else {
        print('❌ No se obtuvo código de autorización');
      }
    } catch (e) {
      print('⚠️ Error durante login Instagram: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo institucional
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/city.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(color: Colors.black.withOpacity(0.7)),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: const Color(0xfff7bd02),
            title: const Text('Instagram Bot',
                style: TextStyle(color: Colors.black)),
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 0,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Logo (abre perfil público IG)
                    GestureDetector(
                      onTap: openInstagramProfile,
                      child: Image.asset(
                        'assets/logo_in.png',
                        height: 90,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Switch ON/OFF con LED
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Activar o desactivar bot de Instagram',
                            style:
                                TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color:
                                      isBotEnabled ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: isBotEnabled
                                          ? Colors.green.withOpacity(0.6)
                                          : Colors.red.withOpacity(0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Switch(
                                value: isBotEnabled,
                                onChanged: (value) {
                                  setState(() => isBotEnabled = value);
                                  toggleBotStatus();
                                },
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                                inactiveTrackColor: Colors.white30,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isBotEnabled ? 'ON' : 'OFF',
                                style: TextStyle(
                                  color: isBotEnabled
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Botón Login Instagram (OAuth)
                    ElevatedButton.icon(
                      onPressed: loginWithInstagram,
                      icon: const Icon(Icons.login, color: Colors.black),
                      label: const Text(
                        'Login Instagram',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xfff7bd02),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                    ),

                    const Spacer(flex: 2),
                  ],
                ),
        ),
      ],
    );
  }
}
