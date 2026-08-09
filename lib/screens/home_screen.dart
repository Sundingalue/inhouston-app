// 🔽 IMPORTACIONES
import 'package:flutter/material.dart';
import 'package:inhouston_nuevo/widgets/search.dart';
import 'package:inhouston_nuevo/screens/profile_scree.dart';
import 'package:inhouston_nuevo/screens/detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:inhouston_nuevo/screens/categorias_screen.dart';
import 'package:inhouston_nuevo/screens/contact_screen.dart';
import 'package:inhouston_nuevo/screens/ofertas_screen.dart';
import 'package:inhouston_nuevo/screens/revistas_screen.dart';
import 'package:inhouston_nuevo/screens/avisos_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // (se mantiene por si luego lo usamos para links externos)
import '../screens/Api/auth.dart';

// ⬇️ IMPORTAMOS LA NUEVA PANTALLA DE INSTAGRAM
import 'package:inhouston_nuevo/screens/instagram_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userEmail;
  bool hayAvisosNuevos = false;

  // ✅ AHORA: en vez de abrir navegador externo, navegamos al panel interno
  Future<void> _openChatLogin() async {
    if (!mounted) return;
    Navigator.pushNamed(context, '/client-panel');
  }

  // ✅ ABRIR NUEVA PANTALLA DE INSTAGRAM
  Future<void> _openInstagramScreen() async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InstagramScreen()),
    );
  }

  final List<Map<String, dynamic>> premiumServices = [
    {
      'nombre': 'M.Gabriela Irureta',
      'tipo': 'Realtor',
      'ciudad': 'Houston',
      'telefono': '8322445485',
      'direccion': '23410 Grand Reserve Dr. Suite 603, Katy TX 77494',
      'instagram': 'https://www.instagram.com/step.realestate/',
      'imageUrl': 'https://inhoustontexas.us/wp-content/uploads/2023/09/step.jpg'
    },
    {
      'nombre': 'Galue Group',
      'tipo': 'Sonido Profesional',
      'ciudad': 'Houston',
      'telefono': '7862237089',
      'direccion': 'Houston TX',
      'instagram': 'https://instagram.com/galuegroup',
      'imageUrl': 'https://inhoustontexas.us/wp-content/uploads/2023/08/galue-group-.jpg'
    },
    {
      'nombre': 'Ilac',
      'tipo': 'Migración • Seguros',
      'ciudad': '',
      'telefono': '7869614919',
      'direccion': '27100 Shadow Dune Dr, Katy, TX 77493',
      'instagram': 'https://instagram.com/servicioalmigrante',
      'imageUrl': 'https://inhoustontexas.us/wp-content/uploads/2024/07/IMG_7732.jpg'
    },
  ];

  @override
  void initState() {
    super.initState();
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario != null) {
      userEmail = usuario.email;
    }
    verificarAvisos();
  }

  Future<void> verificarAvisos() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimaVisita = prefs.getInt('ultima_visita_avisos') ?? 0;

    final query = await FirebaseFirestore.instance
        .collection('avisos')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final aviso = query.docs.first;
      final timestamp = aviso['timestamp'];
      if (timestamp != null &&
          timestamp.millisecondsSinceEpoch > ultimaVisita) {
        if (!mounted) return;
        setState(() {
          hayAvisosNuevos = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: size.height,
            child: Image.asset(
              'assets/city.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Header(size: size, hayAvisosNuevos: hayAvisosNuevos),
          ),
          Positioned(
            top: size.height * 0.35,
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
              child: Column(
                children: [
                  Textfield(),
                  const SizedBox(height: 6),
                  // 🔽 BOTONES Chat + Instagram + Ver servicios
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openChatLogin,
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                          label: const Text(
                            'Chat',
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xfff7bd02),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openInstagramScreen,
                          icon: const Icon(Icons.camera_alt_outlined, color: Colors.black),
                          label: const Text(
                            'Instagram',
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xfff7bd02),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoriasScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.view_module_rounded, color: Colors.black),
                          label: const Text(
                            'Servicios',
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xfff7bd02),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 🔽 SE MANTIENE LISTA DE SERVICIOS PREMIUM
                  Container(
                    height: 315,
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(54, 191, 190, 190),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(premiumServices.length, (index) {
                          final servicio = premiumServices[index];
                          return BounceInUp(
                            duration: Duration(milliseconds: 800 + index * 100),
                            child: StatefulBuilder(
                              builder: (context, setLocalState) {
                                double offsetX = 0;
                                return GestureDetector(
                                  onTap: () async {
                                    setLocalState(() => offsetX = -10);
                                    await Future.delayed(const Duration(milliseconds: 100));
                                    setLocalState(() => offsetX = 0);
                                    await Future.delayed(const Duration(milliseconds: 100));
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailScreen(servicio: servicio),
                                      ),
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    transform: Matrix4.translationValues(offsetX, 0, 0),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 5),
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 5, 5, 5).withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color.fromARGB(255, 255, 220, 220).withOpacity(0.3),
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromARGB(31, 211, 211, 211),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              servicio['imageUrl'],
                                              height: 59,
                                              width: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  servicio['nombre'],
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${servicio['tipo']} • ${servicio['ciudad']}',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white70),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 17,
                                            color: Colors.white54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔥 Clase HEADER
class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.size,
    required this.hayAvisosNuevos,
  });

  final Size size;
  final bool hayAvisosNuevos;

  @override
  Widget build(BuildContext context) {
    final bool hasUser = myUserGlobal != null && myUserGlobal.isNotEmpty;
    final String nombre = hasUser ? myUserGlobal['nombre'] ?? '' : '';
    final String apellido = hasUser ? myUserGlobal['apellido'] ?? '' : '';
    final String imageUrl = hasUser ? myUserGlobal['imageUrl'] ?? '' : '';

    return Container(
      width: size.width,
      height: size.height * 0.42,
      decoration: const BoxDecoration(
        color: Color(0xfff7bd02),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 70,
            left: 18,
            right: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/logo_in.png', width: 60, height: 70),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AvisosScreen()),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications, color: Colors.black, size: 30),
                      if (hayAvisosNuevos)
                        const Positioned(
                          top: -2,
                          right: -2,
                          child: CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: Hero(
                    tag: 'avatar-profile',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.black, size: 40)
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  hasUser ? 'Hola, $nombre$apellido' : 'Hola, Invitado',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 0),
                const Text(
                  '¿En qué te podemos ayudar hoy?',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
