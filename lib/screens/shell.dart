import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../state/portfolio_controller.dart';
import 'add_asset_screen.dart';
import 'tabs/analiz_tab.dart';
import 'tabs/ayarlar_tab.dart';
import 'tabs/kurlar_tab.dart';
import 'tabs/portfolio_tab.dart';

/// Alt gezinme çubuklu ana kabuk. Merkez FAB "+ Ekle" için notch içerir.
class AppShell extends StatefulWidget {
  final PortfolioController controller;
  final SettingsService settings;
  const AppShell({
    super.key,
    required this.controller,
    required this.settings,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  late final List<Widget> _tabs = [
    PortfolioTab(controller: widget.controller, settings: widget.settings),
    AnalizTab(controller: widget.controller, settings: widget.settings),
    KurlarTab(controller: widget.controller),
    AyarlarTab(settings: widget.settings),
  ];

  Future<void> _openAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAssetScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: SizedBox(
        width: 62, height: 62,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFFFB300),
          foregroundColor: Colors.black,
          elevation: 6,
          shape: const CircleBorder(),
          onPressed: _openAdd,
          child: const Icon(Icons.add, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).cardColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 68,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navButton(0, Icons.pie_chart_outline_rounded, 'Portföy'),
            _navButton(1, Icons.analytics_outlined, 'Analiz'),
            const SizedBox(width: 60),
            _navButton(2, Icons.currency_exchange, 'Kurlar'),
            _navButton(3, Icons.settings_outlined, 'Ayarlar'),
          ],
        ),
      ),
    );
  }

  Widget _navButton(int idx, IconData icon, String label) {
    final selected = _index == idx;
    final color = selected
        ? const Color(0xFFFFB300)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
