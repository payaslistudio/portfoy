import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/money_formatter.dart';
import '../../services/settings_service.dart';
import '../../state/portfolio_controller.dart';

enum PlPeriod { w1, m1, m3, m6, y1, all }

extension PlPeriodX on PlPeriod {
  String get label => switch (this) {
        PlPeriod.w1 => '1 Hafta',
        PlPeriod.m1 => '1 Ay',
        PlPeriod.m3 => '3 Ay',
        PlPeriod.m6 => '6 Ay',
        PlPeriod.y1 => '1 Yıl',
        PlPeriod.all => 'Tümü',
      };

  Duration? get duration => switch (this) {
        PlPeriod.w1 => const Duration(days: 7),
        PlPeriod.m1 => const Duration(days: 30),
        PlPeriod.m3 => const Duration(days: 90),
        PlPeriod.m6 => const Duration(days: 180),
        PlPeriod.y1 => const Duration(days: 365),
        PlPeriod.all => null,
      };
}

class AnalizTab extends StatefulWidget {
  final PortfolioController controller;
  final SettingsService settings;
  const AnalizTab({
    super.key,
    required this.controller,
    required this.settings,
  });

  @override
  State<AnalizTab> createState() => _AnalizTabState();
}

class _AnalizTabState extends State<AnalizTab> {
  late MoneyFormatter _m =
      MoneyFormatter(widget.settings, widget.controller);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    widget.settings.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    widget.settings.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    setState(() => _m = MoneyFormatter(widget.settings, widget.controller));
  }

  Color _subtle([double a = 0.6]) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: a);

  ({double? pl, double? pct, DateTime? baseTime, bool haveData})
      _computeFor(PlPeriod p) {
    final c = widget.controller;
    if (c.snapshots.isEmpty) {
      return (pl: null, pct: null, baseTime: null, haveData: false);
    }
    final now = DateTime.now();
    double? base;
    DateTime? baseTime;
    if (p == PlPeriod.all) {
      base = c.snapshots.first.value;
      baseTime = c.snapshots.first.time;
    } else {
      final cutoff = now.subtract(p.duration!);
      base = c.valueAtOrBefore(cutoff);
      for (final s in c.snapshots) {
        if (!s.time.isAfter(cutoff)) baseTime = s.time;
      }
      if (base == null && c.snapshots.isNotEmpty) {
        base = c.snapshots.first.value;
        baseTime = c.snapshots.first.time;
      }
    }
    if (base == null) return (pl: null, pct: null, baseTime: null, haveData: false);
    final pl = c.totalValue - base;
    final pct = base == 0 ? null : (pl / base) * 100;
    return (pl: pl, pct: pct, baseTime: baseTime, haveData: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.assets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analiz')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.query_stats,
                    size: 72, color: _subtle(0.25)),
                const SizedBox(height: 16),
                Text('Henüz analiz edilecek varlık yok',
                    style: TextStyle(color: _subtle(0.7), fontSize: 16)),
                const SizedBox(height: 6),
                Text('Portföyüne varlık ekledikçe zaman içindeki '
                    'kar/zarar burada birikecek.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _subtle(0.4), fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Analiz')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Toplam Değer',
                      style: TextStyle(color: _subtle(0.6), fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(_m.fmt(c.totalValue),
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Toplam maliyet: ${_m.fmt(c.totalCost)}',
                      style: TextStyle(color: _subtle(0.5), fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text('Zaman Dilimlerinde Kar / Zarar',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600)),
          ),
          ...PlPeriod.values.map(_periodTile),
          const SizedBox(height: 16),
          if (c.snapshots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Zaman içindeki kar/zarar için yeterli veri henüz yok. '
                'Uygulamayı düzenli açtıkça geçmiş birikecek.',
                style: TextStyle(color: _subtle(0.5), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'İlk kayıt: ${DateFormat('dd.MM.yyyy HH:mm').format(c.snapshots.first.time)} '
                '• Toplam kayıt: ${c.snapshots.length}',
                style: TextStyle(color: _subtle(0.4), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _periodTile(PlPeriod p) {
    final r = _computeFor(p);
    final color = (r.pl ?? 0) >= 0
        ? const Color(0xFF66BB6A)
        : const Color(0xFFEF5350);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(p.label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: r.baseTime == null
            ? Text('—', style: TextStyle(color: _subtle(0.4)))
            : Text('Baz: ${DateFormat('dd.MM.yyyy').format(r.baseTime!)}',
                style: TextStyle(color: _subtle(0.4), fontSize: 11)),
        trailing: r.haveData
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(r.pl ?? 0) >= 0 ? '+' : ''}${_m.fmt(r.pl ?? 0)}',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w600, fontSize: 14)),
                  if (r.pct != null)
                    Text('${r.pct! >= 0 ? '+' : ''}${r.pct!.toStringAsFixed(2)}%',
                        style: TextStyle(color: color, fontSize: 12)),
                ],
              )
            : Text('veri yok',
                style: TextStyle(color: _subtle(0.4), fontSize: 11)),
      ),
    );
  }
}
