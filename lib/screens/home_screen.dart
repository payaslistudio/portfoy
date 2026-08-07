import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../state/portfolio_controller.dart';
import 'add_asset_screen.dart';
import 'asset_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final PortfolioController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _touchedIndex;
  final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  // Renk kategori bazında; aynı kategorideki varlıklar aynı renkte.
  static const Map<AssetCategory, Color> _categoryColors = {
    AssetCategory.gold: Color(0xFFFFB300),     // Emtia — amber
    AssetCategory.currency: Color(0xFF4FC3F7), // Döviz — mavi
    AssetCategory.stock: Color(0xFFBA68C8),    // Hisse — mor
    AssetCategory.fund: Color(0xFF81C784),     // Fon — yeşil
  };

  Color _colorFor(UserAsset a) =>
      _categoryColors[a.category] ?? const Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

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
          padding: const EdgeInsets.all(16),
          children: [
            _summaryCard(c),
            const SizedBox(height: 16),
            SizedBox(height: 260, child: _pieChart(c, totalValue)),
            const SizedBox(height: 16),
            if (c.assets.isEmpty)
              _emptyHint()
            else
              ...c.assets.map((a) => _assetTile(a, totalValue)),
            if (c.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Uyarı: ${c.error}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            if (c.lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Son güncelleme: ${DateFormat('dd.MM.yyyy HH:mm').format(c.lastUpdated!)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Varlık Ekle'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddAssetScreen(controller: c),
            ),
          );
        },
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
            const Text('Toplam Değer',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 6),
            Text(_tl.format(c.totalValue),
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _plBox('Maliyet', _tl.format(c.totalCost), Colors.white70),
                ),
                Expanded(
                  child: _plBox(
                      'Kar/Zarar',
                      '${pl >= 0 ? '+' : ''}${_tl.format(pl)}\n(${plPct.toStringAsFixed(2)}%)',
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
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _pieChart(PortfolioController c, double totalValue) {
    // Boş / henüz değer yok → sarı boş halka + 0 ₺
    if (c.assets.isEmpty || totalValue <= 0) {
      return Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: const Color(0xFFFFB300),
                  value: 1,
                  radius: 80,
                  showTitle: false,
                ),
              ],
              centerSpaceRadius: 55,
              sectionsSpace: 0,
              startDegreeOffset: -90,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Toplam',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text(_tl.format(0),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
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
        color: _colorFor(a),
        value: value,
        title: '${pct.toStringAsFixed(1)}%',
        radius: isTouched ? 95 : 80,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ));
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 55,
            sectionsSpace: 2,
            pieTouchData: PieTouchData(
              touchCallback: (event, resp) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      resp == null ||
                      resp.touchedSection == null) {
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
                  const Text('Toplam',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(_tl.format(totalValue),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
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
          Text(a.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          Text('${pct.toStringAsFixed(2)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(_tl.format(value),
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text('${pl >= 0 ? '+' : ''}${_tl.format(pl)}',
              style: TextStyle(
                  color: pl >= 0 ? Colors.greenAccent : Colors.redAccent,
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
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_tl.format(value),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${pl >= 0 ? '+' : ''}${plPct.toStringAsFixed(2)}%',
                style: TextStyle(
                    color: pl >= 0 ? Colors.greenAccent : Colors.redAccent,
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
      case AssetCategory.gold:
        return Icons.diamond_outlined;
      case AssetCategory.currency:
        return Icons.attach_money;
      case AssetCategory.stock:
        return Icons.show_chart;
      case AssetCategory.fund:
        return Icons.account_balance;
    }
  }

  Widget _emptyHint() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text('Henüz varlık eklemediniz',
                style: TextStyle(color: Colors.white60, fontSize: 15)),
            SizedBox(height: 4),
            Text('Sağ alttaki + butonundan başlayın',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
}
