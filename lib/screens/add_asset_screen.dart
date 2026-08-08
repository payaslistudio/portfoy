import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/bist_symbols.dart';
import '../data/tefas_funds.dart';
import '../models/asset.dart';
import '../state/portfolio_controller.dart';

class AddAssetScreen extends StatefulWidget {
  final PortfolioController controller;
  const AddAssetScreen({super.key, required this.controller});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  AssetCategory _category = AssetCategory.gold;
  AssetDefinition? _selectedDef;
  final _stockCtrl = TextEditingController();
  final _fundCtrl = TextEditingController();
  Map<String, ({double price, String name})> _tefasCatalog = {};
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDef = AssetCatalog.byCategory(_category).first;
    _loadTefasCatalog();
  }

  Future<void> _loadTefasCatalog() async {
    try {
      final c = await widget.controller.priceService.fetchFundCatalog();
      if (mounted) setState(() => _tefasCatalog = c);
    } catch (_) {}
  }

  @override
  void dispose() {
    _stockCtrl.dispose();
    _fundCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _currentUnit {
    switch (_category) {
      case AssetCategory.stock:
        return 'lot';
      case AssetCategory.fund:
        return 'pay';
      case AssetCategory.currency:
      case AssetCategory.gold:
        return _selectedDef?.unit ?? '';
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    String code;
    String name;
    String unit;
    AssetCategory cat = _category;

    if (_category == AssetCategory.stock) {
      code = _stockCtrl.text.trim().toUpperCase();
      name = 'BIST: $code';
      unit = 'lot';
    } else if (_category == AssetCategory.fund) {
      code = _fundCtrl.text.trim().toUpperCase();
      final fname = kTefasFunds[code];
      name = 'Fon: $code${fname != null ? ' — $fname' : ''}';
      unit = 'pay';
    } else {
      code = _selectedDef!.code;
      name = _selectedDef!.name;
      unit = _selectedDef!.unit;
    }

    // Maliyet boşsa güncel fiyatı kullan
    double? unitCost = double.tryParse(_costCtrl.text.replaceAll(',', '.'));
    if (unitCost == null || unitCost <= 0) {
      final svc = widget.controller.priceService;
      // 1) Cache
      unitCost = widget.controller.currentPrices[code];
      // 2) Altın / döviz için Truncgil'i yenile
      if ((unitCost == null || unitCost <= 0) &&
          cat != AssetCategory.stock) {
        try {
          final fresh = await svc.fetchTruncgil(force: true);
          unitCost = fresh[code];
          widget.controller.currentPrices.addAll(fresh);
        } catch (_) {}
      }
      // 3) BIST hissesi için Yahoo'dan çek
      if ((unitCost == null || unitCost <= 0) &&
          cat == AssetCategory.stock) {
        unitCost = await svc.fetchBistStock(code);
        if (unitCost != null) {
          widget.controller.currentPrices[code] = unitCost;
        }
      }
      // 4) TEFAS fonu
      if ((unitCost == null || unitCost <= 0) &&
          cat == AssetCategory.fund) {
        unitCost = await svc.fetchTefasFund(code);
        if (unitCost != null) {
          widget.controller.currentPrices[code] = unitCost;
        }
      }
      if (unitCost == null || unitCost <= 0) {
        if (!mounted) return;
        setState(() => _saving = false);
        final msg = cat == AssetCategory.fund
            ? 'TEFAS fon fiyatı otomatik alınamıyor (kaynak API şu an bloklu). Lütfen fon pay fiyatını elle girin.'
            : 'Güncel fiyat alınamadı. İnternet bağlantınızı kontrol edin ya da maliyeti elle girin.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
        );
        return;
      }
    }

    await widget.controller.addTransaction(
      assetCode: code,
      category: cat,
      displayName: name,
      unit: unit,
      quantity: double.parse(_qtyCtrl.text.replaceAll(',', '.')),
      unitCost: unitCost,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Varlık Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Kategori', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 8),
            SegmentedButton<AssetCategory>(
              segments: const [
                ButtonSegment(
                    value: AssetCategory.gold,
                    label: Text('Emtia'),
                    icon: Icon(Icons.diamond_outlined)),
                ButtonSegment(
                    value: AssetCategory.currency,
                    label: Text('Döviz'),
                    icon: Icon(Icons.attach_money)),
                ButtonSegment(
                    value: AssetCategory.stock,
                    label: Text('Hisse'),
                    icon: Icon(Icons.show_chart)),
                ButtonSegment(
                    value: AssetCategory.fund,
                    label: Text('Fon'),
                    icon: Icon(Icons.account_balance)),
              ],
              selected: {_category},
              onSelectionChanged: (s) {
                setState(() {
                  _category = s.first;
                  if (_category != AssetCategory.stock &&
                      _category != AssetCategory.fund) {
                    _selectedDef = AssetCatalog.byCategory(_category).first;
                  }
                  _costCtrl.clear();
                });
              },
            ),
            const SizedBox(height: 20),
            if (_category == AssetCategory.fund)
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  final q = value.text.trim().toUpperCase();
                  if (q.isEmpty) return const Iterable<String>.empty();
                  // Öncelik: canlı TEFAS kataloğu (1300+ fon).
                  // Yoksa fallback olarak yerleşik kısa liste.
                  final src = _tefasCatalog.isNotEmpty ? _tefasCatalog : null;
                  if (src != null) {
                    return src.entries
                        .where((e) =>
                            e.key.startsWith(q) ||
                            e.value.name.toUpperCase().contains(q))
                        .take(25)
                        .map((e) => e.key);
                  }
                  return kTefasFunds.entries
                      .where((e) =>
                          e.key.startsWith(q) ||
                          e.value.toUpperCase().contains(q))
                      .take(20)
                      .map((e) => e.key);
                },
                displayStringForOption: (s) => s,
                onSelected: (s) => _fundCtrl.text = s,
                fieldViewBuilder: (context, textCtrl, focus, onSubmit) {
                  if (textCtrl.text != _fundCtrl.text) {
                    textCtrl.text = _fundCtrl.text;
                  }
                  textCtrl.addListener(() {
                    if (_fundCtrl.text != textCtrl.text) {
                      _fundCtrl.text = textCtrl.text;
                    }
                  });
                  return TextFormField(
                    controller: textCtrl,
                    focusNode: focus,
                    decoration: const InputDecoration(
                      labelText: 'TEFAS Fon Kodu',
                      hintText: 'Yazmaya başla: A, YAC, TI2…',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Fon kodu girin' : null,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      color: const Color(0xFF1F242E),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxHeight: 260, maxWidth: 380),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, i) {
                            final code = options.elementAt(i);
                            final name = _tefasCatalog[code]?.name
                                ?? kTefasFunds[code] ?? '';
                            return ListTile(
                              dense: true,
                              title: Text(code,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                              onTap: () => onSelected(code),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              )
            else if (_category == AssetCategory.stock)
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  final q = value.text.trim().toUpperCase();
                  if (q.isEmpty) return const Iterable<String>.empty();
                  return kBistSymbols.entries
                      .where((e) =>
                          e.key.startsWith(q) ||
                          e.value.toUpperCase().contains(q))
                      .take(20)
                      .map((e) => e.key);
                },
                displayStringForOption: (s) => s,
                onSelected: (s) => _stockCtrl.text = s,
                fieldViewBuilder: (context, textCtrl, focus, onSubmit) {
                  // Sync dış controller ile
                  if (textCtrl.text != _stockCtrl.text) {
                    textCtrl.text = _stockCtrl.text;
                  }
                  textCtrl.addListener(() {
                    if (_stockCtrl.text != textCtrl.text) {
                      _stockCtrl.text = textCtrl.text;
                    }
                  });
                  return TextFormField(
                    controller: textCtrl,
                    focusNode: focus,
                    decoration: const InputDecoration(
                      labelText: 'BIST Sembolü',
                      hintText: 'Yazmaya başla: T, THY, ASELS…',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Sembol girin' : null,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      color: const Color(0xFF1F242E),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxHeight: 260, maxWidth: 380),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, i) {
                            final code = options.elementAt(i);
                            final name = kBistSymbols[code] ?? '';
                            return ListTile(
                              dense: true,
                              title: Text(code,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(name,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                              onTap: () => onSelected(code),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              DropdownButtonFormField<AssetDefinition>(
                initialValue: _selectedDef,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Varlık',
                  border: OutlineInputBorder(),
                ),
                items: AssetCatalog.byCategory(_category)
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d.name),
                        ))
                    .toList(),
                onChanged: (d) {
                  setState(() {
                    _selectedDef = d;
                    _costCtrl.clear();
                  });
                },
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _qtyCtrl,
              decoration: InputDecoration(
                labelText: 'Miktar',
                suffixText: _currentUnit,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _costCtrl,
              decoration: const InputDecoration(
                labelText: 'Birim Maliyet (₺) — opsiyonel',
                hintText: 'Boş bırakılırsa güncel fiyat kullanılır',
                border: OutlineInputBorder(),
                prefixText: '₺ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final d = double.tryParse(v.replaceAll(',', '.'));
                if (d == null || d <= 0) return 'Geçerli maliyet girin';
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Alım Tarihi',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('dd.MM.yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: const Text('Kaydet'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
