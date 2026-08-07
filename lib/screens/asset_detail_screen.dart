import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../state/portfolio_controller.dart';

class AssetDetailScreen extends StatefulWidget {
  final PortfolioController controller;
  final UserAsset asset;
  const AssetDetailScreen({
    super.key,
    required this.controller,
    required this.asset,
  });

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  final _df = DateFormat('dd.MM.yyyy');

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
    final a = widget.asset;
    final c = widget.controller;
    final price = c.priceOf(a);
    final value = a.currentValue(price);
    final pl = a.profitLoss(price);
    final plPct = a.profitLossPct(price);
    final plColor = pl >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);

    return Scaffold(
      appBar: AppBar(
        title: Text(a.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Varlığı sil'),
                  content: Text(
                      '${a.displayName} varlığı ve tüm işlemleri silinecek. Emin misiniz?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Vazgeç')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sil')),
                  ],
                ),
              );
              if (ok == true) {
                await c.removeAsset(a);
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Güncel Birim Fiyat',
                      price > 0 ? _tl.format(price) : '—'),
                  _row('Toplam Miktar',
                      '${_fmtQty(a.totalQuantity)} ${a.unit}'),
                  _row('Ortalama Maliyet',
                      a.averageCost > 0 ? _tl.format(a.averageCost) : '—'),
                  _row('Toplam Maliyet', _tl.format(a.totalCost)),
                  _row('Güncel Değer', _tl.format(value)),
                  const Divider(),
                  _row(
                    'Kar / Zarar',
                    '${pl >= 0 ? '+' : ''}${_tl.format(pl)}  (${plPct.toStringAsFixed(2)}%)',
                    color: plColor,
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('İşlemler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          ...a.transactions.map((t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.add_shopping_cart),
                  title: Text(
                      '${_fmtQty(t.quantity)} ${a.unit} @ ${_tl.format(t.unitCost)}'),
                  subtitle: Text(
                      '${_df.format(t.date)}${t.note != null ? '  •  ${t.note}' : ''}\nToplam: ${_tl.format(t.totalCost)}'),
                  isThreeLine: t.note != null,
                  onTap: () => _openEditSheet(a, t),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: 'Düzenle',
                        onPressed: () => _openEditSheet(a, t),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Sil',
                        onPressed: () async {
                          final wasLast = a.transactions.length == 1;
                          await c.removeTransaction(a, t.id);
                          if (!mounted) return;
                          if (wasLast) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              )),
        ],
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

  Future<void> _openEditSheet(UserAsset a, Transaction t) async {
    final qty = TextEditingController(text: t.quantity.toString());
    final cost = TextEditingController(text: t.unitCost.toString());
    final note = TextEditingController(text: t.note ?? '');
    DateTime date = t.date;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('İşlemi Düzenle',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qty,
                    decoration: InputDecoration(
                      labelText: 'Miktar',
                      suffixText: a.unit,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (v) {
                      final d = double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (d == null || d <= 0) return 'Geçerli miktar girin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cost,
                    decoration: const InputDecoration(
                      labelText: 'Birim Maliyet (₺)',
                      prefixText: '₺ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (v) {
                      final d = double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (d == null || d <= 0) return 'Geçerli maliyet girin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setSt(() => date = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tarih',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(_df.format(date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: 'Not (opsiyonel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Kaydet'),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await widget.controller.updateTransaction(
                        a, t.id,
                        quantity: double.parse(qty.text.replaceAll(',', '.')),
                        unitCost: double.parse(cost.text.replaceAll(',', '.')),
                        date: date,
                        note: note.text.trim().isEmpty ? null : note.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(value,
                style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: bold ? 16 : 14,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      );
}
