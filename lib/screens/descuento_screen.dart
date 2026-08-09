import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:uni_links/uni_links.dart'; // ✅ Para obtener parámetros si vienen del link

class DescuentoScreen extends StatefulWidget {
  final String empresa;
  final String correoEmpresa;
  final String descripcion;

  const DescuentoScreen({
    required this.empresa,
    required this.correoEmpresa,
    required this.descripcion,
  });

  @override
  State<DescuentoScreen> createState() => _DescuentoScreenState();
}

class _DescuentoScreenState extends State<DescuentoScreen> {
  String? codigoGenerado;
  String mensaje = '';
  bool cargando = true;

  String empresa = '';
  String correoEmpresa = '';
  String descripcion = '';

  @override
  void initState() {
    super.initState();
    inicializarDatos();
  }

  Future<void> inicializarDatos() async {
    empresa = widget.empresa;
    correoEmpresa = widget.correoEmpresa;
    descripcion = widget.descripcion;

    if (empresa.isEmpty || correoEmpresa.isEmpty || descripcion.isEmpty) {
      try {
        final uri = await getInitialUri();
        if (uri != null && uri.host == 'pagocompletado') {
          empresa = uri.queryParameters['empresa'] ?? empresa;
          correoEmpresa = uri.queryParameters['correo'] ?? correoEmpresa;
          descripcion = 'Descuento del ${uri.queryParameters['descuento'] ?? ''}';
        }
      } catch (e) {
        print('Error leyendo URI: $e');
      }
    }

    await verificarUltimoDescuento();
  }

  String generarCodigo() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> verificarUltimoDescuento() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        mensaje = 'Usuario no autenticado';
        cargando = false;
      });
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();

    String nombre = userDoc['nombre'] ?? '';
    String apellido = userDoc['apellido'] ?? '';
    final correo = userDoc['correo'] ?? '';
    final telefono = userDoc['telefono'] ?? '';

    // 👇 Separar nombre y apellido si el apellido está vacío
    if (apellido.isEmpty && nombre.trim().contains(' ')) {
      final partes = nombre.trim().split(' ');
      nombre = partes.first;
      apellido = partes.sublist(1).join(' ');
    }

    final now = DateTime.now();
    final limite = now.subtract(const Duration(hours: 24));

    try {
      final query = await FirebaseFirestore.instance
          .collection('Descuentos')
          .where('empresa', isEqualTo: empresa)
          .where('usuario.correo', isEqualTo: correo)
          .orderBy('fecha', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final fecha = (query.docs.first.data()['fecha'] as Timestamp).toDate();
        if (fecha.isAfter(limite)) {
          final diferencia = fecha.add(const Duration(hours: 24)).difference(now);
          final horas = diferencia.inHours;
          final minutos = diferencia.inMinutes % 60;

          setState(() {
            mensaje =
                'Debes esperar $horas horas y $minutos minutos para volver a solicitar este descuento.';
            cargando = false;
          });
          return;
        }
      }

      await generarYEnviarCodigo(nombre, apellido, correo, telefono);
    } catch (e) {
      setState(() {
        mensaje = 'Ocurrió un error al verificar: $e';
        cargando = false;
      });
    }
  }

  Future<void> generarYEnviarCodigo(
      String nombre, String apellido, String correo, String telefono) async {
    final codigo = generarCodigo();
    final fechaEnvio = DateTime.now();
    final fechaFormateada =
        '${fechaEnvio.day.toString().padLeft(2, '0')}/${fechaEnvio.month.toString().padLeft(2, '0')}/${fechaEnvio.year} ${fechaEnvio.hour.toString().padLeft(2, '0')}:${fechaEnvio.minute.toString().padLeft(2, '0')}';

    try {
      await FirebaseFirestore.instance.collection('Descuentos').add({
        'empresa': empresa,
        'descripcion': descripcion,
        'codigo': codigo,
        'fecha': Timestamp.now(),
        'usuario': {
          'nombre': nombre,
          'apellido': apellido,
          'correo': correo,
          'telefono': telefono,
        }
      });

      final smtpServer = SmtpServer(
        'smtp.zoho.com',
        port: 465,
        ssl: true,
        username: 'info@inhoustontexas.us',
        password: 'Venezuela!1',
      );

      final htmlContent = '''
        <html>
        <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
          <div style="max-width: 600px; margin: auto; background: white; padding: 20px; border-radius: 10px;">
            <h2 style="color: #F7BD02;">¡Hola $nombre $apellido!</h2>
            <p>Gracias por solicitar un <strong>descuento</strong> con <strong>$empresa</strong>.</p>
            <p><strong>Promoción:</strong> $descripcion</p>
            <p>Tu <strong>código único</strong> es:</p>
            <div style="text-align: center; margin: 30px 0;">
              <span style="font-size: 32px; font-weight: bold; color: #000; background-color: #F7BD02; padding: 10px 20px; border-radius: 8px; letter-spacing: 4px;">
                $codigo
              </span>
            </div>
            <p style="text-align: center; font-size: 16px; color: #333;">
              ✅ <strong>Válido por 7 días</strong><br>
              📅 <strong>Emitido el:</strong> $fechaFormateada
            </p>
            <hr style="margin: 30px 0;">
            <p style="font-size: 14px; color: #555;">
              Datos del usuario:<br>
              <strong>Nombre:</strong> $nombre $apellido<br>
              <strong>Correo:</strong> $correo<br>
              <strong>Teléfono:</strong> $telefono
            </p>
            <p style="font-size: 14px; color: #777;">— El equipo de IN Houston Texas</p>
            <p style="font-size: 14px; color: #777;">
              <a href="sms:8323790809" style="color: #F7BD02; text-decoration: none;">
                📩 (832) 379-0809
              </a>
            </p>
          </div>
        </body>
        </html>
      ''';

      final message = Message()
        ..from = Address('info@inhoustontexas.us', 'IN Houston Texas')
        ..recipients.add(correo)
        ..bccRecipients.add('info@inhoustontexas.us')
        ..ccRecipients.add(correoEmpresa)
        ..subject = '🎁 Código de Descuento de $empresa'
        ..html = htmlContent;

      await send(message, smtpServer);

      setState(() {
        codigoGenerado = codigo;
        mensaje = 'El código se ha enviado a tu correo.';
        cargando = false;
      });
    } catch (e) {
      setState(() {
        mensaje = 'Ocurrió un error: $e';
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Código de Descuento',
            style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: cargando
            ? const CircularProgressIndicator(color: Colors.yellow)
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      empresa,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    if (codigoGenerado != null)
                      Column(
                        children: [
                          const Text('Tu código único es:',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 10),
                          Text(
                            codigoGenerado!,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),
                    Text(
                      mensaje,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Listo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow.shade700,
                        foregroundColor: Colors.black,
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
