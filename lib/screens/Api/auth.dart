// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:inhouston_nuevo/widgets/circle_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/utils.dart';
import '../navigator.sceen.dart';

Map<String, dynamic> myUserGlobal = {};

Route rutaFadeIn(ruta) {
  return PageRouteBuilder(
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => ruta,
    transitionDuration: const Duration(seconds: 1),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
        child: child,
      );
    },
  );
}

Route rutaCircle(ruta) {
  return PageRouteBuilder(
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => ruta,
    transitionDuration: const Duration(seconds: 1),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var screenSize = MediaQuery.of(context).size;
      var centerCircleClipper = Offset(screenSize.width / 2, screenSize.height / 2);
      double beginRadius = 0.0;
      double endRadius = screenSize.height * 1.2;
      var radiusTween = Tween(begin: beginRadius, end: endRadius);
      var radiusTweenAnimation = animation.drive(radiusTween);

      return ClipPath(
        clipper: CircleTransitionClipper(center: centerCircleClipper, radius: radiusTweenAnimation.value),
        child: child,
      );
    },
  );
}

class WelcomeApi {
  Future registro(
    String email,
    String password,
    String name,
    String apellido,
    String number,
    String ciudad,
    String estado,
    BuildContext context,
  ) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).then((value) async {
        Navigator.pop(context);

        if (value.user!.uid.isNotEmpty) {
          final uid = value.user!.uid;

          // ✅ Eliminar datos anteriores si existen
          final userDoc = FirebaseFirestore.instance.collection('Users').doc(uid);
          final docSnapshot = await userDoc.get();
          if (docSnapshot.exists) {
            await userDoc.delete();
          }

          final fcmToken = await FirebaseMessaging.instance.getToken();

          // ✅ Separar nombre y apellido si apellido viene vacío
          String nombreFinal = name;
          String apellidoFinal = apellido;

          if (apellidoFinal.isEmpty && name.trim().contains(' ')) {
            final partes = name.trim().split(' ');
            nombreFinal = partes.first;
            apellidoFinal = partes.sublist(1).join(' ');
          }

          Map<String, dynamic> data = {
            'nombre': nombreFinal,
            'apellido': apellidoFinal,
            'telefono': number,
            'ciudad': ciudad,
            'estado': estado,
            'correo': email,
            'uid': uid,
            if (fcmToken != null) 'fcmToken': fcmToken,
          };

          await FirebaseFirestore.instance.collection('Users').doc(uid).set(data);

          final prefs = await SharedPreferences.getInstance();
          prefs.setString('myData', json.encode(data));
          myUserGlobal = data;

          Navigator.of(context).push(rutaFadeIn(const BottomNavigatorScreen()));
        }
      });
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'weak-password') {
        ventana(context, 'Error', 'Contraseña muy corta, Ingrese una contraseña más fuerte', 'Ok', '', () {
          Navigator.pop(context);
        });
      } else if (e.code == 'email-already-in-use') {
        ventana(context, 'Error', 'Usuario registrado, Este correo está en uso, regresa e inicia sesión', 'Ok', '', () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      print('❌ Error en registro: $e');
    }
  }

  Future<void> actualizarDatosUsuario() async {
    try {
      Map<String, dynamic> data = {
        'nombre': myUserGlobal['nombre'],
        'apellido': myUserGlobal['apellido'],
        'telefono': myUserGlobal['telefono'],
        'ciudad': myUserGlobal['ciudad'],
        'estado': myUserGlobal['estado'],
      };
      await FirebaseFirestore.instance.collection('Users').doc(myUserGlobal['uid']).update(data);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('myData', json.encode(myUserGlobal));
    } catch (e) {
      // error
    }
  }

  Future<void> cargarDatosUsuarioActual() async {
    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario != null) {
        final snapshot = await FirebaseFirestore.instance.collection('Users').doc(usuario.uid).get();
        if (snapshot.exists) {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('myData', json.encode(snapshot.data()));
          myUserGlobal = snapshot.data()!;
        }
      }
    } catch (e) {
      print('Error cargando datos del usuario actual: $e');
    }
  }

  Future iniciarSesion(String emailAddress, String password, context, {bool rememberMe = false}) async {
    try {
      print('📧 Email recibido en login: "$emailAddress"');
      print('🔐 Contraseña recibida: "$password"');

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return const CupertinoAlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cargando...'),
                SizedBox(height: 20),
                CircularProgressIndicator()
              ],
            ),
          );
        },
      );

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailAddress.trim(),
        password: password.trim(),
      );

      final snapshot = await FirebaseFirestore.instance.collection('Users').doc(cred.user!.uid).get();
      final prefs = await SharedPreferences.getInstance();

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await FirebaseFirestore.instance.collection('Users').doc(cred.user!.uid).update({'fcmToken': fcmToken});
      }

      myUserGlobal = snapshot.data() ?? {};
      prefs.setString('myData', json.encode(myUserGlobal));

      if (rememberMe) {
        await prefs.setString('saved_email', emailAddress);
        await prefs.setString('saved_pass', password);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_pass');
        await prefs.setBool('remember_me', false);
      }

      print('✅ Autenticación exitosa con Firebase');
      Navigator.of(context, rootNavigator: true).pop(); // Cierra el dialog
      Future.delayed(const Duration(milliseconds: 100), () {
        Navigator.of(context).pushReplacement(
          rutaFadeIn(const BottomNavigatorScreen()),
        );
      });

    } on FirebaseAuthException catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      print('❌ Error de FirebaseAuth: ${e.code}');

      String mensaje = switch (e.code) {
        'user-not-found' => 'Usuario no encontrado. Verifique su correo o regístrese.',
        'wrong-password' => 'Contraseña incorrecta',
        'INVALID_LOGIN_CREDENTIALS' => 'Credenciales incorrectas',
        'too-many-requests' => 'Demasiados intentos. Intente más tarde.',
        _ => 'Error desconocido: ${e.message}'
      };

      ventana(context, 'Error', mensaje, 'Ok', '', () {
        Navigator.pop(context);
      });
    }
  }

  Future cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
  }

  Future forgetPasswordService(String emailAddress) async {
    try {
      return await FirebaseAuth.instance.sendPasswordResetEmail(email: emailAddress);
    } on FirebaseAuthException catch (err) {
      throw Exception(err.message.toString());
    } catch (err) {
      throw Exception(err.toString());
    }
  }
}
