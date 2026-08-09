import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:ui' as ui;

const Color colorAmarillo = Color(0xFFF7BD02);
const Color fondoColor = Color(0xFFF5F5F5);
const Color primario = Colors.black;
const Color textoColor = Colors.black87;
const Color inputFill = Colors.white;

class AgregarEmpresaScreen extends StatefulWidget {
  const AgregarEmpresaScreen({Key? key}) : super(key: key);

  @override
  State<AgregarEmpresaScreen> createState() => _AgregarEmpresaScreenState();
}

class _AgregarEmpresaScreenState extends State<AgregarEmpresaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _negocioController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();

  String? _categoriaSeleccionada;
  String? _descuentoSeleccionado;
  File? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();
  bool _guardando = false;
  bool accesoPermitido = false;

  final List<String> _categorias = [
    'Comida rápida',
    'Restaurantes',
    'Mecánicos',
    'Spa',
    'Manicuristas',
    'Fotografía',
    'Envíos',
    'Perfumerías',
    'Joyerías',
    'Barberías',
    'Zapaterías',
    'Salón de belleza',
  ];
  final List<String> _descuentos = ['20%', '25%', '30%'];

  @override
void initState() {
  super.initState();
  final usuario = FirebaseAuth.instance.currentUser;
  if (usuario != null) {
    accesoPermitido = true;
  }
}

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 400,
      imageQuality: 75,
    );
    if (imagen != null) {
      final File archivo = File(imagen.path);
      final bytes = await archivo.readAsBytes();
      final decoded = await ui.instantiateImageCodec(bytes);
      final frame = await decoded.getNextFrame();
      print('👉 Tamaño imagen: ${frame.image.width}x${frame.image.height}');
      print('👉 Peso imagen: ${bytes.lengthInBytes / (1024 * 1024)} MB');
      setState(() => _imagenSeleccionada = archivo);
    }
  }

  void mostrarDialogoCarga() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Estamos guardando tu información...',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.black),
          ],
        ),
      ),
    );
  }

  void mostrarDialogoExito() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 16),
            Text('Registro exitoso',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Tu empresa ha sido registrada correctamente.'),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () => Navigator.of(context).pop());
  }

  Future<String?> _subirImagen(String nombreNegocio) async {
    if (_imagenSeleccionada == null) return null;

    final nombreArchivo =
        'empresas/${DateTime.now().millisecondsSinceEpoch}_${nombreNegocio.replaceAll(" ", "_")}.jpg';
    final ref = FirebaseStorage.instance.ref().child(nombreArchivo);

    final uploadTask = ref.putFile(_imagenSeleccionada!);
    mostrarDialogoCarga();
    await uploadTask;
    Navigator.of(context).pop();
    return await ref.getDownloadURL();
  }

  Future<void> _enviarCorreo({
    required String correoDestino,
    required String nombreNegocio,
    required String descuento,
  }) async {
    final smtpServer = SmtpServer(
      'smtp.zoho.com',
      port: 465,
      ssl: true,
      username: 'info@inhoustontexas.us',
      password: 'Venezuela!1',
    );

    final message = Message()
      ..from = Address('info@inhoustontexas.us', 'IN Houston Texas')
      ..recipients.add(correoDestino)
      ..bccRecipients.add('info@inhoustontexas.us')
      ..subject = 'Tu descuento ha sido recibido - IN Houston Texas'
      ..html = '''
      <div style="background-color:#fefefe; padding:30px; font-family:Arial,sans-serif;">
        <h2 style="color:#000000;">🎉 ¡Gracias por registrarte en IN Houston Texas!</h2>
        <p>Tu empresa <strong>$nombreNegocio</strong> se ha registrado exitosamente con un descuento de <strong>$descuento</strong>.</p>
        <p>En breve aparecerás en nuestra app móvil en la plataforma de descuentos.</p>
        <br>
        <a href="https://inhoustontexas.us" style="background-color:#F7BD02; padding:10px 20px; color:#000; text-decoration:none; border-radius:6px; font-weight:bold;">Ver sitio web</a>
        <br><br>
        <hr>
        <p style="font-size:12px; color:#555;">IN Houston Texas • info@inhoustontexas.us</p>
      </div>
      ''';

    try {
      await send(message, smtpServer);
    } catch (e) {
      print('Error al enviar correo: $e');
    }
  }

  Future<void> _crearAviso(String negocio, String descuento) async {
    try {
      await FirebaseFirestore.instance.collection('avisos').add({
        'titulo': 'Nuevo descuento de $negocio',
        'descripcion':
            '¡Ahora puedes disfrutar de un descuento del $descuento en $negocio!',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al crear aviso: $e');
    }
  }

  Future<void> _guardarEmpresa() async {
    if (!_formKey.currentState!.validate() ||
        _categoriaSeleccionada == null ||
        _descuentoSeleccionado == null ||
        _imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Por favor completa todos los campos y selecciona una imagen.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _guardando = true);

    final nombreNegocio = _negocioController.text.trim();
    String instagram = _instagramController.text.trim();
    if (!instagram.startsWith('@')) instagram = '@$instagram';

    final correo = _correoController.text.trim();
    final descuento = _descuentoSeleccionado!;
    final categoria = _categoriaSeleccionada!;
    final imagenUrl = await _subirImagen(nombreNegocio);

    try {
      await FirebaseFirestore.instance.collection('empresas_ofertas').add({
        'nombre_negocio': nombreNegocio,
        'instagram': instagram,
        'correo': correo,
        'descuento': descuento,
        'categoria': categoria,
        'imagenUrl': imagenUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _crearAviso(nombreNegocio, descuento);
      await _enviarCorreo(
        correoDestino: correo,
        nombreNegocio: nombreNegocio,
        descuento: descuento,
      );

      mostrarDialogoExito();
      _formKey.currentState!.reset();
      _negocioController.clear();
      _instagramController.clear();
      _correoController.clear();
      setState(() {
        _imagenSeleccionada = null;
        _categoriaSeleccionada = null;
        _descuentoSeleccionado = null;
        _guardando = false;
      });
    } catch (e) {
      print('Error al guardar en Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() => _guardando = false);
    }
  }

  Widget _campo(TextEditingController controller, String label,
      {TextInputType tipo = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textoColor),
          filled: true,
          fillColor: inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        style: TextStyle(color: textoColor),
        validator: (value) =>
            value == null || value.isEmpty ? 'Este campo es obligatorio' : null,
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textoColor),
          filled: true,
          fillColor: inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) => value == null ? 'Selecciona una opción' : null,
      ),
    );
  }

  Widget _imagenInput() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: _imagenSeleccionada == null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.image, size: 70, color: Colors.grey),
                    Positioned(
                      bottom: 12,
                      child: Text(
                        '800x400 px. recomendado',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imagenSeleccionada!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _seleccionarImagen,
            icon: const Icon(Icons.photo),
            label: const Text('Seleccionar imagen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primario,
              foregroundColor: colorAmarillo,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!accesoPermitido) {
      return const Scaffold(body: Center(child: Text('Acceso denegado')));
    }

    return Scaffold(
      backgroundColor: fondoColor,
      appBar: AppBar(
        backgroundColor: primario,
        title: Text(
          'Agregar Empresa',
          style: TextStyle(color: colorAmarillo, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: colorAmarillo),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _campo(_negocioController, 'Nombre del negocio'),
              _campo(_instagramController, 'Instagram'),
              _dropdown(
                label: 'Selecciona la categoría',
                items: _categorias,
                value: _categoriaSeleccionada,
                onChanged: (val) =>
                    setState(() => _categoriaSeleccionada = val),
              ),
              _dropdown(
                label: 'Selecciona el descuento',
                items: _descuentos,
                value: _descuentoSeleccionado,
                onChanged: (val) =>
                    setState(() => _descuentoSeleccionado = val),
              ),
              _campo(_correoController, 'Correo del negocio',
                  tipo: TextInputType.emailAddress),
              _imagenInput(),
              ElevatedButton(
                onPressed: _guardando ? null : _guardarEmpresa,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primario,
                  foregroundColor: colorAmarillo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
