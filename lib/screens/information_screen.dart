import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inhouston_app/widgets/utils.dart' as utils;
import 'package:url_launcher/url_launcher.dart';
import '../widgets/search.dart';
import 'Api/api.dart';
import 'Api/auth.dart';

class InformationScreen extends StatefulWidget {
  final Map info;
  const InformationScreen({super.key, required this.info});

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  double margin1 = 0;
  double margin2 = 0;
  double margin3 = 0;
  String comentarioController = '';
  List<DropdownMenuItem> list = <DropdownMenuItem>[
    const DropdownMenuItem(value: 'Horarios', child: Text('Horarios')),
    const DropdownMenuItem(value: 'Disponibilidad', child: Text('Disponibilidad')),
    const DropdownMenuItem(value: 'Reservas', child: Text('Reservas')),
    const DropdownMenuItem(value: 'Precios', child: Text('Precios')),
    const DropdownMenuItem(value: 'Otro', child: Text('Otro')),
  ];
  String? dropdownValue;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: size.height,
            child: Image.asset(
              'assets/city.png',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.05),
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.fromLTRB(65, 23, 66, 17),
                        width: size.height,
                        decoration: const BoxDecoration(color: Color(0x7f000000)),
                        child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                      ),
                      Positioned(
                        left: size.width * 0.03,
                        top: size.height * 0.04,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: size.height * 0.04,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.06),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _botonAccion(
                        texto: 'Llamar',
                        margin: margin1,
                        onTap: () {
                          setState(() => margin1 = size.height * 0.015);
                          launchUrl(Uri(scheme: 'tel', path: widget.info['telefono']));
                          Future.delayed(const Duration(seconds: 3), () => setState(() => margin1 = 0));
                        },
                      ),
                      _botonAccion(
                        texto: 'Ver Mapa',
                        margin: margin2,
                        onTap: () {
                          setState(() => margin2 = size.height * 0.015);
                          launchUrl(Uri.parse('https://www.google.com/maps/place/${widget.info['direccion']}'));
                          Future.delayed(const Duration(seconds: 3), () => setState(() => margin2 = 0));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Solicita Información',
                    style: utils.SafeGoogleFont(
                      'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.2125,
                      color: const Color(0xffffffff),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Motivo *',
                        style: utils.SafeGoogleFont(
                          'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: size.height * 0.07,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12.0)),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton(
                              value: dropdownValue,
                              onChanged: (value) => setState(() => dropdownValue = value),
                              items: list,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextfieldS(
                    changed: (value) => comentarioController = value,
                    text: 'Comentario *',
                  ),
                  const SizedBox(height: 50),
                  GestureDetector(
                    onTap: _enviarSolicitud,
                    child: Container(
                      height: size.height * 0.065,
                      width: size.width,
                      decoration: BoxDecoration(
                        color: const Color(0xfff7bd02),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.only(bottom: margin3),
                          child: Text(
                            'Enviar Solicitud',
                            style: utils.SafeGoogleFont(
                              'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: margin3 != 0 ? Colors.white : const Color(0xff000000),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonAccion({
    required String texto,
    required double margin,
    required VoidCallback onTap,
  }) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: size.height * 0.065,
          decoration: BoxDecoration(
            color: const Color(0xfff7bd02),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(bottom: margin),
              child: Text(
                texto,
                style: utils.SafeGoogleFont(
                  'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: margin != 0 ? Colors.white : const Color(0xff000000),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _enviarSolicitud() {
    Size size = MediaQuery.of(context).size;
    setState(() => margin3 = size.height * 0.015);
    if (comentarioController.isEmpty || dropdownValue == null) {
      utils.ventana(
        context,
        'Error',
        'Complete todos los campos requeridos *',
        'Ok',
        '',
        () => Navigator.pop(context),
      );
    } else {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => const CupertinoAlertDialog(
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
      FirebaseFirestore.instance.collection('Solicitudes').add({
        'servicio': widget.info,
        'user': myUserGlobal,
        'motivo': dropdownValue,
        'comentario': comentarioController
      }).then((_) {
        Api().snackBarErrorSuccefull(
          context,
          'Solicitud enviada, pronto nos pondremos en contacto contigo',
          Colors.green,
        );
        Navigator.pop(context);
        Navigator.pop(context);
      });
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => margin3 = 0);
    });
  }
}
