# TEFAS Fon Fiyat Backend'i (Sıfır Maliyet)

TEFAS'ın resmi API'si F5 WAF ile korumalı olduğu için Flutter app doğrudan
çekemiyor. Bu klasördeki script her gece **GitHub Actions** üzerinde
Playwright (headless Chromium) ile çalışıp fon fiyatlarını
`data/funds.json` dosyasına yazar. Flutter app bu dosyayı GitHub'ın
`raw.githubusercontent.com` CDN'inden okur.

**Toplam maliyet: 0 ₺.** GitHub Actions ücretsiz katmanında ayda ~2 dakika
kullanır (aylık kota 2000 dk).

## Kurulum (3 adım)

### 1. Public GitHub repo oluştur
```powershell
cd C:\Users\DELL\Lab\Portfoy
git init
git add .
git commit -m "initial commit"
# GitHub'da yeni bir public repo aç (örn. "portfoy")
git remote add origin https://github.com/<KULLANICI_ADIN>/portfoy.git
git branch -M main
git push -u origin main
```

### 2. Actions'ın yazma iznini kontrol et
GitHub → repo → Settings → Actions → General → Workflow permissions →
**"Read and write permissions"** işaretli olmalı.

### 3. İlk scrape'i elle tetikle
GitHub → repo → Actions → "Daily TEFAS fund prices" → **Run workflow**.
~2 dakikada `data/funds.json` güncellenir.

Bundan sonra her gün 23:30 TSİ'de otomatik çalışır.

## Flutter app'te ne değiştirilecek?

`lib/services/price_service.dart` içindeki bu satırı kendi kullanıcı
adın/repo adınla güncelle:

```dart
static const _fundsJsonUrl =
    'https://raw.githubusercontent.com/<KULLANICI_ADIN>/portfoy/main/data/funds.json';
```

Sonra `flutter build apk --release` yeter.

## Lokal test

```powershell
cd C:\Users\DELL\Lab\Portfoy
python -m pip install -r backend/requirements.txt
python -m playwright install chromium
python backend/scrape_tefas.py
```
