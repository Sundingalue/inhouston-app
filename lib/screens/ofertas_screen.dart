import 'package:flutter/material.dart';
import 'package:inhouston_nuevo/screens/empresas_por_categoria_screen.dart';
import 'package:animate_do/animate_do.dart';

class OfertasScreen extends StatefulWidget {
  const OfertasScreen({super.key});

  @override
  State<OfertasScreen> createState() => _OfertasScreenState();
}

class _OfertasScreenState extends State<OfertasScreen> {
  final List<Map<String, String>> todasLasCategorias = [
    {'image': 'assets/comida_rapida.png', 'title': 'Comida rápida'},
    {'image': 'assets/restaurantes.png', 'title': 'Restaurantes'},
    {'image': 'assets/mecanicos.png', 'title': 'Mecánicos'},
    {'image': 'assets/spa.png', 'title': 'Spa'},
    {'image': 'assets/manicurista.png', 'title': 'Manicuristas'},
    {'image': 'assets/fotografia.png', 'title': 'Fotografía'},
    {'image': 'assets/envios.png', 'title': 'Envíos'},
    {'image': 'assets/perfumeria.png', 'title': 'Perfumerías'},
    {'image': 'assets/joyeria.png', 'title': 'Joyerías'},
    {'image': 'assets/barberia.png', 'title': 'Barberías'},
    {'image': 'assets/zapateria.png', 'title': 'Zapaterías'},
    {'image': 'assets/salon_belleza.png', 'title': 'Salón de belleza'},
  ];

  List<Map<String, String>> categoriasFiltradas = [];

  @override
  void initState() {
    super.initState();
    categoriasFiltradas = List.from(todasLasCategorias);
  }

  void filtrarCategorias(String query) {
    final resultado = todasLasCategorias
        .where(
            (cat) => cat['title']!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      categoriasFiltradas = resultado;
    });
  }

  Future<void> navegarConAnimacion(String categoria) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionDuration: const Duration(milliseconds: 500),
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
              color: Color.fromARGB(255, 227, 227, 227),
            ),
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pop();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EmpresasPorCategoriaScreen(categoria: categoria),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = Curves.easeOutExpo;
          final scale =
              Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: curve));
          final fade =
              Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/city.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/ofertas_1.png',
                height: 100,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 90),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: filtrarCategorias,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.black),
                        hintText: 'Buscar categoría...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      itemCount: categoriasFiltradas.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 11,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final categoria = categoriasFiltradas[index];
                        return BounceInUp(
                          duration: Duration(milliseconds: 800 + index * 80),
                          child: GestureDetector(
                            onTap: () {
                              navegarConAnimacion(categoria['title']!);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: Image.asset(
                                        categoria['image']!,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 2,
                                    color: const Color(0xfff7bd02),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 10),
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(72, 97, 97, 97),
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      categoria['title']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
