import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/settings_service.dart';

class AyarlarTab extends StatefulWidget {
  final SettingsService settings;
  const AyarlarTab({super.key, required this.settings});

  @override
  State<AyarlarTab> createState() => _AyarlarTabState();
}

class _AyarlarTabState extends State<AyarlarTab> {
  static const _appName = 'Yatırım Cüzdanı';
  static const _version = '0.1.0';
  static const _supportEmail = 'payaslistudio@gmail.com';
  // Play Store paket kimliği ile aynı olmalı
  static const _packageId = 'com.payaslistudio.varlikcuzdani';

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 220),
        children: [
          _proBanner(),
          _sectionHeader('Üyelik'),
          ListTile(
            leading: Icon(
              Icons.workspace_premium,
              color: s.isPro ? const Color(0xFFFFB300) : null,
            ),
            title: const Text('Durum'),
            trailing: _statusBadge(isPro: s.isPro),
            onTap: () => _showProSheet(),
          ),
          _sectionHeader('Tercihler'),
          ListTile(
            leading: const Icon(Icons.currency_lira),
            title: const Text('Para Birimi'),
            subtitle: Text(s.currency.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickCurrency,
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Görünüm'),
            subtitle: Text(_themeLabel(s.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickTheme,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Bildirimler'),
            subtitle: const Text('Kapalı'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _toast('Yakında.'),
          ),
          _sectionHeader('Destek'),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Bize Ulaşın'),
            subtitle: const Text(_supportEmail),
            onTap: _showContactSheet,
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Uygulamayı Puanla'),
            onTap: _showRatingDialog,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Gizlilik Politikası'),
            onTap: _showPrivacyDialog,
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text(_appName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Sürüm $_version',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Text('© 2026 Yatırım Cüzdanı. Tüm hakları saklıdır.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11)),
              ],
            ),
          ),
          // FAB'ın alta binmemesi için ekstra boşluk
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ————————————————— Pro —————————————————

  Widget _proBanner() {
    final isPro = widget.settings.isPro;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: InkWell(
        onTap: _showProSheet,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: isPro
                  ? const [Color(0xFF66BB6A), Color(0xFF43A047), Color(0xFF00897B)]
                  : const [Color(0xFFFFB300), Color(0xFFFF7043), Color(0xFFAB47BC)],
            ),
            boxShadow: [
              BoxShadow(
                color: (isPro
                        ? const Color(0xFF66BB6A)
                        : const Color(0xFFFFB300))
                    .withValues(alpha: 0.35),
                blurRadius: 20, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium,
                    size: 26, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPro
                          ? 'Pro üyeliğin aktif ✓'
                          : 'Yatırım Cüzdanı Pro’ya Geç',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPro
                          ? 'Tüm özellikler açık'
                          : 'Reklamsız deneyim ve tüm özellikler',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge({required bool isPro}) {
    final color = isPro ? const Color(0xFFFFB300) : const Color(0xFF66BB6A);
    final label = isPro ? 'Pro' : 'Ücretsiz';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  void _showProSheet() {
    // NOT: Google Play Billing entegrasyonu tamamlanana kadar planlar
    // gizlenir — Play Store aksi halde uygulamayı reddeder.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.workspace_premium,
                    color: Color(0xFFFFB300), size: 28),
                SizedBox(width: 8),
                Text('Yatırım Cüzdanı Pro',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 24),
            _proFeature('Reklamsız deneyim'),
            _proFeature('Sınırsız varlık ekleme'),
            _proFeature('Detaylı analiz ve raporlar'),
            _proFeature('Öncelikli destek'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule, color: Color(0xFFFFB300), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pro üyelik çok yakında. İlk sürümde tüm özellikler herkese ücretsiz.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _proFeature(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.check_circle,
                color: Color(0xFF66BB6A), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );

  // ————————————————— Currency picker —————————————————

  void _pickCurrency() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Para Birimi',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ...Currency.values.map((c) {
              final selected = widget.settings.currency == c;
              return ListTile(
                leading: Icon(
                  c == Currency.tryLira
                      ? Icons.currency_lira
                      : Icons.attach_money,
                ),
                title: Text(c.label),
                trailing: selected
                    ? const Icon(Icons.check, color: Color(0xFFFFB300))
                    : null,
                onTap: () async {
                  await widget.settings.setCurrency(c);
                  if (mounted) Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ————————————————— Theme picker —————————————————

  String _themeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => 'Sistem varsayılanı',
        ThemeMode.dark => 'Koyu tema',
        ThemeMode.light => 'Açık tema',
      };

  void _pickTheme() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Görünüm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            for (final m in [
              ThemeMode.system,
              ThemeMode.dark,
              ThemeMode.light
            ])
              ListTile(
                leading: Icon(switch (m) {
                  ThemeMode.system => Icons.brightness_auto,
                  ThemeMode.dark => Icons.dark_mode,
                  ThemeMode.light => Icons.light_mode,
                }),
                title: Text(_themeLabel(m)),
                trailing: widget.settings.themeMode == m
                    ? const Icon(Icons.check, color: Color(0xFFFFB300))
                    : null,
                onTap: () async {
                  await widget.settings.setThemeMode(m);
                  if (mounted) Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ————————————————— Contact —————————————————

  void _showContactSheet() {
    final subject = TextEditingController();
    final body = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Bize Ulaşın',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Mesajın $_supportEmail adresine gönderilecek.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: subject,
              decoration: const InputDecoration(
                labelText: 'Konu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: body,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Mesaj',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Gönder'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                final s = subject.text.trim();
                final b = body.text.trim();
                if (s.isEmpty && b.isEmpty) {
                  _toast('Konu veya mesaj boş olamaz.');
                  return;
                }
                final uri = Uri(
                  scheme: 'mailto',
                  path: _supportEmail,
                  queryParameters: {
                    if (s.isNotEmpty) 'subject': s,
                    if (b.isNotEmpty) 'body': b,
                  },
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                  if (mounted) Navigator.pop(ctx);
                } else {
                  _toast('E-posta uygulaması bulunamadı.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ————————————————— Rating —————————————————

  void _showRatingDialog() {
    int rating = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          title: const Text('Uygulamayı Puanla'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Deneyimini nasıl bulursun?',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final idx = i + 1;
                  final filled = idx <= rating;
                  return IconButton(
                    icon: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFB300),
                      size: 34,
                    ),
                    onPressed: () => setSt(() => rating = idx),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: rating == 0
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      // Play Store veya App Store'a yönlendir
                      final uris = [
                        Uri.parse('market://details?id=$_packageId'),
                        Uri.parse(
                            'https://play.google.com/store/apps/details?id=$_packageId'),
                      ];
                      for (final u in uris) {
                        if (await canLaunchUrl(u)) {
                          await launchUrl(u,
                              mode: LaunchMode.externalApplication);
                          return;
                        }
                      }
                      if (mounted) _toast('Mağaza uygulaması bulunamadı.');
                    },
              child: const Text('Mağazada Puanla'),
            ),
          ],
        );
      }),
    );
  }

  // ————————————————— shared —————————————————

  Widget _sectionHeader(String s) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(s.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Color(0xFFFFB300))),
      );

  void _toast(String s) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s), duration: const Duration(seconds: 2)));
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gizlilik Politikası ve Yasal Uyarı'),
        content: const SingleChildScrollView(
          child: Text(
            '⚠ ÖNEMLİ YASAL UYARI\n\n'
            'Yatırım Cüzdanı bir aracı kurum, banka, cüzdan servisi veya '
            'finansal danışmanlık hizmeti DEĞİLDİR. Uygulama yalnızca '
            'kullanıcının kendi kayıtlarını tuttuğu bir TAKİP ARACIDIR.\n\n'
            'Uygulama\'da gösterilen fiyatlar ve hesaplamalar hiçbir şekilde '
            'yatırım tavsiyesi niteliği taşımaz. Yatırım kararlarınız için '
            'lisanslı bir aracı kuruluşa danışmanız gerekir.\n\n'
            '📊 FİYAT VERİLERİ\n\n'
            'Uygulama\'da gösterilen piyasa fiyatları anlık/gerçek zamanlı '
            'DEĞİLDİR. Fiyatlar:\n'
            '• 15 dakika veya daha fazla gecikmeli olabilir\n'
            '• Hatalı, eksik veya güncel olmayan değerler içerebilir\n'
            '• Kaynağa ulaşılamadığı anlarda güncellenmeyebilir\n\n'
            'Fiyatların doğruluğu ve güncelliği garanti EDİLMEZ. Bu verilere '
            'dayanarak aldığınız kararlardan geliştirici sorumlu tutulamaz.\n\n'
            '🔒 GİZLİLİK\n\n'
            '• Portföy kayıtlarınız yalnızca telefonunuzun yerel depolamasında '
            'tutulur; sunucularımıza gönderilmez.\n'
            '• Uygulamayı sildiğinizde tüm verileriniz cihazınızla birlikte '
            'silinir.\n'
            '• Piyasa fiyatları için üçüncü taraf açık veri sağlayıcılarına '
            'HTTP çağrısı yapılır; yalnızca istenen sembol iletilir, kişisel '
            'bilginiz gönderilmez.\n'
            '• Reklam, analitik veya üçüncü taraf takip SDK\'sı YOKTUR.\n\n'
            '📱 SORUMLULUK REDDİ\n\n'
            'Uygulama "olduğu gibi" sunulmuştur. Kesintisiz çalışacağına, '
            'hatasız olacağına dair garanti verilmez. Kullanımdan doğabilecek '
            'doğrudan veya dolaylı zararlar için geliştirici sorumlu değildir.\n\n'
            'Detaylı sürüm ve iletişim: $_supportEmail',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
