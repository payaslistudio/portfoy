"""TEFAS fon fiyatlarını Playwright ile çekip data/funds.json'a yazar.

- TEFAS'ın F5 BigIP WAF'ı JS challenge içerdiği için düz HTTP çalışmaz.
- Playwright (headless Chromium) sayfayı yükleyip cookie'yi alır, sonra
  Açık Veri "Günlük Fon Verileri" tablosunu çeker.
"""
from __future__ import annotations

import json
import os
import sys
from datetime import datetime
from pathlib import Path

from playwright.sync_api import sync_playwright

OUTPUT = Path(__file__).parent.parent / "data" / "funds.json"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)


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
        # Ana sayfa: F5 challenge çözülür ve cookie set edilir
        page.goto("https://www.tefas.gov.tr/", wait_until="domcontentloaded", timeout=60000)
        page.wait_for_timeout(3000)  # WAF cookie'sinin oturması için

        # Günlük fiyatlar sayfası (tüm fonlar tek tabloda)
        page.goto(
            "https://www.tefas.gov.tr/FonKarsilastirma.aspx",
            wait_until="networkidle",
            timeout=60000,
        )
        page.wait_for_selector("#MainContent_grdKarsilastirma", timeout=30000)

        rows = page.query_selector_all("#MainContent_grdKarsilastirma tbody tr")
        for row in rows:
            cells = [c.inner_text().strip() for c in row.query_selector_all("td")]
            if len(cells) < 3:
                continue
            code = cells[0].strip().upper()
            name = cells[1].strip() if len(cells) > 1 else ""
            # Fiyat sütununu bul (genelde 3. veya 4. hücre)
            price = None
            for c in cells[2:6]:
                c = c.replace(".", "").replace(",", ".")
                try:
                    v = float(c)
                    if 0.0001 < v < 100000:
                        price = v
                        break
                except ValueError:
                    continue
            if code and price is not None:
                prices[code] = {"price": price, "name": name}
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
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(prices)} fund prices to {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
