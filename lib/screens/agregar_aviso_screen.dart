import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgregarAvisoScreen extends StatefulWidget {
  const AgregarAvisoScreen({super.key});

  @override
  State<AgregarAvisoScreen> createState() => _AgregarAvisoScreenState();
}

class _AgregarAvisoScreenState extends State<AgregarAvisoScreen> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  bool cargando = false;

  Future<void> guardarAviso() async {
    final String titulo = tituloController.text.trim();
    final String descripcion = descripcionController.text.trim();

    if (titulo.isEmpty || descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      await FirebaseFirestore.instance.collection('avisos').add({
        'titulo': titulo,
        'descripcion': descripcion,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aviso agregado correctamente')),
      );

      tituloController.clear();
      descripcionController.clear();
      Navigator.pop(context); // ← Regresa a la pantalla anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Agregar Aviso'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descripcionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: cargando ? null : guardarAviso,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xfff7bd02),
                  foregroundColor: Colors.black,
                ),
                child: cargando
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'Guardar Aviso',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
