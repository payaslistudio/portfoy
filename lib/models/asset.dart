import 'package:uuid/uuid.dart';

enum AssetCategory { gold, currency, stock, fund }

class AssetDefinition {
  final String code;
  final String name;
  final AssetCategory category;
  final String unit;

  const AssetDefinition({
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
  });
}

class AssetCatalog {
  static const List<AssetDefinition> all = [
    // ALTIN
    AssetDefinition(code: 'GRAM_ALTIN', name: 'Gram Altın', category: AssetCategory.gold, unit: 'gram'),
    AssetDefinition(code: 'CEYREK', name: 'Çeyrek Altın', category: AssetCategory.gold, unit: 'adet'),
    AssetDefinition(code: 'YARIM', name: 'Yarım Altın', category: AssetCategory.gold, unit: 'adet'),
    AssetDefinition(code: 'TAM', name: 'Tam Altın', category: AssetCategory.gold, unit: 'adet'),
    AssetDefinition(code: 'CUMHURIYET', name: 'Cumhuriyet Altını', category: AssetCategory.gold, unit: 'adet'),
    AssetDefinition(code: 'ATA', name: 'Ata Altın', category: AssetCategory.gold, unit: 'adet'),
    AssetDefinition(code: 'RESAT', name: 'Reşat Altını', category: AssetCategory.gold, unit: 'adet'),
    AssetDefinition(code: 'HAMIT', name: 'Hamit Altını', category: AssetCategory.gold, unit: 'adet'),
    AssetDefinition(code: 'ONS', name: 'Ons Altın (USD)', category: AssetCategory.gold, unit: 'ons'),
    AssetDefinition(code: 'AYAR22', name: '22 Ayar Bilezik', category: AssetCategory.gold, unit: 'gram'),
    AssetDefinition(code: 'AYAR18', name: '18 Ayar Altın', category: AssetCategory.gold, unit: 'gram'),
    AssetDefinition(code: 'AYAR14', name: '14 Ayar Altın', category: AssetCategory.gold, unit: 'gram'),
    AssetDefinition(code: 'GUMUS', name: 'Gümüş (Gram)', category: AssetCategory.gold, unit: 'gram'),
    AssetDefinition(code: 'PLATIN', name: 'Platin (Gram)', category: AssetCategory.gold, unit: 'gram'),
    AssetDefinition(code: 'PALADYUM', name: 'Paladyum (Gram)', category: AssetCategory.gold, unit: 'gram'),
    AssetDefinition(code: 'BRENT', name: 'Brent Petrol (Varil)', category: AssetCategory.gold, unit: 'varil'),
    // DÖVİZ
    AssetDefinition(code: 'USD', name: 'Amerikan Doları', category: AssetCategory.currency, unit: 'USD'),
    AssetDefinition(code: 'EUR', name: 'Euro', category: AssetCategory.currency, unit: 'EUR'),
    AssetDefinition(code: 'GBP', name: 'İngiliz Sterlini', category: AssetCategory.currency, unit: 'GBP'),
    AssetDefinition(code: 'CHF', name: 'İsviçre Frangı', category: AssetCategory.currency, unit: 'CHF'),
    AssetDefinition(code: 'JPY', name: 'Japon Yeni', category: AssetCategory.currency, unit: 'JPY'),
    AssetDefinition(code: 'CAD', name: 'Kanada Doları', category: AssetCategory.currency, unit: 'CAD'),
    AssetDefinition(code: 'AUD', name: 'Avustralya Doları', category: AssetCategory.currency, unit: 'AUD'),
    AssetDefinition(code: 'SAR', name: 'Suudi Riyali', category: AssetCategory.currency, unit: 'SAR'),
    AssetDefinition(code: 'RUB', name: 'Rus Rublesi', category: AssetCategory.currency, unit: 'RUB'),
    AssetDefinition(code: 'TRY', name: 'Türk Lirası (Nakit)', category: AssetCategory.currency, unit: 'TRY'),
  ];

  static AssetDefinition? byCode(String code) {
    for (final a in all) {
      if (a.code == code) return a;
    }
    return null;
  }

  static List<AssetDefinition> byCategory(AssetCategory c) =>
      all.where((a) => a.category == c).toList();
}

class Transaction {
  final String id;
  final double quantity;
  final double unitCost; // TL cinsinden birim maliyet
  final DateTime date;
  final String? note;

  Transaction({
    String? id,
    required this.quantity,
    required this.unitCost,
    required this.date,
    this.note,
  }) : id = id ?? const Uuid().v4();

  double get totalCost => quantity * unitCost;

  Map<String, dynamic> toJson() => {
        'id': id,
        'quantity': quantity,
        'unitCost': unitCost,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] as String?,
        quantity: (j['quantity'] as num).toDouble(),
        unitCost: (j['unitCost'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String),
        note: j['note'] as String?,
      );
}

/// BIST hissesi gibi katalog dışı varlıklar için kullanıcı tanımlı sembol.
class UserAsset {
  final String assetCode; // Katalog kodu VEYA BIST sembolü (örn. THYAO)
  final AssetCategory category;
  final String displayName;
  final String unit;
  final List<Transaction> transactions;

  UserAsset({
    required this.assetCode,
    required this.category,
    required this.displayName,
    required this.unit,
    List<Transaction>? transactions,
  }) : transactions = transactions ?? [];

  double get totalQuantity =>
      transactions.fold(0.0, (s, t) => s + t.quantity);

  double get totalCost =>
      transactions.fold(0.0, (s, t) => s + t.totalCost);

  double get averageCost =>
      totalQuantity == 0 ? 0 : totalCost / totalQuantity;

  double currentValue(double currentUnitPrice) =>
      totalQuantity * currentUnitPrice;

  double profitLoss(double currentUnitPrice) =>
      currentValue(currentUnitPrice) - totalCost;

  double profitLossPct(double currentUnitPrice) {
    if (totalCost == 0) return 0;
    return (profitLoss(currentUnitPrice) / totalCost) * 100;
  }

  Map<String, dynamic> toJson() => {
        'assetCode': assetCode,
        'category': category.name,
        'displayName': displayName,
        'unit': unit,
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory UserAsset.fromJson(Map<String, dynamic> j) => UserAsset(
        assetCode: j['assetCode'] as String,
        category: AssetCategory.values.firstWhere(
          (c) => c.name == j['category'],
          orElse: () => AssetCategory.gold,
        ),
        displayName: j['displayName'] as String,
        unit: j['unit'] as String,
        transactions: (j['transactions'] as List)
            .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
