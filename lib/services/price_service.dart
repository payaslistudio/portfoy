import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fiyatları TL cinsinden döndüren servis.
/// - Altın + döviz: https://finans.truncgil.com/v4/today.json (ücretsiz, anahtarsız)
/// - BIST hisseleri: Yahoo Finance query1 (ücretsiz, anahtarsız, .IS suffix)
class PriceService {
  static const _truncgilUrl = 'https://finans.truncgil.com/v4/today.json';

  /// Katalog kodu → Truncgil JSON alan adı
  static const _truncgilMap = <String, String>{
    'GRAM_ALTIN': 'GRA',
    'CEYREK': 'CEYREKALTIN',
    'YARIM': 'YARIMALTIN',
    'TAM': 'TAMALTIN',
    'CUMHURIYET': 'CUMHURIYETALTINI',
    'ATA': 'ATAALTIN',
    'RESAT': 'RESATALTIN',
    'HAMIT': 'HAMITALTIN',
    'ONS': 'ONS',
    'AYAR22': 'YIA',
    'AYAR18': '18AYARALTIN',
    'AYAR14': '14AYARALTIN',
    'GUMUS': 'GUMUS',
    'PLATIN': 'GPL',
    'PALADYUM': 'PAL',
    'BRENT': 'BRENT',
    'USD': 'USD',
    'EUR': 'EUR',
    'GBP': 'GBP',
    'CHF': 'CHF',
    'JPY': 'JPY',
    'CAD': 'CAD',
    'AUD': 'AUD',
    'SAR': 'SAR',
    'RUB': 'RUB',
    'TRY': 'TRY',
  };

  Map<String, double>? _cache;
  DateTime? _cacheTime;
  static const _cacheTtl = Duration(minutes: 2);

  /// Katalog varlıklarının TL cinsinden anlık fiyatı.
  Future<Map<String, double>> fetchTruncgil({bool force = false}) async {
    if (!force &&
        _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheTtl) {
      return _cache!;
    }

    final res = await http
        .get(Uri.parse(_truncgilUrl))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Fiyat servisi hatası: ${res.statusCode}');
    }

    final data = json.decode(res.body) as Map<String, dynamic>;
    final result = <String, double>{};

    _truncgilMap.forEach((code, key) {
      if (code == 'TRY') {
        result[code] = 1.0;
        return;
      }
      final entry = data[key];
      if (entry is Map && entry['Selling'] != null) {
        final raw = entry['Selling'].toString().replaceAll(',', '.');
        final v = double.tryParse(raw);
        if (v != null && v > 0) result[code] = v;
      } else if (entry is num && entry > 0) {
        result[code] = entry.toDouble();
      }
    });

    _cache = result;
    _cacheTime = DateTime.now();
    return result;
  }

  /// Fon fiyatları GitHub Actions cron ile her gece çekilip JSON'a yazılır.
  /// Kendi repo'nu deploy ettikten sonra bu URL'i güncelle.
  static const _fundsJsonUrl =
      'https://raw.githubusercontent.com/payaslistudio/portfoy/main/data/funds.json';

  Map<String, double>? _fundCache;
  DateTime? _fundCacheTime;
  static const _fundCacheTtl = Duration(hours: 6);

  Future<Map<String, double>> _fetchAllFunds({bool force = false}) async {
    if (!force &&
        _fundCache != null &&
        _fundCacheTime != null &&
        DateTime.now().difference(_fundCacheTime!) < _fundCacheTtl) {
      return _fundCache!;
    }
    final res = await http
        .get(Uri.parse(_fundsJsonUrl))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return {};
    final data = json.decode(res.body) as Map<String, dynamic>;
    final prices = data['prices'];
    final map = <String, double>{};
    if (prices is Map) {
      prices.forEach((k, v) {
        if (v is Map && v['price'] is num) {
          map[k.toString().toUpperCase()] = (v['price'] as num).toDouble();
        }
      });
    }
    _fundCache = map;
    _fundCacheTime = DateTime.now();
    return map;
  }

  /// TEFAS fonunun son fiyatı (TL). `code` 2-4 harfli fon kodu (ör. YAC, AAK).
  /// Backend cron'unu deploy etmediysen boş döner.
  Future<double?> fetchTefasFund(String code) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return null;
    if (_fundsJsonUrl.contains('CHANGE_ME')) return null;
    try {
      final all = await _fetchAllFunds();
      return all[c];
    } catch (_) {
      return null;
    }
  }

  /// BIST hissesinin TL cinsinden son fiyatı. `symbol` örn: THYAO, ASELS.
  Future<double?> fetchBistStock(String symbol) async {
    final s = symbol.toUpperCase().endsWith('.IS')
        ? symbol.toUpperCase()
        : '${symbol.toUpperCase()}.IS';
    final url =
        'https://query1.finance.yahoo.com/v8/finance/chart/$s?interval=1d&range=1d';
    try {
      final res = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final result = data['chart']?['result'];
      if (result is List && result.isNotEmpty) {
        final meta = result[0]['meta'] as Map<String, dynamic>?;
        final price = meta?['regularMarketPrice'];
        if (price is num) return price.toDouble();
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
