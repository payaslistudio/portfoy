"""TEFAS fon fiyatlarını Playwright ile çekip data/funds.json'a yazar.

Strateji:
  1. Playwright headless Chromium ile TEFAS ana sayfasını açıp F5 BigIP WAF
     challenge'ını çözer (cookie set edilir).
  2. Aynı context'ten `page.evaluate` ile fetch() çağırarak
     /api/DB/BindComparisonFundReturns endpoint'ini denenir (tüm fon listesi).
  3. Başarısız olursa, uygulama içinde tanımlı fon listesi üzerinden
     FonAnaliz.aspx sayfaları gezilip fiyat HTML'den regex ile çıkarılır.
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime
from pathlib import Path

from playwright.sync_api import sync_playwright

OUTPUT = Path(__file__).parent.parent / "data" / "funds.json"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

# Uygulamayla senkron (lib/data/tefas_funds.dart) — buraya eklemek yeter.
KNOWN_FUNDS = [
    "AAK","AFA","AFO","AFT","AK3","AKE","AKU","APT","AUT","DBH",
    "FIB","GAF","GHS","GPP","HIS","IIH","IIT","IJH","IJS","IPB",
    "ISY","KKA","KTY","MPO","NNF","OBI","OSD","PPZ","QIA","QIH",
    "TBD","TBH","TCD","TE1","TGE","TI2","TI3","TI7","TMG","TPZ",
    "YAC","YAS","YBS","YKS","YLC","YTA","ZBJ","ZPX",
]

PRICE_RE = re.compile(
    r'Son\s*Fiyat.{0,200}?([0-9]+[.,][0-9]{4,6})', re.IGNORECASE | re.DOTALL
)
# Yedek desen: sayfada geçen ilk 4-6 basamaklı ondalık
FALLBACK_RE = re.compile(r'([0-9]+[.,][0-9]{4,6})')


def parse_price(html: str) -> float | None:
    m = PRICE_RE.search(html)
    if m:
        raw = m.group(1).replace(".", "").replace(",", ".")
        try:
            v = float(raw)
            if 0.0001 < v < 100000:
                return v
        except ValueError:
            pass
    # Fallback: en yüksek ihtimalli "N,NNNN" veya "N.NNNN" değeri
    for m in FALLBACK_RE.finditer(html):
        raw = m.group(1)
        # Türkçe biçim (virgül ondalık ayracı)
        if "," in raw:
            candidate = raw.replace(".", "").replace(",", ".")
        else:
            candidate = raw
        try:
            v = float(candidate)
            if 0.001 < v < 10000:
                return v
        except ValueError:
            continue
    return None


def scrape() -> dict:
    prices: dict[str, dict] = {}
    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=True)
        ctx = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/120.0.0.0 Safari/537.36"
            ),
            locale="tr-TR",
        )
        page = ctx.new_page()

        # 1) Ana sayfa: F5 WAF challenge çözülsün
        page.goto("https://www.tefas.gov.tr/", wait_until="domcontentloaded", timeout=60000)
        page.wait_for_timeout(3000)

        # 2) Her fon için FonAnaliz sayfasını gez
        for code in KNOWN_FUNDS:
            url = f"https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod={code}"
            try:
                page.goto(url, wait_until="domcontentloaded", timeout=30000)
                page.wait_for_timeout(1500)  # dinamik içerik için
                html = page.content()
                price = parse_price(html)
                # Fon adını başlıktan çıkar
                name_m = re.search(
                    r'<title>([^<]+)</title>', html, re.IGNORECASE
                )
                name = name_m.group(1).strip() if name_m else ""
                name = re.sub(r'\s*\|\s*TEFAS.*$', '', name).strip()
                if price:
                    prices[code] = {"price": price, "name": name}
                    print(f"OK  {code}: {price}  ({name})")
                else:
                    print(f"MISS {code}: no price parsed")
            except Exception as e:
                print(f"ERR {code}: {e}", file=sys.stderr)

        browser.close()
    return prices


def main() -> int:
    prices = scrape()
    if not prices:
        print("ERROR: no prices scraped", file=sys.stderr)
        return 1
    payload = {
        "updated": datetime.utcnow().isoformat() + "Z",
        "count": len(prices),
        "prices": prices,
    }
    OUTPUT.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"Wrote {len(prices)} fund prices to {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
