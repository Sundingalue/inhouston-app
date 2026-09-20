import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:inhouston_app/screens/descuento_screen.dart';
import 'package:animate_do/animate_do.dart';

class EmpresasPorCategoriaScreen extends StatelessWidget {
  final String categoria;
  final String? empresaDestacada; // Este será el ID del documento

  const EmpresasPorCategoriaScreen({
    super.key,
    required this.categoria,
    this.empresaDestacada,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color.fromARGB(255, 245, 194, 10)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ofertas en $categoria'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/city.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/agregar');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'AGREGAR EMPRESA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7BD02),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('empresas_ofertas')
                      .where('categoria', isEqualTo: categoria)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No hay empresas disponibles en esta categoría.',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      );
                    }

                    final empresas = snapshot.data!.docs;

                    final ordenadas = List.from(empresas)
                      ..sort((a, b) {
                        final t1 = a['timestamp'] as Timestamp?;
                        final t2 = b['timestamp'] as Timestamp?;
                        if (t1 == null && t2 == null) return 0;
                        if (t1 == null) return 1;
                        if (t2 == null) return -1;
                        return t2.compareTo(t1);
                      });

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: ordenadas.length,
                      itemBuilder: (context, index) {
                        final doc = ordenadas[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final nombreNegocio =
                            (data['nombre_negocio'] ?? '').toString();

                        final esDestacada = empresaDestacada != null &&
                            doc.id == empresaDestacada;

                        return BounceInUp(
                          duration: Duration(milliseconds: 800 + index * 100),
                          child: Container(
                            key: esDestacada
                                ? const ValueKey('empresa_destacada')
                                : null,
                            color: esDestacada
                                ? Colors.yellow.withOpacity(0.15)
                                : null,
                            child: _TarjetaEmpresaCargada(
                              nombre: nombreNegocio.toUpperCase(),
                              descripcion:
                                  'Descuento especial del ${data['descuento'] ?? '--'}',
                              instagram: data['instagram'] ?? '',
                              imagen: data['imagenUrl'] ?? '',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DescuentoScreen(
                                      empresa: data['nombre_negocio'] ?? '',
                                      correoEmpresa: data['correo'] ?? '',
                                      descripcion:
                                          'Descuento del ${data['descuento'] ?? ''}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaEmpresaCargada extends StatelessWidget {
  final String nombre;
  final String descripcion;
  final String instagram;
  final String imagen;
  final VoidCallback onTap;

  const _TarjetaEmpresaCargada({
    required this.nombre,
    required this.descripcion,
    required this.instagram,
    required this.imagen,
    required this.onTap,
  });

  void _abrirInstagram(String username) async {
    final cleanUser = username.replaceAll('@', '');
    final uri = Uri.parse('https://instagram.com/$cleanUser');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  imagen,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 130,
                    color: Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7BD02),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'OFERTA ACTIVA',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 0),
                Row(
                  children: [
                    const Icon(Icons.local_offer_outlined, color: Colors.white),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        descripcion,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (instagram.isNotEmpty)
                      ElevatedButton(
                        onPressed: () => _abrirInstagram(instagram),
                        child: const Text(
                          'Instagram',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF7BD02),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: onTap,
                      child: const Text(
                        'Obtener descuento',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF7BD02),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
