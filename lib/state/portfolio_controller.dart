import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../services/price_service.dart';
import '../services/storage_service.dart';

class Snapshot {
  final DateTime time;
  final double value;
  Snapshot(this.time, this.value);
  Map<String, dynamic> toJson() =>
      {'t': time.toIso8601String(), 'v': value};
  factory Snapshot.fromJson(Map<String, dynamic> j) =>
      Snapshot(DateTime.parse(j['t'] as String), (j['v'] as num).toDouble());
}

class PortfolioController extends ChangeNotifier {
  final PriceService priceService = PriceService();
  final StorageService _storage = StorageService();

  List<UserAsset> assets = [];
  Map<String, double> currentPrices = {}; // assetCode → TL/birim
  List<Snapshot> snapshots = [];
  bool loading = false;
  String? error;
  DateTime? lastUpdated;

  static const _snapKey = 'portfoy_snapshots_v1';

  Future<void> init() async {
    assets = await _storage.load();
    await _loadSnapshots();
    await refreshPrices();
  }

  Future<void> _loadSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snapKey);
    if (raw == null) return;
    final list = json.decode(raw) as List;
    snapshots = list
        .map((e) => Snapshot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    // Son ~400 giriş yeter (yıllık günlük ~365)
    if (snapshots.length > 400) {
      snapshots = snapshots.sublist(snapshots.length - 400);
    }
    await prefs.setString(
        _snapKey, json.encode(snapshots.map((s) => s.toJson()).toList()));
  }

  Future<void> _recordSnapshot() async {
    final now = DateTime.now();
    final v = totalValue;
    // Aynı gün içinde ilk snapshot dışında tekrar kaydetme; günün sonundaki değeri yakalamak için son değeri güncelle
    if (snapshots.isNotEmpty) {
      final last = snapshots.last;
      final sameDay = last.time.year == now.year &&
          last.time.month == now.month &&
          last.time.day == now.day;
      if (sameDay) {
        snapshots[snapshots.length - 1] = Snapshot(now, v);
        await _saveSnapshots();
        return;
      }
    }
    snapshots.add(Snapshot(now, v));
    await _saveSnapshots();
  }

  /// Belirli bir zaman ya da öncesindeki en yakın snapshot'un değerini döner.
  double? valueAtOrBefore(DateTime cutoff) {
    Snapshot? best;
    for (final s in snapshots) {
      if (!s.time.isAfter(cutoff)) {
        if (best == null || s.time.isAfter(best.time)) best = s;
      }
    }
    return best?.value;
  }

  Future<void> refreshPrices() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      currentPrices = await priceService.fetchTruncgil(force: true);
      // Kullanıcının eklediği BIST hisselerini de çek
      final stocks = assets.where((a) => a.category == AssetCategory.stock);
      for (final s in stocks) {
        final p = await priceService.fetchBistStock(s.assetCode);
        if (p != null) currentPrices[s.assetCode] = p;
      }
      // TEFAS fonları
      final funds = assets.where((a) => a.category == AssetCategory.fund);
      for (final f in funds) {
        final p = await priceService.fetchTefasFund(f.assetCode);
        if (p != null) currentPrices[f.assetCode] = p;
      }
      lastUpdated = DateTime.now();
      await _recordSnapshot();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  double priceOf(UserAsset a) => currentPrices[a.assetCode] ?? 0;

  double get totalValue =>
      assets.fold(0.0, (s, a) => s + a.currentValue(priceOf(a)));

  double get totalCost =>
      assets.fold(0.0, (s, a) => s + a.totalCost);

  double get totalPl => totalValue - totalCost;

  double get totalPlPct {
    if (totalCost == 0) return 0;
    return (totalPl / totalCost) * 100;
  }

  Future<void> addTransaction({
    required String assetCode,
    required AssetCategory category,
    required String displayName,
    required String unit,
    required double quantity,
    required double unitCost,
    required DateTime date,
    String? note,
  }) async {
    UserAsset? existing;
    for (final a in assets) {
      if (a.assetCode == assetCode) {
        existing = a;
        break;
      }
    }
    final tx = Transaction(
      quantity: quantity,
      unitCost: unitCost,
      date: date,
      note: note,
    );
    if (existing == null) {
      assets.add(UserAsset(
        assetCode: assetCode,
        category: category,
        displayName: displayName,
        unit: unit,
        transactions: [tx],
      ));
      if (category == AssetCategory.stock) {
        final p = await priceService.fetchBistStock(assetCode);
        if (p != null) currentPrices[assetCode] = p;
      } else if (category == AssetCategory.fund) {
        final p = await priceService.fetchTefasFund(assetCode);
        if (p != null) currentPrices[assetCode] = p;
      }
    } else {
      existing.transactions.add(tx);
    }
    await _storage.save(assets);
    notifyListeners();
  }

  Future<void> updateTransaction(
    UserAsset asset,
    String txId, {
    required double quantity,
    required double unitCost,
    required DateTime date,
    String? note,
  }) async {
    final idx = asset.transactions.indexWhere((t) => t.id == txId);
    if (idx == -1) return;
    asset.transactions[idx] = Transaction(
      id: txId,
      quantity: quantity,
      unitCost: unitCost,
      date: date,
      note: note,
    );
    await _storage.save(assets);
    notifyListeners();
  }

  Future<void> removeTransaction(UserAsset asset, String txId) async {
    asset.transactions.removeWhere((t) => t.id == txId);
    if (asset.transactions.isEmpty) {
      assets.remove(asset);
    }
    await _storage.save(assets);
    notifyListeners();
  }

  Future<void> removeAsset(UserAsset asset) async {
    assets.remove(asset);
    await _storage.save(assets);
    notifyListeners();
  }
}
