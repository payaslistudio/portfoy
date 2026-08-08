import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'state/portfolio_controller.dart';
import 'screens/shell.dart';

/// Uygulama boyunca tek örnek ayarlar servisi.
final settings = SettingsService();

void main() {
  runApp(const YatirimCuzdaniApp());
}

class YatirimCuzdaniApp extends StatefulWidget {
  const YatirimCuzdaniApp({super.key});

  @override
  State<YatirimCuzdaniApp> createState() => _YatirimCuzdaniAppState();
}

class _YatirimCuzdaniAppState extends State<YatirimCuzdaniApp> {
  final controller = PortfolioController();

  @override
  void initState() {
    super.initState();
    settings.load();
    controller.init();
    settings.addListener(_onSettings);
  }

  @override
  void dispose() {
    settings.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() => setState(() {});

  ThemeData _darkTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB300),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0E1116),
        cardTheme: const CardThemeData(
          color: Color(0xFF161A22),
          elevation: 0,
        ),
      );

  ThemeData _lightTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB300),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Varlık Cüzdanı',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: AppShell(controller: controller, settings: settings),
    );
  }
}
