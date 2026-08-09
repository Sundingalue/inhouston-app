import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lógica real para dispositivos móviles: abre el enlace de pago
Future<void> procesarPagoConSquare(String urlPago, BuildContext context) async {
  final uri = Uri.parse(urlPago);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirigiendo al sistema de pago...')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el enlace de pago.')),
    );
  }
}
