import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inhouston_app/screens/Api/auth.dart' hide ventana;
import 'package:inhouston_app/screens/loginn_screen.dart';
import 'package:inhouston_app/widgets/search.dart';
import 'package:inhouston_app/widgets/utils.dart';

class SignScreen extends StatelessWidget {
  String nameController = '';
  String apellidoController = '';
  String telefonoController = '';
  String ciudadController = '';
  String estadoController = '';
  String correoController = '';
  String contraController = '';
  String reContraController = '';

  SignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/simboloIN.png', height: size.height * 0.2),
            const SizedBox(height: 30),
            Text(
              'Suscríbete',
              style: SafeGoogleFont(
                'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            TextfieldS(
              changed: (value) => nameController = value,
              text: 'Nombre *',
            ),
            const SizedBox(height: 20),
            TextfieldS(
              changed: (value) => apellidoController = value,
              text: 'Apellido *',
            ),
            const SizedBox(height: 20),
            PhoneField(
              changed: (value) => telefonoController = value,
              text: 'Teléfono',
            ),
            TextfieldS(
              changed: (value) => ciudadController = value,
              text: 'Ciudad',
            ),
            const SizedBox(height: 20),
            TextfieldS(
              changed: (value) => estadoController = value,
              text: 'Estado',
            ),
            const SizedBox(height: 20),
            TextfieldS(
              changed: (value) => correoController = value,
              text: 'Correo *',
            ),
            const SizedBox(height: 20),
            TextfieldPassword(
              changed: (value) => contraController = value,
              text: 'Contraseña *',
            ),
            const SizedBox(height: 20),
            TextfieldPassword(
              changed: (value) => reContraController = value,
              text: 'Repetir Contraseña *',
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: () {
                final emailReg = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,4}$');

                if (nameController.isEmpty ||
                    apellidoController.isEmpty ||
                    correoController.isEmpty ||
                    contraController.isEmpty ||
                    reContraController.isEmpty) {
                  ventana(
                    context,
                    'Error',
                    'Complete todos los campos requeridos *',
                    'Ok',
                    '',
                    () => Navigator.pop(context),
                  );
                } else if (!emailReg.hasMatch(correoController)) {
                  ventana(
                    context,
                    'Error',
                    'Correo inválido',
                    'Back',
                    '',
                    () => Navigator.pop(context),
                  );
                } else if (contraController.length < 7) {
                  ventana(
                    context,
                    'Error',
                    'Ingrese al menos 7 caracteres',
                    'Back',
                    '',
                    () => Navigator.pop(context),
                  );
                } else if (contraController != reContraController) {
                  ventana(
                    context,
                    'Error',
                    'Las contraseñas no coinciden',
                    'Back',
                    '',
                    () => Navigator.pop(context),
                  );
                } else {
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (_) => const CupertinoAlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Cargando'),
                          SizedBox(height: 20),
                          CircularProgressIndicator()
                        ],
                      ),
                    ),
                  );

                  WelcomeApi().registro(
                    correoController,
                    reContraController,
                    nameController,
                    apellidoController,
                    telefonoController,
                    ciudadController,
                    estadoController,
                    context,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                width: size.width,
                decoration: BoxDecoration(
                  color: const Color(0xfff7bd02),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Acceder',
                    style: SafeGoogleFont(
                      'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            InicioSesion(
              text1: '¿Tienes una cuenta?',
              text2: ' Iniciar Sesión',
              callback: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
