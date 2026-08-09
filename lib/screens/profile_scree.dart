// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inhouston_nuevo/screens/Api/api.dart';
import 'package:inhouston_nuevo/screens/Api/auth.dart';
import 'package:inhouston_nuevo/screens/loginn_screen.dart';
import 'package:inhouston_nuevo/widgets/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;

  const ProfileScreen({super.key, this.showBackButton = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double margin3 = 0;
  final ImagePicker picker = ImagePicker();
  String? newPhoto;
  XFile? photo;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final String nombre =
        myUserGlobal['nombre']?.split(" ")[0].toUpperCase() ?? '';
    final String apellido =
        myUserGlobal['apellido']?.split(" ")[0].toUpperCase() ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xfff7bd02),
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('assets/city.png'),
              ),
            ),
          ),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 23, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage: myUserGlobal['imageUrl'] != null
                            ? NetworkImage(myUserGlobal['imageUrl'])
                            : null,
                        child: myUserGlobal['imageUrl'] == null
                            ? const Icon(Icons.person,
                                color: Colors.grey, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      "HOLA $nombre",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Divider(
                        color: Color.fromARGB(221, 125, 125, 125),
                        thickness: 1),
                    const Text(
                      "Gracias por ser parte de nuestra comunidad.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => settingModalBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 49, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xfff7bd02),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 5),
                            Text("Cambiar foto"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: DatesProfile(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => customConfirmationModal(
                          context,
                          icon: Icons.save,
                          title: 'Guardar Cambios',
                          description:
                              '¿Deseas guardar los cambios realizados en tu perfil?',
                          onConfirm: () async {
                            setState(() {
                              margin3 =
                                  MediaQuery.of(context).size.height * 0.015;
                            });
                            WelcomeApi().actualizarDatosUsuario();
                            MessageHandler.showOkMessage(
                                context, 'Sus datos fueron actualizados');
                            Future.delayed(const Duration(milliseconds: 350),
                                () => setState(() => margin3 = 0));
                          },
                        ),
                        child: buildButton('Guardar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => customConfirmationModal(
                          context,
                          icon: Icons.logout,
                          title: 'Cerrar Sesión',
                          description: '¿Estás seguro que deseas salir?',
                          onConfirm: () async {
                            final prefs = await SharedPreferences.getInstance();

                            final remember =
                                prefs.getBool('remember_me') ?? false;
                            final savedEmail = prefs.getString('saved_email');
                            final savedPass = prefs.getString('saved_pass');
                            final usarFaceID =
                                prefs.getBool('usar_faceid') ?? false;

                            await prefs.clear();

                            if (remember) {
                              if (savedEmail != null) {
                                await prefs.setString(
                                    'saved_email', savedEmail);
                              }
                              if (savedPass != null) {
                                await prefs.setString('saved_pass', savedPass);
                              }
                              await prefs.setBool('remember_me', true);
                            }

                            await prefs.setBool('usar_faceid', usarFaceID);

                            WelcomeApi().cerrarSesion();
                            myUserGlobal = {};
                            Future.microtask(() {
                              Navigator.of(context).pushAndRemoveUntil(
                                rutaFadeIn(const LoginScreen()),
                                (route) => false,
                              );
                            });
                          },
                        ),
                        child: buildButton('Cerrar Sesión'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => customConfirmationModal(
                          context,
                          icon: Icons.delete,
                          title: 'Eliminar Cuenta',
                          description:
                              '¿Estás seguro que deseas eliminar tu cuenta? Esta acción no se puede deshacer.',
                          onConfirm: () async {
                            Api().loadingDialog(context);
                            final user = await FirebaseFirestore.instance
                                .collection('Users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .get();
                            try {
                              await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .delete();
                              await FirebaseAuth.instance.currentUser!.delete();
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.clear();
                              WelcomeApi().cerrarSesion();
                              myUserGlobal = {};
                              Future.microtask(() {
                                Navigator.of(context).pushAndRemoveUntil(
                                  rutaFadeIn(const LoginScreen()),
                                  (route) => false,
                                );
                              });
                            } catch (e) {
                              await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .set(user.data()!);
                              Navigator.pop(context);
                              Api().snackBarErrorSuccefull(
                                context,
                                'Inicie sesión nuevamente y vuelva a intentar eliminar su cuenta',
                                Colors.red,
                              );
                              Future.microtask(() {
                                Navigator.of(context).pushAndRemoveUntil(
                                  rutaFadeIn(const LoginScreen()),
                                  (route) => false,
                                );
                              });
                            }
                          },
                        ),
                        child: buildButton('Eliminar'),
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

  Widget buildButton(String text) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xfff7bd02),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void customConfirmationModal(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                      ),
                      child: const Text("Cancelar",
                          style: TextStyle(color: Colors.black)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xfff7bd02),
                      ),
                      child: const Text("Sí, continuar",
                          style: TextStyle(color: Colors.black)),
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                    ),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void settingModalBottomSheet(context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_search, size: 40, color: Colors.black54),
              const SizedBox(height: 10),
              const Text(
                'Selecciona una opción',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        pickPhoto();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.camera_alt, size: 40, color: Colors.black),
                          SizedBox(height: 8),
                          Text('Cámara'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        pickImage();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.photo_library,
                              size: 40, color: Colors.black),
                          SizedBox(height: 8),
                          Text('Galería'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future pickPhoto() async {
    photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    setState(() {
      newPhoto = photo!.path;
      uploadFile(newPhoto!);
    });
  }

  Future pickImage() async {
    photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo == null) return;
    setState(() {
      newPhoto = photo!.path;
      uploadFile(newPhoto!);
    });
  }

  Future<String> uploadFile(String pathh) async {
    final path = 'Perfil/${FirebaseAuth.instance.currentUser!.uid}/Foto_Perfil';
    final file = File(photo!.path);
    final ref = FirebaseStorage.instance.ref().child(path);
    UploadTask uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    final urlDownload = await snapshot.ref.getDownloadURL();
    final prefs = await SharedPreferences.getInstance();
    myUserGlobal.addAll({'imageUrl': urlDownload});
    prefs.setString('myData', json.encode(myUserGlobal));
    FirebaseFirestore.instance
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'imageUrl': urlDownload});
    setState(() {});
    return urlDownload;
  }
}

