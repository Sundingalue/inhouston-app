import 'package:flutter/material.dart';
import 'package:inhouston_nuevo/screens/categorias.dart';
import 'package:inhouston_nuevo/widgets/search.dart';
import 'package:inhouston_nuevo/widgets/utils.dart';
import 'package:animate_do/animate_do.dart';
import 'package:inhouston_nuevo/screens/navigator.sceen.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/city.png',
              fit: BoxFit.cover,
            ),
          ),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 75),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) =>
                            const BottomNavigatorScreen(selectedIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home, color: Colors.black),
                  label: const Text(
                    'Volver al inicio',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF7BD02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  height: 58,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchText = value.toLowerCase();
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Buscar categoría...',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.black54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 255, 255, 255), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xffF7BD02), width: 5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 700,
                child: DatesContact(searchText: searchText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DatesContact extends StatefulWidget {
  final String searchText;

  const DatesContact({super.key, required this.searchText});

  @override
  State<DatesContact> createState() => _DatesContactState();
}

class _DatesContactState extends State<DatesContact> {
  Map servSelected = {};

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final categorias = Categorias()
        .allCategoria
        .where((cat) =>
            cat['nombre'].toLowerCase().contains(widget.searchText))
        .toList();

    return GridView.count(
      crossAxisCount: 4,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
      crossAxisSpacing: size.width * 0.03,
      mainAxisSpacing: size.height * 0.01,
      children: List.generate(categorias.length, (index) {
        final categoria = categorias[index];
        return BounceInUp(
          duration: Duration(milliseconds: 800 + index * 20),
          child: GestureDetector(
            onTap: () {
              setState(() {
                servSelected = categoria;
              });
              Textfield().getRes(context, categoria['busqueda']);
              Future.delayed(const Duration(seconds: 3), () {
                if (!mounted) return;
                setState(() {
                  servSelected = {};
                });
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xffF7BD02),
              ),
              child: Center(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: size.width * 0.01),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Image.asset(
                        categoria['asset'],
                        height: size.height * 0.05,
                        color: servSelected['nombre'] == categoria['nombre']
                            ? Colors.white
                            : Colors.black,
                      ),
                      Text(
                        categoria['nombre'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: size.width * 0.027,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
