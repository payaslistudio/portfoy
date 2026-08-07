import 'package:flutter/material.dart';
import 'state/portfolio_controller.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PortfoyApp());
}

class PortfoyApp extends StatefulWidget {
  const PortfoyApp({super.key});

  @override
  State<PortfoyApp> createState() => _PortfoyAppState();
}

class _PortfoyAppState extends State<PortfoyApp> {
  final controller = PortfolioController();

  @override
  void initState() {
    super.initState();
    controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portföy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
      ),
      home: HomeScreen(controller: controller),
    );
  }
}
