"""TEFAS fon fiyatlarını resmi API üzerinden çekip data/funds.json'a yazar.

Endpoint: POST /api/funds/fonBuyuklukBazliBilgiGetir
Fiyat = sonPortfoyDegeri / sonPayAdedi (fon NAV'ı / pay adedi = birim pay fiyatı).

Public Bearer token TEFAS'ın frontend'inde hardcoded. WAF'ı by-pass eder;
Playwright veya JS challenge çözmeye gerek yok. Sıradan HTTP çağrısı yeter.
"""
from __future__ import annotations

import json
import sys
import urllib.request
from datetime import datetime, timedelta
from pathlib import Path

OUTPUT = Path(__file__).parent.parent / "data" / "funds.json"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

URL = "https://www.tefas.gov.tr/api/funds/fonBuyuklukBazliBilgiGetir"
HEADERS = {
    "Authorization": "Bearer ST-tefaswebwse3irfmSBj4iRAzGPbAlS94Se",
    "Content-Type": "application/json",
    "Accept": "*/*",
    "Origin": "https://www.tefas.gov.tr",
    "Referer": "https://www.tefas.gov.tr/tr/fon-getirileri?fundType=YAT&listingTab=size",
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"
    ),
}

# YAT: yatırım fonları, EMK: emeklilik, BYF: borsa yatırım fonları
FUND_TYPES = ["YAT", "EMK", "BYF"]


def fetch_type(fund_type: str) -> list[dict]:
    now = datetime.now()
    start = now - timedelta(days=15)
    body = {
        "dil": "TR", "fonTipi": fund_type,
        "kurucuKodu": None, "sfonTurKod": None,
        "fonTurAciklama": None, "islem": 1,
        "fonTurKod": None, "fonGrubu": None,
        "basTarih": start.strftime("%Y%m%d"),
        "bitTarih": now.strftime("%Y%m%d"),
        "calismaTipi": 1,
    }
    req = urllib.request.Request(
        URL, data=json.dumps(body).encode(), headers=HEADERS, method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        data = json.loads(r.read().decode())
    return data.get("resultList") or []


def main() -> int:
    prices: dict[str, dict] = {}
    for tipi in FUND_TYPES:
        try:
            rl = fetch_type(tipi)
            print(f"{tipi}: {len(rl)} funds")
            for e in rl:
                code = e.get("fonKodu")
                pd = e.get("sonPortfoyDegeri")
                pa = e.get("sonPayAdedi")
                if not code or not pd or not pa or pa <= 0:
                    continue
                nav = pd / pa
                if not (0.0001 < nav < 1000000):
                    continue
                entry = {
                    "price": round(nav, 6),
                    "name": e.get("fonUnvan", ""),
                    "type": tipi,
                    "kind": e.get("fonTurAciklama", ""),
                }
                # Ilk gelen kayıt tutulur; aynı kod farklı tipte olmaz normalde.
                prices.setdefault(code, entry)
        except Exception as ex:
            print(f"ERR {tipi}: {ex}", file=sys.stderr)

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
    print(f"\nWrote {len(prices)} fund prices to {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