class DatesProfile extends StatelessWidget {
  const DatesProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          DataTextField(
            text: myUserGlobal['nombre'] ?? "",
            onChange: (value) => {myUserGlobal['nombre'] = value},
          ),
          const Divider(color: Colors.white54, thickness: 0.7),
          DataTextField(
            text: myUserGlobal['apellido'] ?? "",
            onChange: (value) => {myUserGlobal['apellido'] = value},
          ),
          const Divider(color: Colors.white54, thickness: 0.7),
          DataTextField(
            text: myUserGlobal['correo'],
            onChange: ((value) => {}),
            disabled: true,
          ),
          const Divider(color: Colors.white54, thickness: 0.7),
          DataTextField(
            text: myUserGlobal['telefono'] ?? "",
            onChange: (value) => {myUserGlobal['telefono'] = value},
          ),
          const Divider(color: Colors.white54, thickness: 0.7),
          DataTextField(
            text: myUserGlobal['ciudad'] ?? "",
            onChange: (value) => {myUserGlobal['ciudad'] = value},
          ),
          const Divider(color: Colors.white54, thickness: 0.7),
          DataTextField(
            text: myUserGlobal['estado'] ?? "",
            onChange: (value) => {myUserGlobal['estado'] = value},
          ),
        ],
      ),
    );
  }
}

class DataTextField extends StatefulWidget {
  final String text;
  final ValueChanged onChange;
  final bool disabled;

  const DataTextField({
    super.key,
    required this.text,
    required this.onChange,
    this.disabled = false,
  });

  @override
  _DataTextFieldState createState() => _DataTextFieldState();
}

class _DataTextFieldState extends State<DataTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xfff7bd02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        enabled: !widget.disabled,
        controller: _controller,
        onChanged: (value) {
          widget.onChange(value);
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class MessageHandler {
  static void showOkMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
