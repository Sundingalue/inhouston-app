import 'package:flutter/material.dart';
import 'package:inhouston_app/screens/detail_screen.dart';
import 'package:inhouston_app/widgets/utils.dart';
import 'package:animate_do/animate_do.dart';

class ResultScreen extends StatefulWidget {
  final List<Map> servicios;

  const ResultScreen({super.key, required this.servicios});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int cant = 0;
  int dif = 0;
  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          SizedBox(
            width: double.infinity,
            height: size.height,
            child: Image.asset(
              'assets/city.png',
              fit: BoxFit.cover,
            ),
          ),

          // 👉 Resultados y flecha alineados en una sola fila
          Positioned(
            top: size.height * 0.11, // Subido
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: const Color(0xFFF7BD02),
                      size: size.height * 0.04,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Resultados',
                        style: SafeGoogleFont(
                          'Inter',
                          fontSize: size.height * 0.04,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF7BD02),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 38), // Para equilibrar espacio derecho
                ],
              ),
            ),
          ),

          // 👉 Lista scrollable
          Padding(
            padding: EdgeInsets.only(top: size.height * 0.19), // Subido
            child: ListView(
              controller: controller,
              children: [
                Column(
                  children: List.generate(
                    widget.servicios.isEmpty
                        ? 1
                        : dif == 0
                            ? widget.servicios.length < 10
                                ? widget.servicios.length
                                : 10
                            : dif,
                    (index) {
                      final servicio = widget.servicios[
                          dif == 0 ? index + cant : index + cant + 10 - dif];

                      return BounceInUp(
                        duration: Duration(milliseconds: 400 + index * 100),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailScreen(servicio: servicio),
                            ),
                          ),
                          child: DetailCard(servicio: servicio),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 👉 Paginación
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (cant != 0) {
                          controller.animateTo(0.0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.linear);
                          if (dif != 0) {
                            setState(() {
                              cant = cant - dif;
                              dif = 0;
                            });
                          } else {
                            setState(() {
                              cant = cant - 10;
                            });
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.servicios.length < 10 ? widget.servicios.length : (cant + 10)} - ${widget.servicios.length}',
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        if ((cant + 10) < widget.servicios.length) {
                          controller.animateTo(0.0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.linear);
                          if (((cant + 20) - widget.servicios.length) < 10 &&
                              ((cant + 20) - widget.servicios.length) > 0) {
                            setState(() {
                              dif = widget.servicios.length - (cant + 10);
                              cant = widget.servicios.length - 10;
                            });
                          } else {
                            setState(() {
                              cant = cant + 10;
                            });
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailCard extends StatelessWidget {
  const DetailCard({super.key, required this.servicio});
  final Map servicio;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Container(
      margin: const EdgeInsets.all(10),
      width: size.width * 0.9,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: size.height * 0.4,
            width: double.infinity,
            decoration: BoxDecoration(
              image: servicio['imageUrl'] == 'assets'
                  ? const DecorationImage(
                      image: AssetImage('assets/noImage.png'),
                      fit: BoxFit.cover,
                    )
                  : DecorationImage(
                      image: NetworkImage(servicio['imageUrl']),
                      fit: BoxFit.fill,
                    ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  servicio['nombre'],
                  textAlign: TextAlign.center,
                  style: SafeGoogleFont(
                    'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF7BD02),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  width: 60,
                  color: const Color(0xFFF7BD02),
                ),
                const SizedBox(height: 8),
                Text(
                  servicio['tipo'],
                  style: SafeGoogleFont(
                    'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFF7BD02),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
