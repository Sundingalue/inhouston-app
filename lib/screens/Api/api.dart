import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Api {
  Future<List> getRes(String query, BuildContext context) async {
    loadingDialog(context);
    try {
      var response = await http.get(Uri.parse(
        'https://inhoustontexas.us/wp-json/wp/v2/servicio?_embed&search=$query&per_page=50',
      ));

      if (response.statusCode == 200) {
        List res = json.decode(utf8.decode(response.bodyBytes));
        if (Navigator.canPop(context)) Navigator.pop(context);

        // ✅ Si no hay resultados:
        if (res.isEmpty) {
          snackBarErrorSuccefull(
              context, 'No se encontraron resultados.', Colors.orange);
        }

        return res;
      } else {
        if (Navigator.canPop(context)) Navigator.pop(context);
        snackBarErrorSuccefull(
            context,
            'Error ${response.statusCode}: No se pudo obtener información.',
            Colors.red);
        return [];
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      snackBarErrorSuccefull(
          context, 'Error de conexión. Intenta de nuevo.', Colors.red);
      return [];
    }
  }

  loadingDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return const CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cargando'),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
  }

  void snackBarErrorSuccefull(BuildContext context, String txt, Color colorBg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colorBg,
        content: Text(
          txt,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
