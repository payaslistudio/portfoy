import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/asset.dart';
import '../../state/portfolio_controller.dart';

/// Emtia + döviz canlı fiyatları.
class KurlarTab extends StatefulWidget {
  final PortfolioController controller;
  const KurlarTab({super.key, required this.controller});

  @override
  State<KurlarTab> createState() => _KurlarTabState();
}

class _KurlarTabState extends State<KurlarTab> {
  final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 4);

  // Emtia için renk paleti (sarı = altın türleri, gri = gümüş, açık gri = platin/paladyum, koyu = petrol)
  static const Map<String, Color> _commodityColors = {
    'GRAM_ALTIN': Color(0xFFFFB300),
    'CEYREK': Color(0xFFFFB300),
    'YARIM': Color(0xFFFFB300),
    'TAM': Color(0xFFFFB300),
    'CUMHURIYET': Color(0xFFFFB300),
    'ATA': Color(0xFFFFB300),
    'RESAT': Color(0xFFFFB300),
    'HAMIT': Color(0xFFFFB300),
    'ONS': Color(0xFFFFB300),
    'AYAR22': Color(0xFFFFB300),
    'AYAR18': Color(0xFFFFB300),
    'AYAR14': Color(0xFFFFB300),
    'GUMUS': Color(0xFFBDBDBD),
    'PLATIN': Color(0xFFE0E0E0),
    'PALADYUM': Color(0xFFCFD8DC),
    'BRENT': Color(0xFF546E7A),
  };

  static const Map<String, Color> _currencyColors = {
    'USD': Color(0xFF43A047),
    'EUR': Color(0xFF1E88E5),
    'GBP': Color(0xFF3949AB),
    'CHF': Color(0xFFE53935),
    'JPY': Color(0xFFE91E63),
    'CAD': Color(0xFFD84315),
    'AUD': Color(0xFF00897B),
    'SAR': Color(0xFF6D4C41),
    'RUB': Color(0xFF283593),
  };

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
    final commodities = AssetCatalog.byCategory(AssetCategory.gold);
    final currencies = AssetCatalog.byCategory(AssetCategory.currency)
        .where((d) => d.code != 'TRY')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Güncel Kurlar'),
        actions: [
          IconButton(
            icon: c.loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: 'Fiyatları yenile',
            onPressed: c.loading ? null : () => c.refreshPrices(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => c.refreshPrices(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _sectionTitle('Döviz'),
            const SizedBox(height: 8),
            ...currencies.map((d) => _row(
                  d,
                  _currencyColors[d.code] ?? const Color(0xFF78909C),
                )),
            const SizedBox(height: 20),
            _sectionTitle('Emtia'),
            const SizedBox(height: 8),
            ...commodities.map((d) => _row(
                  d,
                  _commodityColors[d.code] ?? const Color(0xFFFFB300),
                )),
            if (c.lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Son güncelleme: ${DateFormat('dd.MM.yyyy HH:mm').format(c.lastUpdated!)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(s,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      );

  Widget _row(AssetDefinition d, Color color) {
    final c = widget.controller;
    final price = c.currentPrices[d.code];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            d.category == AssetCategory.gold
                ? Icons.diamond_outlined
                : Icons.attach_money,
            color: color, size: 20,
          ),
        ),
        title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(d.code,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11)),
        trailing: Text(
          price == null ? '—' : _tl.format(price),
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
