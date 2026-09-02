import 'package:flutter/material.dart';

import 'services/database_service.dart';
import 'services/secure_storage_service.dart';
import 'services/theme_manager.dart';
import 'screens/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar base de datos local SQLite (0 ms cold start)
  await DatabaseService.instance.init();

  // Migración transparente de claves sensibles a almacenamiento cifrado
  await SecureStorageService.instance.migrateFromSharedPreferences();

  // Cargar preferencia de tema (Oscuro / Claro / Sistema)
  await ThemeManager.instance.loadTheme();

  runApp(const TrackerApp());
}

class TrackerApp extends StatelessWidget {
  const TrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Victor Engineer - Game Tracker',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeManager.instance.themeMode,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
