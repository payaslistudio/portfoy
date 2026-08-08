"""BIST hisselerini sabah.com.tr canlı borsa sayfasından çıkarır.

Sayfada yerleşik bir JSON var: [{"SEMBOL":"AKBNK","URL":"akbank-akbnk"}, ...]
Buradan tüm BIST sembollerini + firma adlarını (URL slug'ından türetilmiş)
çekip lib/data/bist_symbols.dart olarak yazar.

Fiyatlar zaten Yahoo Finance query üzerinden anlık (fetchBistStock).
"""
from __future__ import annotations

import json
import re
import sys
import urllib.request
from pathlib import Path

OUTPUT = Path(__file__).parent.parent / "lib" / "data" / "bist_symbols.dart"


def title_case_tr(s: str) -> str:
    return " ".join(w.capitalize() for w in s.split())


def main() -> int:
    url = "https://www.sabah.com.tr/finans/canli-borsa"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=25) as r:
        html = r.read().decode("utf-8", errors="ignore")

    # Sayfa şu yapıyı içeriyor: "SEMBOL":"XXXX","URL":"firma-adi-xxxx"
    pattern = re.compile(
        r'"SEMBOL"\s*:\s*"([A-Z0-9]{3,6})"\s*,\s*"URL"\s*:\s*"([^"]+)"'
    )
    matches = pattern.findall(html)
    symbols: dict[str, str] = {}
    for code, slug in matches:
        # slug: "akbank-akbnk" veya "ahes-gmyo-ahsgy"
        parts = slug.split("-")
        # son kısım kod (aynı sembol) olabilir; onu çıkar
        if parts and parts[-1].upper() == code:
            parts = parts[:-1]
        raw_name = " ".join(parts)
        name = title_case_tr(raw_name)
        # kısmi TR karakter geri dönüşümü (yaygın patternler)
        name = (name.replace("Gyo", "GYO").replace("Gmyo", "GYO")
                    .replace("As", "A.Ş.").replace("Aş", "A.Ş.")
                    .replace(" I ", " İ ").replace(" S ", " Ş "))
        if code not in symbols or (name and not symbols[code]):
            symbols[code] = name

    if not symbols:
        print("ERROR: no BIST symbols extracted", file=sys.stderr)
        return 1
    print(f"Extracted {len(symbols)} BIST symbols")

    lines = [
        "/// BIST'te işlem gören tüm hisseler.",
        "/// Otomatik derleme: backend/scrape_bist.py (sabah.com.tr yerleşik JSON)",
        "const Map<String, String> kBistSymbols = {",
    ]
    for code in sorted(symbols):
        name = symbols[code].replace("'", "\\'").replace("\n", " ").strip()
        lines.append(f"  '{code}': '{name}',")
    lines.append("};")
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
