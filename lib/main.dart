import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

// Pantallas existentes
import 'screens/splash_screen.dart';
import 'screens/agregar_empresa_screen.dart';
import 'screens/categorias_screen.dart';
import 'screens/navigator.sceen.dart';
import 'screens/empresas_por_categoria_screen.dart';
import 'screens/chat_login_screen.dart';

// ✅ NUEVOS IMPORTS (pantallas)
import 'screens/client_panel_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/instagram_screen.dart'; // 👈 IMPORT NUEVO

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación fija vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await EasyLocalization.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? languageCode = prefs.getString('language');
  final Locale startLocale = (languageCode != null && languageCode.isNotEmpty)
      ? Locale(languageCode)
      : const Locale('es');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await configurarNotificaciones();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'),
      startLocale: startLocale,
      child: const MyApp(),
    ),
  );
}

Future<void> configurarNotificaciones() async {
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 🔹 Al tocar la notificación
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload ?? '';
        if (payload.isNotEmpty) {
          final Uri uri = Uri.parse(payload);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
    );

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Token (opcional)
    final token = await messaging.getToken();
    // print('🔑 Token FCM: $token');

    await messaging.subscribeToTopic('todos');

    // ===== Foreground =====
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      final title = data['title'] ?? 'Notificación';
      final body = data['body'] ?? '';
      final url = data['url'] ?? '';

      flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: url, // 👈 guardamos la URL aquí
      );
    });

    // ===== Background / App cerrada =====
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      final data = message.data;

      // Caso 1: abrir URL
      final dynamicUrl = data['url'] ?? data['URL'] ?? data['link'] ?? data['Link'];
      if (dynamicUrl != null && dynamicUrl.toString().isNotEmpty) {
        final Uri uri = Uri.parse(dynamicUrl.toString());
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // Caso 2: abrir pantalla interna
      if (data['pantalla'] != null && data['pantalla'].toString().isNotEmpty) {
        final pantalla = data['pantalla'].toString();
        navigatorKey.currentState?.pushNamed(pantalla);
        return;
      }

      // Caso 3: empresa/categoría
      final empresaId = data['empresaId'];
      final categoria = data['categoria'];
      if (empresaId != null && categoria != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => EmpresasPorCategoriaScreen(
              categoria: categoria,
              empresaDestacada: empresaId,
            ),
          ),
        );
      }
    });
  } catch (e) {
    // print('❌ Error notificaciones: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'In Houston Nuevo',

      useInheritedMediaQuery: true,

      scrollBehavior: const _NoGlowScrollBehavior(),

      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const _NoGlowScrollBehavior(),
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: () {
              final currentFocus = FocusManager.instance.primaryFocus;
              if (currentFocus != null && !currentFocus.hasPrimaryFocus) {
                currentFocus.unfocus();
              }
            },
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/agregar': (context) => const AgregarEmpresaScreen(),
        '/categorias': (context) => const CategoriasScreen(),
        '/home': (context) => const BottomNavigatorScreen(),
        '/chat-login': (context) => const ChatLoginScreen(),
        '/client-panel': (context) => const ClientPanelScreen(),
        '/chat': (context) => const ChatScreen(),
        '/instagram': (context) => const InstagramScreen(), // ✅ NUEVA RUTA
      },
    );
  }
}

// ==== Utilidades UI ====
class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child; // sin glow
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // sin glow
  }
}
