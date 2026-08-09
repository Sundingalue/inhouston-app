import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RevistasScreen extends StatelessWidget {
  RevistasScreen({super.key});

  final double posicionDesdeArriba = 137;
  final double alturaRecuadro = 440;

  final PageController _pageController = PageController(viewportFraction: 0.88);

  final List<Map<String, String>> revistas = [
    {
      'titulo': 'Edición 1 - Dic 2023',
      'imagePath': 'assets/edicion_1.jpg',
      'url': 'https://heyzine.com/flip-book/6f3c2929a9.html',
    },
    {
      'titulo': 'Edición 2 - Mar 2024',
      'imagePath': 'assets/edicion_2.jpg',
      'url': 'https://heyzine.com/flip-book/6bf4fb5632.html',
    },
    {
      'titulo': 'Edición 3 - Jun 2024',
      'imagePath': 'assets/edicion_3.jpg',
      'url': 'https://heyzine.com/flip-book/dd5d7e4d88.html',
    },
    {
      'titulo': 'Edición 4 - Sep 2024',
      'imagePath': 'assets/edicion_4.jpg',
      'url': 'https://heyzine.com/flip-book/398e8540f8.html',
    },
    {
      'titulo': 'Edición 5 - Dic 2024',
      'imagePath': 'assets/edicion_5.jpg',
      'url': 'https://heyzine.com/flip-book/30f222b6a0.html',
    },
    {
      'titulo': 'Edición 6 - Mar 2025',
      'imagePath': 'assets/edicion_6.jpg',
      'url': 'https://heyzine.com/flip-book/f89f60752e.html',
    },
      {
      'titulo': 'Edición 7 - Jun 2025',
      'imagePath': 'assets/edicion_7.jpg',
      'url': 'https://heyzine.com/flip-book/623b40a77c.html',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          SizedBox.expand(
            child: Image.asset(
              'assets/city.png',
              fit: BoxFit.cover,
            ),
          ),

          // AppBar con logo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: const Color(0xfff7bd02),
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
              title: Image.asset(
                'assets/logo_in.png',
                height: 45,
              ),
            ),
          ),

          // Carrusel
          Positioned(
            top: posicionDesdeArriba,
            left: -5,
            right: -35,
            child: SizedBox(
              height: alturaRecuadro,
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                itemCount: revistas.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final revista = revistas[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 30),
                    width: 350,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(106, 255, 255, 255)
                          .withOpacity(0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(38, 67, 67, 67)
                              .withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () async {
                        final url = Uri.parse(revista['url']!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo abrir el enlace'),
                            ),
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.asset(
                              revista['imagePath']!,
                              height: alturaRecuadro - 90,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                          // ✅ Línea amarilla decorativa
                          Container(
                            height: 2.5,
                            color: const Color(0xfff7bd02),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.menu_book_rounded,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    revista['titulo']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Texto abajo
          Positioned(
            bottom: 13,
            left: 21,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xfff7bd02),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xfff7bd02),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'EDICIONES',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Explora nuestras ediciones impresas en formato digital desde cualquier lugar y a cualquier hora.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
