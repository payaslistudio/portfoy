import 'package:intl/intl.dart';
import '../state/portfolio_controller.dart';
import 'settings_service.dart';

/// TL cinsinden tutulan tüm miktarları kullanıcı tercih ettiği para birimine
/// çevirir ve formatlar. USD kuru controller.currentPrices['USD']'den alınır.
class MoneyFormatter {
  final SettingsService settings;
  final PortfolioController controller;

  late final NumberFormat _try =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  late final NumberFormat _usd =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  MoneyFormatter(this.settings, this.controller);

  double _usdRate() {
    final r = controller.currentPrices['USD'];
    if (r == null || r <= 0) return 0;
    return r;
  }

  /// TL girdisini seçili para birimine çevrilmiş biçimlendirilmiş metin.
  String fmt(double amountTry) {
    if (settings.currency == Currency.tryLira) {
      return _try.format(amountTry);
    }
    final rate = _usdRate();
    if (rate == 0) return '—';
    return _usd.format(amountTry / rate);
  }

  /// USD'ye çevrilebilir mi (kur var mı)?
  bool get canConvert =>
      settings.currency == Currency.tryLira || _usdRate() > 0;
}
