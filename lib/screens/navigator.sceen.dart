import 'package:flutter/material.dart';
import 'package:inhouston_nuevo/screens/Api/auth.dart';
import 'package:inhouston_nuevo/screens/contact_screen.dart';
import 'package:inhouston_nuevo/screens/home_screen.dart';
import 'package:inhouston_nuevo/screens/loginn_screen.dart';
import 'package:inhouston_nuevo/screens/revistas_screen.dart';
import 'package:inhouston_nuevo/screens/ofertas_screen.dart';
import 'package:inhouston_nuevo/screens/eventos_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inhouston_nuevo/widgets/utils.dart' as utils;

class BottomNavigatorScreen extends StatefulWidget {
  final int selectedIndex;

  const BottomNavigatorScreen({super.key, this.selectedIndex = 0});

  @override
  State<BottomNavigatorScreen> createState() => _BottomNavigatorScreenState();
}

class _BottomNavigatorScreenState extends State<BottomNavigatorScreen> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex;
  }

  List<Widget> getScreens() {
    return [
      const HomeScreen(),
      RevistasScreen(),
      const OfertasScreen(),
      const EventosScreen(),
      const ContactScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/city.png',
                fit: BoxFit.cover,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: getScreens()[selectedIndex],
            ),
          ],
        ),
        bottomNavigationBar: SizedBox(
          height: 100,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xfff7bd02),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 5,
                right: 5,
                bottom: 20,
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                bottom: selectedIndex == 2 ? 25 : 15,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = 2;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xfff7bd02),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_offer,
                            size: 27,
                            color: selectedIndex == 2 ? Colors.white : Colors.black,
                          ),
                          const SizedBox(height: 0),
                          Text(
                            'Ofertas',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: selectedIndex == 2 ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: (value) {
                    if (value == 4 && myUserGlobal.isEmpty) {
                      utils.ventana(
                        context,
                        'Alerta',
                        'Para ingresar a esta función, inicie sesión',
                        'Iniciar Sesión',
                        'Volver',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                      );
                    } else {
                      setState(() {
                        selectedIndex = value;
                      });
                    }
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: const Color(0xfff7bd02),
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                  iconSize: 22,
                  selectedLabelStyle: const TextStyle(fontSize: 10),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Icon(Icons.home_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(Icons.home),
                      ),
                      label: 'Inicio',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Icon(Icons.menu_book_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(Icons.menu_book),
                      ),
                      label: 'Revistas',
                    ),
                    BottomNavigationBarItem(
                      icon: SizedBox(height: 0),
                      activeIcon: SizedBox(height: 0),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Icon(Icons.calendar_month_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(Icons.calendar_month),
                      ),
                      label: 'Eventos',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Icon(Icons.phone_in_talk_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(Icons.phone_in_talk),
                      ),
                      label: 'Contacto',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
