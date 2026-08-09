import 'package:flutter/material.dart';
import 'package:inhouston_nuevo/widgets/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  void mostrarInformacionEmergente(
      String titulo, String descripcion, Uri url, String iconPath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(25.0),
          child: Wrap(
            children: [
              Center(
                child: Column(
                  children: [
                    Image.asset(iconPath, height: 48),
                    const SizedBox(height: 15),
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      descripcion,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xfff7bd02),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await launchUrl(url);
                      },
                      child: const Text(
                        'Ir ahora',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/city.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                    decoration: const BoxDecoration(
                      color: Color(0xfff7bd02),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 0),
                        const Text(
                          'CONTACTO',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 0),
                        Container(
                          width: 125,
                          height: 2,
                          color: Colors.black,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Selecciona el medio por el que deseas comunicarte.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 35),
                        Container(
                          height: 30,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 80,
                    right: 25,
                    child: Image.asset(
                      'assets/logo_in.png',
                      height: 45,
                      width: 60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: DatesContact(onShowModal: mostrarInformacionEmergente),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DatesContact extends StatelessWidget {
  final Function(String, String, Uri, String) onShowModal;

  const DatesContact({super.key, required this.onShowModal});

  @override
  Widget build(BuildContext context) {
    final contactos = [
      {
        'icon': 'assets/icon/whatsapp.png',
        'texto': 'Whatsapp',
        'url':  'https://wa.me/message/OTJGLK3LNP3SA1',
        'desc': 'Conéctate directamente con nosotros vía WhatsApp.'
      },
      {
        'icon': 'assets/icon/mailo.png',
        'texto': 'Correo',
        'url': 'mailto:info@inhoustontexas.us',
        'desc': 'Envía un correo directo con tus preguntas o propuestas.'
      },
      {
        'icon': 'assets/icon/sitio-web.png',
        'texto': 'Sitio Web',
        'url': 'https://www.inhoustontexas.us',
        'desc': 'Visita nuestro sitio web oficial para más información.'
      },
      {
        'icon': 'assets/icon/gps.png',
        'texto': 'Dirección',
        'url':
            'https://www.google.com/maps/place/11211 Katy Fwy #260, Houston, TX 77097',
        'desc': 'Encuentra nuestra ubicación en Google Maps.'
      },
      {
        'icon': 'assets/icon/instagram.png',
        'texto': 'Instagram',
        'url': 'https://www.instagram.com/inhoustontexas/',
        'desc': 'Síguenos en Instagram y descubre lo nuevo.'
      },
      {
        'icon': 'assets/icon/facebook.png',
        'texto': 'Facebook',
        'url': 'https://www.facebook.com/profile.php?id=61550851727719',
        'desc': 'Encuentra nuestras noticias y eventos en Facebook.'
      },
      {
        'icon': 'assets/icon/logotipo-de-linkedin.png',
        'texto': 'LinkedIn',
        'url': 'https://www.linkedin.com/company/in-houston-texas/',
        'desc': 'Conéctate con nosotros en LinkedIn de forma profesional.'
      },
    ];

    return Column(
      children: [
        const Divider(
          color: Colors.white,
          thickness: 0.8,
          indent: 10,
          endIndent: 10,
          height: 10,
        ),
        ...contactos.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              BounceInUp(
                duration: Duration(milliseconds: 800 + index * 80),
                child: GestureDetector(
                  onTap: () {
                    onShowModal(
                      item['texto']!,
                      item['desc']!,
                      Uri.parse(item['url']!),
                      item['icon']!,
                    );
                  },
                  child: InputData(
                    image: item['icon']!,
                    text2: item['texto']!,
                  ),
                ),
              ),
              const Divider(
                color: Colors.white,
                thickness: 0.8,
                indent: 10,
                endIndent: 10,
                height: 10,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}

class InputData extends StatelessWidget {
  const InputData({
    super.key,
    required this.image,
    required this.text2,
  });

  final String image;
  final String text2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 167, 167, 167).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(image, height: 28, color: Colors.white),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              text2,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }
}
