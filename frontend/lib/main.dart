import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/dashboard.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Archivo .env no encontrado");
  }

  final String url = dotenv.env['SUPABASE_URL'] ?? '';
  final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (url.isEmpty || anonKey.isEmpty) {
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "❌ Error de Configuración:\nFaltan las claves de Supabase en el archivo .env.\n\nAsegúrate de que el APK fue compilado con los secretos correctos en GitHub.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ),
      ),
    ));
    return;
  }
  
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  runApp(const TrackerApp());
}

class TrackerApp extends StatelessWidget {
  const TrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchar el estado de autenticación en la raíz para saltar el login automáticamente.
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Game Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF38BDF8),
          secondary: const Color(0xFF818CF8),
          surface: const Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: session != null ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
