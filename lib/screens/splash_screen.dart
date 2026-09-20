import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inhouston_app/screens/api/auth.dart';
import 'package:inhouston_app/screens/loginn_screen.dart';
import 'package:inhouston_app/screens/navigator.sceen.dart';
import 'package:local_auth/local_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  final LocalAuthentication auth = LocalAuthentication();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = Tween<double>(begin: 1.5, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticInOut),
    );

    _controller = VideoPlayerController.asset('assets/logo_animado.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
        Future.delayed(_controller.value.duration, () async {
          if (!mounted) return;
          await _fadeController.forward();
          await _scaleController.forward();
          if (!mounted) return;
          _navegar();
        });
      });
  }

  Future<void> _navegar() async {
    // 🔒 Eliminamos el login automático. Siempre se va a login.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: const LoginScreen(), // ✅ Siempre se va aquí
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
