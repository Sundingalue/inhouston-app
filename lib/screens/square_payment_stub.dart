import 'package:flutter/material.dart';

/// Stub para plataformas que no soportan pagos (ej. web)
Future<void> procesarPagoConSquare(String urlPago, BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Pago no disponible en esta plataforma.')),
  );
}
