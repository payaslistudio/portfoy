import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/asset.dart';
import '../../services/money_formatter.dart';
import '../../services/settings_service.dart';
import '../../state/portfolio_controller.dart';
import '../asset_detail_screen.dart';

class PortfolioTab extends StatefulWidget {
  final PortfolioController controller;
  final SettingsService settings;
  const PortfolioTab({
    super.key,
    required this.controller,
    required this.settings,
  });

  @override
  State<PortfolioTab> createState() => _PortfolioTabState();
}

class _PortfolioTabState extends State<PortfolioTab> {
  int? _touchedIndex;
  late MoneyFormatter _m =
      MoneyFormatter(widget.settings, widget.controller);

  static const Map<AssetCategory, Color> _categoryColors = {
    AssetCategory.gold: Color(0xFFFFB300),
    AssetCategory.currency: Color(0xFF4FC3F7),
    AssetCategory.stock: Color(0xFFBA68C8),
    AssetCategory.fund: Color(0xFF81C784),
  };

  Color _colorFor(UserAsset a) =>
      _categoryColors[a.category] ?? const Color(0xFF888888);

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

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final totalValue = c.totalValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portföyüm'),
        actions: [
          Tooltip(
            message: 'Fiyatları yenilemek için',
            child: IconButton(
              icon: c.loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              onPressed: c.loading ? null : () => c.refreshPrices(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => c.refreshPrices(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _summaryCard(c),
            const SizedBox(height: 16),
            SizedBox(height: 260, child: _pieChart(c, totalValue)),
            const SizedBox(height: 16),
            if (c.assets.isEmpty)
              _emptyHint()
            else
              ...c.assets.map((a) => _assetTile(a, totalValue)),
            if (c.lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Son güncelleme: ${DateFormat('dd.MM.yyyy HH:mm').format(c.lastUpdated!)}',
                  style: TextStyle(color: _subtle(0.4), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(PortfolioController c) {
    final pl = c.totalPl;
    final plPct = c.totalPlPct;
    final plColor = pl >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
    return Card(
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
                    fontSize: 30, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _plBox('Maliyet', _m.fmt(c.totalCost), _subtle(0.7)),
                ),
                Expanded(
                  child: _plBox(
                      'Kar/Zarar',
                      '${pl >= 0 ? '+' : ''}${_m.fmt(pl)}\n(${plPct.toStringAsFixed(2)}%)',
                      plColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _plBox(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: _subtle(0.5), fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _pieChart(PortfolioController c, double totalValue) {
    if (c.assets.isEmpty || totalValue <= 0) {
      return Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: const Color(0xFFFFB300),
                  value: 1, radius: 80, showTitle: false,
                ),
              ],
              centerSpaceRadius: 55, sectionsSpace: 0, startDegreeOffset: -90,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Toplam',
                  style: TextStyle(color: _subtle(0.5), fontSize: 12)),
              Text(_m.fmt(0),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      );
    }
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < c.assets.length; i++) {
      final a = c.assets[i];
      final value = a.currentValue(c.priceOf(a));
      if (value <= 0) continue;
      final pct = (value / totalValue) * 100;
      final isTouched = i == _touchedIndex;
      sections.add(PieChartSectionData(
        color: _colorFor(a), value: value,
        title: '${pct.toStringAsFixed(1)}%',
        radius: isTouched ? 95 : 80,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold, color: Colors.black87,
        ),
      ));
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sections: sections, centerSpaceRadius: 55, sectionsSpace: 2,
            pieTouchData: PieTouchData(
              touchCallback: (event, resp) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      resp == null || resp.touchedSection == null) {
                    _touchedIndex = null;
                    return;
                  }
                  _touchedIndex = resp.touchedSection!.touchedSectionIndex;
                });
              },
            ),
          ),
        ),
        _touchedIndex != null && _touchedIndex! < c.assets.length
            ? _centerInfo(c.assets[_touchedIndex!], c)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Toplam',
                      style: TextStyle(color: _subtle(0.5), fontSize: 12)),
                  Text(_m.fmt(totalValue),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
      ],
    );
  }

  Widget _centerInfo(UserAsset a, PortfolioController c) {
    final price = c.priceOf(a);
    final value = a.currentValue(price);
    final pct = c.totalValue == 0 ? 0.0 : (value / c.totalValue) * 100;
    final pl = a.profitLoss(price);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(a.displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          Text('${pct.toStringAsFixed(2)}%',
              style: TextStyle(color: _subtle(0.7), fontSize: 12)),
          Text(_m.fmt(value),
              style: const TextStyle(fontSize: 12)),
          Text('${pl >= 0 ? '+' : ''}${_m.fmt(pl)}',
              style: TextStyle(
                  color: pl >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _assetTile(UserAsset a, double totalValue) {
    final c = widget.controller;
    final price = c.priceOf(a);
    final value = a.currentValue(price);
    final pl = a.profitLoss(price);
    final plPct = a.profitLossPct(price);
    final share = totalValue == 0 ? 0.0 : (value / totalValue) * 100;
    final color = _colorFor(a);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(_iconFor(a.category), color: color, size: 20),
        ),
        title: Text(a.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${_fmtQty(a.totalQuantity)} ${a.unit}  •  ${share.toStringAsFixed(1)}%',
            style: TextStyle(color: _subtle(0.6), fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_m.fmt(value),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${pl >= 0 ? '+' : ''}${plPct.toStringAsFixed(2)}%',
                style: TextStyle(
                    color: pl >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                    fontSize: 12)),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetDetailScreen(controller: c, asset: a),
            ),
          );
        },
      ),
    );
  }

  String _fmtQty(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    var s = v.toStringAsFixed(4);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  IconData _iconFor(AssetCategory c) {
    switch (c) {
      case AssetCategory.gold: return Icons.diamond_outlined;
      case AssetCategory.currency: return Icons.attach_money;
      case AssetCategory.stock: return Icons.show_chart;
      case AssetCategory.fund: return Icons.account_balance;
    }
  }

  Widget _emptyHint() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text('Henüz varlık eklemediniz',
                style: TextStyle(color: _subtle(0.6), fontSize: 15)),
            const SizedBox(height: 4),
            Text('Aşağıdaki + butonundan başlayın',
                style: TextStyle(color: _subtle(0.4), fontSize: 12)),
          ],
        ),
      );
}
