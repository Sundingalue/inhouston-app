import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';

class SubirFotosEventoScreen extends StatefulWidget {
  const SubirFotosEventoScreen({super.key});

  @override
  State<SubirFotosEventoScreen> createState() => _SubirFotosEventoScreenState();
}

class _SubirFotosEventoScreenState extends State<SubirFotosEventoScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _imagenes = [];
  bool _subiendo = false;
  List<String> _urlsSubidas = [];

  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  Future<void> seleccionarImagenes() async {
    final List<XFile>? seleccionadas = await _picker.pickMultiImage();
    if (seleccionadas != null && seleccionadas.isNotEmpty) {
      setState(() {
        _imagenes = seleccionadas;
      });
    }
  }

  Future<void> subirImagenes(BuildContext context) async {
    if (_empresaController.text.trim().isEmpty ||
        _descripcionController.text.trim().isEmpty ||
        _imagenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor llena todos los campos y selecciona fotos.'),
        ),
      );
      return;
    }

    setState(() {
      _subiendo = true;
    });

    _urlsSubidas.clear();

    try {
      for (var imagen in _imagenes) {
        File file = File(imagen.path);
        String nombreArchivo = basename(imagen.path);
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('eventos')
            .child(nombreArchivo);

        UploadTask uploadTask = ref.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        String url = await snapshot.ref.getDownloadURL();
        _urlsSubidas.add(url);
      }

      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('albums').add({
        'empresa': _empresaController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'imagenes': _urlsSubidas,
        'fecha': FieldValue.serverTimestamp(),
        'usuario': {
          'correo': user?.email ?? '',
          'uid': user?.uid ?? '',
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Álbum creado con éxito!')),
      );

      setState(() {
        _imagenes.clear();
        _urlsSubidas.clear();
        _empresaController.clear();
        _descripcionController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _subiendo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir álbum de fotos'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _empresaController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre del álbum',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _descripcionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Descripción',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: seleccionarImagenes,
            icon: const Icon(Icons.photo_library),
            label: const Text('Seleccionar imágenes'),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _imagenes.isEmpty
                ? const Center(
                    child: Text(
                      'No has seleccionado imágenes.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _imagenes.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      return Image.file(
                        File(_imagenes[index].path),
                        fit: BoxFit.cover,
                      );
                    },
                  ),
          ),
          if (_imagenes.isNotEmpty && !_subiendo)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton.icon(
                onPressed: () => subirImagenes(context),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Subir y guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          if (_subiendo)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: CircularProgressIndicator(color: Colors.amber),
            ),
        ],
      ),
    );
  }
}
