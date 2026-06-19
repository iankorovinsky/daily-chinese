#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path

TONE_MARKS = {
    "a": "āáǎàa",
    "e": "ēéěèe",
    "i": "īíǐìi",
    "o": "ōóǒòo",
    "u": "ūúǔùu",
    "v": "ǖǘǚǜü",
    "ü": "ǖǘǚǜü",
}

LINE_RE = re.compile(r"^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+)/$")


def numbered_pinyin_to_marks(text: str) -> str:
    return " ".join(convert_syllable(part) for part in text.replace("u:", "ü").split())


def convert_syllable(syllable: str) -> str:
    match = re.search(r"([1-5])$", syllable)
    if not match:
        return syllable

    tone = int(match.group(1))
    base = syllable[:-1]
    if tone == 5:
        return base

    lower = base.lower()
    target_index = -1
    for vowel in ("a", "e"):
        if vowel in lower:
            target_index = lower.index(vowel)
            break

    if target_index == -1 and "ou" in lower:
        target_index = lower.index("o")

    if target_index == -1:
        for index in range(len(lower) - 1, -1, -1):
            if lower[index] in TONE_MARKS:
                target_index = index
                break

    if target_index == -1:
        return base

    vowel = lower[target_index]
    marked = TONE_MARKS[vowel][tone - 1]
    return base[:target_index] + marked + base[target_index + 1 :]


def clean_english(definition: str) -> str:
    parts = [part.strip() for part in definition.split("/") if part.strip()]
    kept = []
    for part in parts:
        if part.startswith("CL:") or part.startswith("variant of "):
            continue
        kept.append(part)
        if len(kept) == 2:
            break
    return "; ".join(kept)


def read_terms(path: Path | None) -> list[str] | None:
    if path is None:
        return None
    return [
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]


def parse_cedict(path: Path) -> dict[str, dict]:
    entries = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        match = LINE_RE.match(line)
        if not match:
            continue

        traditional, simplified, pinyin, definition = match.groups()
        if len(simplified) != 1:
            continue

        english = clean_english(definition)
        if not english:
            continue

        entries.setdefault(
            simplified,
            {
                "simplified": simplified,
                "traditional": traditional,
                "pinyin": numbered_pinyin_to_marks(pinyin),
                "english": english,
                "notes": None,
            },
        )
    return entries


def main() -> None:
    parser = argparse.ArgumentParser(description="Build Shared/words.json from a CC-CEDICT text file.")
    parser.add_argument("--cedict", required=True, type=Path, help="Path to cedict_ts.u8.")
    parser.add_argument("--out", default=Path("Shared/words.json"), type=Path, help="Output JSON path.")
    parser.add_argument("--terms", type=Path, help="Optional newline-delimited simplified characters to include in order.")
    parser.add_argument("--limit", type=int, default=500, help="Maximum entries when --terms is not provided.")
    args = parser.parse_args()

    entries = parse_cedict(args.cedict)
    terms = read_terms(args.terms)
    selected_terms = terms if terms is not None else sorted(entries.keys())[: args.limit]

    words = []
    for term in selected_terms:
        entry = entries.get(term)
        if not entry:
            continue
        words.append({"id": len(words) + 1, **entry})

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(words, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(words)} words to {args.out}")


if __name__ == "__main__":
    main()
