import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inhouston_nuevo/screens/api/auth.dart';
import 'package:inhouston_nuevo/screens/agregar_aviso_screen.dart';
import 'package:inhouston_nuevo/screens/empresas_por_categoria_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';

class AvisosScreen extends StatefulWidget {
  const AvisosScreen({super.key});

  @override
  State<AvisosScreen> createState() => _AvisosScreenState();
}

class _AvisosScreenState extends State<AvisosScreen> {
  String uidUsuario = '';

  @override
  void initState() {
    super.initState();
    uidUsuario = myUserGlobal['uid'] ?? '';
    guardarUltimaVisita();
  }

  Future<void> guardarUltimaVisita() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'ultima_visita_avisos',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> marcarComoLeido(String avisoId, List<dynamic> leidoPor) async {
    if (!leidoPor.contains(uidUsuario)) {
      await FirebaseFirestore.instance
          .collection('avisos')
          .doc(avisoId)
          .update({
        'leidoPor': FieldValue.arrayUnion([uidUsuario])
      });
    }
  }

  Future<void> abrirEmpresaSiAplica(Map<String, dynamic> aviso) async {
    final titulo = aviso['titulo'] ?? '';
    final empresaId = aviso['empresaId'];
    final categoria = aviso['categoria'];

    if (empresaId != null && categoria != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              EmpresasPorCategoriaScreen(
            categoria: categoria,
            empresaDestacada: empresaId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = Curves.easeOutExpo;
            final fade = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
            final scale = Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: curve));

            return FadeTransition(
              opacity: animation.drive(fade),
              child: ScaleTransition(
                scale: animation.drive(scale),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
      return;
    }

    // Fallback: intentar extraer empresa por título
    if (titulo.toLowerCase().startsWith('nuevo descuento de')) {
      final nombreEmpresa = titulo.split('de').last.trim();

      try {
        final query = await FirebaseFirestore.instance
            .collection('empresas_ofertas')
            .where('nombre_negocio', isEqualTo: nombreEmpresa)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data() as Map<String, dynamic>;
          final categoria = data['categoria'] ?? '';

          if (categoria.isNotEmpty && mounted) {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    EmpresasPorCategoriaScreen(
                  categoria: categoria,
                  empresaDestacada: nombreEmpresa,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final curve = Curves.easeOutExpo;
                  final fade = Tween(begin: 0.0, end: 1.0)
                      .chain(CurveTween(curve: curve));
                  final scale = Tween(begin: 0.9, end: 1.0)
                      .chain(CurveTween(curve: curve));

                  return FadeTransition(
                    opacity: animation.drive(fade),
                    child: ScaleTransition(
                      scale: animation.drive(scale),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          }
        }
      } catch (e) {
        print('Error al abrir empresa destacada por título: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset('assets/city.png', fit: BoxFit.cover),
        ),
        Scaffold(
          backgroundColor: Colors.black.withOpacity(0.6),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xfff7bd02)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Avisos',
              style: TextStyle(color: Color(0xfff7bd02)),
            ),
            centerTitle: true,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('avisos')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay avisos por ahora.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final avisos = snapshot.data!.docs;

              return ListView.builder(
                itemCount: avisos.length,
                itemBuilder: (context, index) {
                  final aviso = avisos[index];
                  final avisoId = aviso.id;
                  final avisoData =
                      aviso.data() as Map<String, dynamic>;

                  final leidoPor = avisoData.containsKey('leidoPor')
                      ? List<String>.from(avisoData['leidoPor'])
                      : <String>[];

                  final esLeido = leidoPor.contains(uidUsuario);
                  final titulo = avisoData['titulo'] ?? '';
                  final descripcion = avisoData['descripcion'] ?? '';

                  final esDescuento = titulo
                      .toString()
                      .toLowerCase()
                      .startsWith("nuevo descuento de");

                  return Dismissible(
                    key: Key(avisoId),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      FirebaseFirestore.instance
                          .collection('avisos')
                          .doc(avisoId)
                          .delete();
                    },
                    child: GestureDetector(
                      onTap: () async {
                        await marcarComoLeido(avisoId, leidoPor);
                        if (esDescuento && mounted) {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierLabel: '',
                            pageBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                            transitionDuration:
                                const Duration(milliseconds: 500),
                            transitionBuilder: (context, animation, _, child) {
                              return SlideTransition(
                                position: Tween(
                                  begin: const Offset(0.0, 1.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                )),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                ),
                              );
                            },
                          );

                          await Future.delayed(
                              const Duration(milliseconds: 700));
                          if (mounted) Navigator.of(context).pop();
                        }
                        await abrirEmpresaSiAplica(avisoData);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: esDescuento
                            ? BounceInLeft(
                                duration: const Duration(milliseconds: 600),
                                child:
                                    _tarjetaAviso(titulo, descripcion, esLeido),
                              )
                            : _tarjetaAviso(titulo, descripcion, esLeido),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tarjetaAviso(String titulo, String descripcion, bool esLeido) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xfff7bd02),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: esLeido ? const Color(0xff5A8617) : Colors.red,
            width: 5,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(
          esLeido
              ? Icons.check_circle_outline
              : Icons.notifications_active_outlined,
          color: esLeido ? const Color(0xff5A8617) : Colors.red,
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(descripcion),
      ),
    );
  }
}
