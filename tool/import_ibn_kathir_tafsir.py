#!/usr/bin/env python3
"""Import verbatim du Tafsir Ibn Kathir (ar) depuis spa5k/tafsir_api.

Ne reformule jamais le texte. Regroupe les ayahs consécutifs au texte
strictement identique en plages start–end.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import pathlib
import urllib.request

DEFAULT_COMMIT = "eb82bb6294efe30ad5c135c03b1864afaa70e855"
RAW = "https://raw.githubusercontent.com/spa5k/tafsir_api/{commit}/tafsir/ar-tafsir-ibn-kathir/{surah}.json"


def download(commit: str, dest: pathlib.Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    for s in range(1, 115):
        url = RAW.format(commit=commit, surah=s)
        path = dest / f"{s}.json"
        print(f"GET {url}")
        with urllib.request.urlopen(url, timeout=120) as resp:
            path.write_bytes(resp.read())
    (dest / "COMMIT.txt").write_text(commit + "\n", encoding="utf-8")


def convert(src: pathlib.Path, out: pathlib.Path, commit: str) -> None:
    out.mkdir(parents=True, exist_ok=True)
    meta = {
        "id": "ibn_kathir_ar",
        "work_ar": "تفسير القرآن العظيم",
        "work_en": "Tafsir al-Qur'an al-Azim",
        "commentator_ar": "ابن كثير",
        "commentator_en": "Ibn Kathir (Ismail ibn Umar, d. 774/1373)",
        "language": "ar",
        "license": "public-domain",
        "license_note": (
            "Classical work public domain (author died 1373). "
            "Digital packaging from spa5k/tafsir_api (MIT). "
            "Text is verbatim; never AI-generated."
        ),
        "source_repo": "https://github.com/spa5k/tafsir_api",
        "source_edition": "ar-tafsir-ibn-kathir",
        "source_commit": commit,
        "upstream_dataset": (
            "quranlab/quran-tafsir config tafsir-ibnkathir-ar (nassimjp mirror)"
        ),
        "attribution": (
            "تفسير القرآن العظيم — ابن كثير. "
            "مصدر رقمي: spa5k/tafsir_api (نص حرفي، ملكية عامة)."
        ),
        "imported_at": dt.datetime.now(dt.timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%SZ"
        ),
        "surahs": 114,
        "ayah_entries_source": 6236,
        "files": [],
    }

    total_ranges = 0
    total_ayahs = 0
    multi = 0

    for s in range(1, 115):
        rows = json.loads((src / f"{s}.json").read_text(encoding="utf-8"))
        entries = []
        i = 0
        while i < len(rows):
            a = rows[i]
            assert a["surah"] == s and a["ayah"] == i + 1
            text = (a.get("text") or "").strip()
            if not text:
                i += 1
                continue
            start = end = a["ayah"]
            j = i + 1
            while j < len(rows):
                t2 = (rows[j].get("text") or "").strip()
                if t2 == text and rows[j]["ayah"] == end + 1:
                    end = rows[j]["ayah"]
                    j += 1
                else:
                    break
            entries.append({"start": start, "end": end, "text": text})
            if end > start:
                multi += 1
            total_ranges += 1
            total_ayahs += end - start + 1
            i = j

        payload = {
            "surah": s,
            "commentator_ar": meta["commentator_ar"],
            "work_ar": meta["work_ar"],
            "entries": entries,
        }
        fname = f"{s:03d}.json"
        path = out / fname
        path.write_text(
            json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n",
            encoding="utf-8",
        )
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        meta["files"].append(
            {
                "file": fname,
                "surah": s,
                "ranges": len(entries),
                "sha256": digest,
                "bytes": path.stat().st_size,
            }
        )

    meta["range_entries"] = total_ranges
    meta["ayahs_covered"] = total_ayahs
    meta["multi_ayah_ranges"] = multi
    meta["sha256_algorithm"] = "SHA-256"
    (out / "MANIFEST.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(
        f"OK ranges={total_ranges} ayahs={total_ayahs} multi={multi} commit={commit}"
    )


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--commit", default=DEFAULT_COMMIT)
    p.add_argument("--download-dir", type=pathlib.Path, default=pathlib.Path("/tmp/ibn_kathir_src"))
    p.add_argument(
        "--out",
        type=pathlib.Path,
        default=pathlib.Path("assets/quran/tafsir/ibn_kathir_ar"),
    )
    p.add_argument("--skip-download", action="store_true")
    args = p.parse_args()
    if not args.skip_download:
        download(args.commit, args.download_dir)
    convert(args.download_dir, args.out, args.commit)


if __name__ == "__main__":
    main()
