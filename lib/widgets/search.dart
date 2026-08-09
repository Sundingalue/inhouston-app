import 'package:flutter/material.dart';
import 'package:inhouston_nuevo/screens/Api/api.dart';
import 'package:inhouston_nuevo/screens/results_screen.dart';
import 'package:inhouston_nuevo/widgets/utils.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class Textfield extends StatelessWidget {
  final double? customHeight;
  final double? customWidth;

  Textfield({
    super.key,
    this.customHeight,
    this.customWidth,
  });

  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      height: customHeight ?? size.height * 0.07,
      width: customWidth ?? size.width * 0.9,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        textAlignVertical: TextAlignVertical.top,
        onSubmitted: (value) async {
          getRes(context, controller.text);
        },
        decoration: InputDecoration(
          hintText: 'Buscar Servicios...',
          hintStyle: const TextStyle(color: Color.fromARGB(255, 96, 96, 96)),
          filled: true,
          fillColor: Colors.black,
          suffixIcon: GestureDetector(
            onTap: () async {
              getRes(context, controller.text);
            },
            child: const Icon(Icons.search,
                color: Color.fromARGB(255, 255, 207, 64)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(
                color: Color.fromARGB(255, 144, 15, 15), width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.white, width: 0),
          ),
        ),
      ),
    );
  }

  getRes(BuildContext context, String query) async {
    if (query.isNotEmpty) {
      final res = await Api().getRes(query.replaceAll("'", "&#8217;"), context);
      if (res.isEmpty) {
        Api().snackBarErrorSuccefull(
            context, 'No se encontraron resultados', Colors.red);
      } else {
        List<Map> servicios = [];
        for (var servicio in res) {
          String igAt = "https://www.instagram.com/inhoustontexas";
          RegExp regExp = RegExp(
              r'(https?:\/\/(www\.)?instagram\.com\/[A-Za-z0-9._%-]+\/?)',
              caseSensitive: false);
          Match? match =
              regExp.firstMatch(servicio['content']['rendered'].toString());
          if (match != null) {
            igAt = match.group(1)!.trim();
          }

          List<String> parts =
              servicio['content']['rendered'].toString().split('</strong>');

          servicios.add({
            'imageUrl': servicio['_embedded']['wp:featuredmedia'] == null
                ? 'assets'
                : servicio['_embedded']['wp:featuredmedia'][0]['media_details']
                    ['sizes']['full']['source_url'],
            'nombre': parts.length > 1
                ? parts[1]
                    .split('<')[0]
                    .replaceAll('&#8217;', "'")
                    .replaceAll('&nbsp;', "")
                    .replaceAll('&amp;', "&")
                    .replaceAll('&#8211;', "-")
                : 'Nombre no disponible',
            'tipo': parts.length > 2
                ? parts[2]
                    .split('<')[0]
                    .replaceAll('&#8217;', "'")
                    .replaceAll('&nbsp;', "")
                    .replaceAll('&amp;', "&")
                    .replaceAll('&#8211;', "-")
                : 'Tipo no disponible',
            'telefono': parts.length > 3
                ? (parts[3].split('<')[1][0] != 'a'
                    ? parts[3]
                        .split('<')[0]
                        .replaceAll('&#8217;', "'")
                        .replaceAll('&nbsp;', "")
                        .replaceAll('&amp;', "&")
                        .replaceAll('&#8211;', "-")
                    : parts[3]
                        .split('<')[1]
                        .split('>')[1]
                        .replaceAll('&#8217;', "'")
                        .replaceAll('&nbsp;', "")
                        .replaceAll('&amp;', "&")
                        .replaceAll('&#8211;', "-"))
                : 'Teléfono no disponible',
            'direccion': parts.length > 4
                ? parts[4]
                    .split('<')[0]
                    .replaceAll('&#8217;', "'")
                    .replaceAll('&nbsp;', "")
                    .replaceAll('&amp;', "&")
                    .replaceAll('&#8211;', "-")
                : 'Dirección no disponible',
            'instagram': igAt,
          });
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(servicios: servicios),
          ),
        );
      }
    }
  }
}

class TextfieldS extends StatefulWidget {
  final String text;
  final ValueChanged changed;
  final String initialValue;
  final TextEditingController? controller;

  const TextfieldS({
    super.key,
    required this.text,
    required this.changed,
    this.initialValue = '',
    this.controller,
  });

  @override
  State<TextfieldS> createState() => _TextfieldSState();
}

class _TextfieldSState extends State<TextfieldS> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: SafeGoogleFont('Inter',
              fontSize: 17, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        TextField(
          controller: _controller,
          onChanged: widget.changed,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white, width: 0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white, width: 0),
            ),
          ),
        ),
      ],
    );
  }
}

class TextfieldPassword extends StatefulWidget {
  final String text;
  final ValueChanged changed;
  final String initialValue;
  final TextEditingController? controller;

  const TextfieldPassword({
    super.key,
    required this.text,
    required this.changed,
    this.initialValue = '',
    this.controller,
  });

  @override
  State<TextfieldPassword> createState() => _TextfieldPasswordState();
}

class _TextfieldPasswordState extends State<TextfieldPassword> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: SafeGoogleFont('Inter',
              fontSize: 17, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        TextField(
          controller: _controller,
          obscureText: true,
          onChanged: widget.changed,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
            ),
          ),
        ),
      ],
    );
  }
}

class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.text,
    required this.changed,
  });

  final String text;
  final ValueChanged changed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: SafeGoogleFont('Inter',
              fontSize: 17, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        IntlPhoneField(
          onChanged: (value) {
            changed(value.completeNumber);
          },
          decoration: InputDecoration(
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
            ),
            filled: true,
            labelStyle: SafeGoogleFont(
              'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: const Color(0xffffffff),
            ),
          ),
        ),
      ],
    );
  }
}

class InicioSesion extends StatelessWidget {
  const InicioSesion({
    super.key,
    required this.text1,
    required this.text2,
    required this.callback,
  });

  final String text1, text2;
  final VoidCallback callback;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text1,
          style: const TextStyle(
              fontSize: 15, color: Color.fromARGB(255, 148, 31, 31)),
        ),
        GestureDetector(
          child: Text(
            text2,
            style: const TextStyle(
              color: Color(0xfff7bd02),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          onTap: callback,
        )
      ],
    );
  }
}
