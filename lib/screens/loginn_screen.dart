// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:inhouston_nuevo/screens/navigator.sceen.dart';
import 'package:inhouston_nuevo/screens/sign_screen.dart';
import 'package:inhouston_nuevo/screens/forget_password.dart';
import 'package:inhouston_nuevo/widgets/search.dart';
import 'package:inhouston_nuevo/widgets/utils.dart' as utils;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Api/auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String correo = '';
  String contrasena = '';
  double margin1 = 0;
  bool rememberMe = false;
  bool usarFaceID = false;
  bool _googleLoading = false;
  bool mostrarPassword = false;

  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    correo = prefs.getString('saved_email') ?? '';
    contrasena = prefs.getString('saved_pass') ?? '';
    rememberMe = prefs.getBool('remember_me') ?? false;
    usarFaceID = prefs.getBool('usar_faceid') ?? false;

    setState(() {
      correoController.text = correo;
      contrasenaController.text = contrasena;
    });

    if (usarFaceID && correo.isNotEmpty && contrasena.isNotEmpty) {
      await _autenticarConBiometrico();
    }
  }

  Future<void> _autenticarConBiometrico() async {
    try {
      final puedeAutenticar = await auth.canCheckBiometrics;
      final soportado = await auth.isDeviceSupported();
      if (!puedeAutenticar || !soportado) return;

      final disponibles = await auth.getAvailableBiometrics();
      if (!disponibles.contains(BiometricType.face)) return;

      final autenticado = await auth.authenticate(
        localizedReason: 'Autenticarse con Face ID',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (autenticado) {
        await _saveCredentials();
        await WelcomeApi().iniciarSesion(
          correo,
          contrasena,
          context,
          rememberMe: rememberMe,
        );
      }
    } catch (e) {
      print('Error autenticación biométrica: $e');
    }
  }

  Future<void> _solicitarPermisoNotificaciones() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Permiso notificaciones: ${settings.authorizationStatus}');
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('saved_email', correo);
      await prefs.setString('saved_pass', contrasena);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_pass');
      await prefs.setBool('remember_me', false);
    }
    await prefs.setBool('usar_faceid', usarFaceID);
  }

  Future<void> _iniciarSesionManual() async {
    final size = MediaQuery.of(context).size;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _solicitarPermisoNotificaciones();
      await _saveCredentials();
      await WelcomeApi().iniciarSesion(
        correo,
        contrasena,
        context,
        rememberMe: rememberMe,
      );
    } catch (e) {
      print('Error en inicio de sesión manual: $e');
      utils.ventana(
        context,
        'Error',
        'No se pudo iniciar sesión. Verifica tus datos o conexión.',
        'OK',
        '',
        () => Navigator.pop(context),
      );
    } finally {
      Navigator.pop(context);
    }
  }

  Future<void> _iniciarConGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? cuenta = await googleSignIn.signIn();
      if (cuenta == null) {
        setState(() => _googleLoading = false);
        return;
      }

      final googleAuth = await cuenta.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const BottomNavigatorScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } catch (e) {
      print('Error con Google Sign-In: $e');
      if (!mounted) return;
      utils.ventana(
        context,
        'Error',
        'No se pudo iniciar sesión con Google',
        'OK',
        '',
        () => Navigator.pop(context),
      );
    }
    setState(() => _googleLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.13),
                Image.asset('assets/logo_in.png', height: size.height * 0.2),
                const SizedBox(height: 20),
                TextfieldS(
                  text: 'Correo',
                  controller: correoController,
                  changed: (value) => correo = value.trim(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: contrasenaController,
                  obscureText: !mostrarPassword,
                  onChanged: (value) => contrasena = value.trim(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Colors.white),
                    suffixIcon: IconButton(
                      icon: Icon(
                        mostrarPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          mostrarPassword = !mostrarPassword;
                        });
                      },
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recuérdame',
                        style: TextStyle(color: Colors.white)),
                    Switch(
                      value: rememberMe,
                      activeColor: const Color(0xfff7bd02),
                      onChanged: (value) =>
                          setState(() => rememberMe = value),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        correo = correoController.text.trim();
                        contrasena = contrasenaController.text.trim();
                        if (correo.isNotEmpty && contrasena.isNotEmpty) {
                          await _autenticarConBiometrico();
                        } else {
                          utils.ventana(
                            context,
                            'Error',
                            'Primero ingrese usuario y contraseña',
                            'OK',
                            '',
                            () => Navigator.pop(context),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Image.asset('assets/face_id.png',
                              height: 24, width: 24, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Usar ID facial',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    Switch(
                      value: usarFaceID,
                      activeColor: const Color(0xfff7bd02),
                      onChanged: (value) =>
                          setState(() => usarFaceID = value),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () async {
                    setState(() => margin1 = size.height * 0.015);
                    correo = correoController.text.trim();
                    contrasena = contrasenaController.text.trim();

                    final emailPattern =
                        r'^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                    final regExp = RegExp(emailPattern);

                    if (correo.isEmpty || contrasena.isEmpty) {
                      utils.ventana(
                        context,
                        'Error',
                        'Complete todos los campos',
                        'Ok',
                        '',
                        () => Navigator.pop(context),
                      );
                    } else if (!regExp.hasMatch(correo)) {
                      utils.ventana(
                        context,
                        'Error',
                        'Correo inválido',
                        'Back',
                        '',
                        () => Navigator.pop(context),
                      );
                    } else {
                      await _iniciarSesionManual();
                    }

                    // ✅ FIX: verificamos mounted antes de llamar setState
                    Future.delayed(
                      const Duration(seconds: 3),
                      () {
                        if (!mounted) return;
                        setState(() => margin1 = 0);
                      },
                    );
                  },
                  child: Container(
                    width: size.width,
                    height: size.height * 0.07,
                    decoration: BoxDecoration(
                      color: const Color(0xfff7bd02),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.only(bottom: margin1),
                        child: const Text(
                          'Acceder',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SignScreen()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: '¿No tienes una cuenta?',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        TextSpan(
                          text: ' Registrarse',
                          style: TextStyle(
                            color: Color(0xfff7bd02),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                InicioSesion(
                  text1: '',
                  text2: '¿Has olvidado tu clave?',
                  callback: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgetPassword(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
