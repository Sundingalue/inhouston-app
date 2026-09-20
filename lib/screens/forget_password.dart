import 'package:flutter/material.dart';
import 'package:inhouston_app/screens/loginn_screen.dart';
import 'package:inhouston_app/screens/sign_screen.dart';
import 'package:inhouston_app/widgets/search.dart';
import 'package:inhouston_app/widgets/utils.dart' as utils;
import 'Api/auth.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  String _emailController = '';
  double action = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.15),
              Image.asset('assets/simboloIN.png', height: size.height * 0.2),
              const SizedBox(height: 30),
              TextfieldS(
                text: 'Correo',
                changed: (value) => _emailController = value,
              ),
              const SizedBox(height: 50),
              GestureDetector(
                onTap: () {
                  setState(() => action = size.height * 0.015);

                  final regExp = RegExp(
                      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

                  if (_emailController.isEmpty) {
                    utils.ventana(
                      context,
                      'Error',
                      'Completa el campo de correo electrónico.',
                      'Ok',
                      '',
                      () => Navigator.pop(context),
                    );
                  } else if (!regExp.hasMatch(_emailController)) {
                    utils.ventana(
                      context,
                      'Error',
                      'Correo electrónico inválido.',
                      'Back',
                      '',
                      () => Navigator.pop(context),
                    );
                  } else {
                    WelcomeApi().forgetPasswordService(_emailController);

                    utils.ventana(
                      context,
                      'Enviado',
                      'Si tu correo está en nuestros registros, recibirás un enlace para cambiar la contraseña. Sigue las instrucciones del mensaje.',
                      'Ok',
                      '',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                    );
                  }

                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (!mounted) return;
                    setState(() => action = 0);
                  });
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
                      margin: EdgeInsets.only(bottom: action),
                      child: Text(
                        'Recuperar clave',
                        style: utils.SafeGoogleFont(
                          'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: action == 0
                              ? const Color(0xff000000)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              InicioSesion(
                text1: '¿No tienes una cuenta?',
                text2: ' Registrarse',
                callback: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              InicioSesion(
                text1: '',
                text2: 'Volver al inicio de sesión',
                callback: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
