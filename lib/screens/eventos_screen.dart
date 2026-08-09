import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:animate_do/animate_do.dart';
import 'subir_fotos_evento_screen.dart';

class EventosScreen extends StatelessWidget {
  const EventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool soyYo = user?.uid == 'QqODMa60KMhWBlmvPDrsWk4iLXe2';

    // 🟡 Variables que puedes ajustar
    double alturaTarjeta = 200;
    double separacionEntreTarjetas = 10;
    double margenSuperiorLista = 18;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          height: 120,
          decoration: const BoxDecoration(
            color: Color(0xfff7bd02),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Image.asset(
                    'assets/logo_in.png',
                    height: 45,
                  ),
                ),
              ),
              if (soyYo)
                Positioned(
                  top: 70,
                  right: 30,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubirFotosEventoScreen(),
                        ),
                      );
                    },
                    child: const Icon(Icons.add, size: 30, color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/city.png',
              fit: BoxFit.cover,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('albums')
                .orderBy('fecha', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay álbumes subidos aún.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final albums = snapshot.data!.docs;

              return ListView.builder(
                padding: EdgeInsets.only(
                  top: margenSuperiorLista,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final album = albums[index];
                  final empresa = album['empresa'] ?? '';
                  final descripcion = album['descripcion'] ?? '';
                  final imagenes = List<String>.from(album['imagenes'] ?? []);

                  return Padding(
                    padding: EdgeInsets.only(bottom: separacionEntreTarjetas),
                    child: BounceInUp(
                      duration: Duration(milliseconds: 800 + index * 80),
                      child: GestureDetector(
                        onTap: () async {
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
                                    color: Color.fromARGB(255, 227, 227, 227),
                                  ),
                                ),
                              );
                            },
                          );

                          await Future.delayed(
                              const Duration(milliseconds: 700));
                          Navigator.of(context).pop();

                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      GaleriaImagenesScreen(
                                imagenes: imagenes,
                                empresa: empresa,
                              ),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                final curve = Curves.easeOutExpo;
                                final scale = Tween(begin: 0.9, end: 1.0)
                                    .chain(CurveTween(curve: curve));
                                final fade = Tween(begin: 0.0, end: 1.0)
                                    .chain(CurveTween(curve: curve));

                                return FadeTransition(
                                  opacity: animation.drive(fade),
                                  child: ScaleTransition(
                                    scale: animation.drive(scale),
                                    child: child,
                                  ),
                                );
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 600),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (imagenes.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                  child: Image.network(
                                    imagenes[0],
                                    height: alturaTarjeta,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              Container(height: 2, color: Color(0xfff7bd02)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.25),
                                  borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(20)),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      empresa,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      descripcion,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class GaleriaImagenesScreen extends StatelessWidget {
  final List<String> imagenes;
  final String empresa;

  const GaleriaImagenesScreen({
    super.key,
    required this.imagenes,
    required this.empresa,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Galería: $empresa'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: imagenes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GaleriaZoom(
                    imagenes: imagenes,
                    indexInicial: index,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imagenes[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.red),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GaleriaZoom extends StatelessWidget {
  final List<String> imagenes;
  final int indexInicial;

  const GaleriaZoom({
    super.key,
    required this.imagenes,
    required this.indexInicial,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: imagenes.length,
            pageController: PageController(initialPage: indexInicial),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imagenes[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, size: 30, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
