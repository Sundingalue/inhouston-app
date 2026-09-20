import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Necesario para usar MethodChannel
import 'package:inhouston_app/screens/information_screen.dart';
import 'package:inhouston_app/widgets/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';

class DetailScreen extends StatefulWidget {
  final Map servicio;

  const DetailScreen({super.key, required this.servicio});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  double margin = 0;
  double shareBtn = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/city.png', fit: BoxFit.cover),
          ),
          ListView(
            padding: const EdgeInsets.only(top: 70),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFFFFC402),
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Detail(image: widget.servicio['imageUrl']),
              ),
              const SizedBox(height: 10),
              FadeInUp(
                duration: const Duration(milliseconds: 700),
                child: DatesContactT(data: widget.servicio),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 100),
                      child: _buildButton(
                        label: 'Contactar',
                        onTap: () {
                          setState(() => margin = size.height * 0.015);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InformationScreen(
                                info: widget.servicio,
                              ),
                            ),
                          );
                          Future.delayed(const Duration(seconds: 1), () {
                            if (!mounted) return;
                            setState(() => margin = 0);
                          });
                        },
                        bottomMargin: margin,
                      ),
                    ),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 200),
                      child: _buildButton(
                        label: 'Compartir',
                        onTap: () {
                          compartirContacto(context, widget.servicio);
                        },
                        bottomMargin: shareBtn,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onTap,
    required double bottomMargin,
    double height = 48,
    double width = 162,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7BD02),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Center(
            child: AnimatedContainer(
              margin: EdgeInsets.only(bottom: bottomMargin),
              duration: const Duration(milliseconds: 300),
              child: Text(
                label,
                style: SafeGoogleFont(
                  'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Detail extends StatelessWidget {
  final String image;

  const Detail({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      height: size.height * 0.37,
      decoration: BoxDecoration(
        image: image == 'assets'
            ? const DecorationImage(
                image: AssetImage('assets/noImage.png'), fit: BoxFit.fill)
            : DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class DatesContactT extends StatelessWidget {
  final Map data;

  const DatesContactT({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        width: size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                data['nombre'],
                textAlign: TextAlign.center,
                style: SafeGoogleFont(
                  'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _txt('Nombre: ', '${data['nombre']}'),
            _txt('Categoría: ', '${data['tipo']}'),
            GestureDetector(
              onTap: () => launchUrl(Uri(scheme: 'tel', path: data['telefono'])),
              child: _txt('Teléfono: ', '${data['telefono']}'),
            ),
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse('https://www.google.com/maps/place/${data['direccion']}'),
              ),
              child: _txt('Dirección: ', '${data['direccion']}'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse('${data['instagram']}')),
                child: const InputData(
                  image: 'assets/icon/instagram.png',
                  text2: 'Instagram',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  RichText _txt(String label, String value) {
    return RichText(
      text: TextSpan(
        style: SafeGoogleFont('Inter', fontSize: 14, color: Colors.white),
        children: [
          TextSpan(
            text: label,
            style: SafeGoogleFont(
              'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          TextSpan(text: value, style: const TextStyle(height: 1.7)),
        ],
      ),
    );
  }
}

class InputData extends StatelessWidget {
  final String image;
  final String text2;

  const InputData({super.key, required this.image, required this.text2});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width * 0.7,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7BD02),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.only(top: 5, bottom: 5, left: 75),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(image,
              color: const Color.fromARGB(255, 15, 15, 15), height: 22),
          const SizedBox(width: 10),
          Text(
            text2,
            style: SafeGoogleFont(
              'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color.fromARGB(255, 24, 24, 24),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Función para abrir el menú nativo de compartir en iPhone
void compartirContacto(BuildContext context, Map servicio) async {
  const platform = MethodChannel('com.inhouston.share');

  final mensaje = 
    'Hola, te comparto un contacto de IN Houston Texas:\n\n'
    '📌 Nombre: ${servicio['nombre']}\n'
    '📂 Categoría: ${servicio['tipo']}\n'
    '📞 Teléfono: ${servicio['telefono']}\n'
    '📍 Dirección: ${servicio['direccion']}\n';

  try {
    await platform.invokeMethod('shareText', {"text": mensaje});
  } on PlatformException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al compartir: ${e.message}')),
    );
  }
}
