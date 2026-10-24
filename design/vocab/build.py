#!/usr/bin/env python3
"""Build a page from vocab-swipe.src.html, embedding each word's clip as a
data URI (artifact pages cannot load media from other hosts).

  python3 design/vocab/build.py AUDIO_DIR
      -> vocab-swipe.html (the layout mock, band 601-700 words)
  python3 design/vocab/build.py AUDIO_DIR --draft tools/vocab/drafts/sample_v1.json --out review-v1.html
      -> the same screens filled with a draft review set

AUDIO_DIR holds report.json from tools/vocab/fetch_audio.py plus the MP3s.
"""
import argparse
import base64
import json
from pathlib import Path

HERE = Path(__file__).parent
ap = argparse.ArgumentParser()
ap.add_argument("audio_dir", type=Path)
ap.add_argument("--draft", type=Path)
ap.add_argument("--out", default="vocab-swipe.html")
args = ap.parse_args()

report = json.loads((args.audio_dir / "report.json").read_text())
audio = {}
for word, r in report.items():
    data = base64.b64encode((args.audio_dir / r["file"]).read_bytes()).decode()
    by = f"Lingua Libre · {r['speaker']}" if r["source"] == "lingualibre" else "TTS"
    audio[word] = {"src": "data:audio/mpeg;base64," + data, "by": by}

src = (HERE / "vocab-swipe.src.html").read_text()
fill = {"__LECON_LABEL__": "Leçon 63 · mots 601–700", "__LECON_NUM__": "63",
        "__INTRO__": "Leçon 63, words ranked 601–700, shuffled.", "__EXTRA__": "{}"}
if args.draft:
    draft = json.loads(args.draft.read_text())
    entries = draft["entries"]
    lesson = [[e["fr"], e["pos"], e["en"]] for e in entries]
    start, end = src.index("/*LESSON*/"), src.index("/*END*/") + len("/*END*/")
    src = src[:start] + json.dumps(lesson, ensure_ascii=False) + src[end:]
    extra = {e["fr"]: {k: e[k] for k in ("fem", "register") if e.get(k)} for e in entries}
    fill.update({"__LECON_LABEL__": "Échantillon · " + args.draft.stem, "__LECON_NUM__": args.draft.stem.rsplit("_", 1)[-1],
                 "__INTRO__": f"Review set {args.draft.stem}: {len(entries)} entries, one of each type.",
                 "__EXTRA__": json.dumps(extra, ensure_ascii=False)})
    src = src.replace("<title>Mots swipe mock</title>", f"<title>Mots review {args.draft.stem}</title>")
    src = src.replace("<h1>Mots · swipe mock</h1>", f"<h1>Mots · review {args.draft.stem}</h1>")
    # Both modes drill the review set.
    boot = 'renderDict(); setMode("review");'
    assert src.count(boot) == 1
    src = src.replace(boot, "REVIEW.splice(0, REVIEW.length, ...LESSON);\n" + boot)
for k, v in fill.items():
    src = src.replace(k, v)
src = src.replace("__AUDIO__", json.dumps(audio, ensure_ascii=False))
(HERE / args.out).write_text(src)
print(f"{args.out}: {len(audio)} clips embedded")
