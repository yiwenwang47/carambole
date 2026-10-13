"""Apply the arc 4 book-wide gloss spec to every draft words file + words.json.

widen: set `en` for an existing key everywhere it is defined.
add:   new base phrase key (firstSeen null) placed in the words file of the
       first draft half (book order) whose lines use it.
Usage: python3 tools/situations/apply_gloss_spec.py SPEC [--dry]  (then assemble.py)
"""
import glob
import json
import re
import sys
import unicodedata
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO))
from tools.situations.lint import tappable_lines, tokens  # noqa: E402

spec = json.loads(Path(sys.argv[1]).read_text())
dry = "--dry" in sys.argv
drafts = sorted(glob.glob(str(REPO / "tools/situations/drafts/*_words.json")))
words_json = REPO / "carambole/Resources/Situations/words.json"
files = drafts + [str(words_json)]


def slug(fr: str) -> str:
    s = unicodedata.normalize("NFKD", fr).encode("ascii", "ignore").decode()
    return "sitw_" + re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")


def load(f):
    text = Path(f).read_text()
    return text, json.loads(text)


def save(f, text, data):
    indent = 2 if text.startswith("{\n") else None
    Path(f).write_text(json.dumps(data, ensure_ascii=False, indent=indent) + ("\n" if text.endswith("\n") else ""))


# all existing keys + audio
existing, audios = {}, set()
for f in files:
    for w in load(f)[1]["words"]:
        existing.setdefault(w["fr"], w)
        audios.add(w["audio"])

problems = []
for k in spec["widen"]:
    if k not in existing:
        problems.append(f"widen: no key {k!r}")

# which draft half first uses each new key (book order = sorted filenames, first before second)
def half_order(p):
    name = Path(p).name
    return (name[:2], 0 if "first_half" in name else 1 if "second_half" in name else 2, name)

elem_drafts = sorted((p for p in glob.glob(str(REPO / "tools/situations/drafts/*.json"))
                      if not p.endswith("_words.json")), key=half_order)
lines_by_draft = {}
for p in elem_drafts:
    d = json.loads(Path(p).read_text())
    ls = []
    for el in d.get("elements", []):
        for it in el.get("items", []):
            ls += [l for l in tappable_lines(it) if isinstance(l, str)]
    lines_by_draft[p] = [tokens(l) for l in ls]

placement = {}
for k, en in spec["add"].items():
    if k in existing:
        problems.append(f"add: key exists {k!r} = {existing[k]['en']!r}")
        continue
    need = tokens(k)
    home = None
    count = 0
    for p, toks in lines_by_draft.items():
        for t in toks:
            if any(t[i:i + len(need)] == need for i in range(len(t) - len(need) + 1)):
                count += 1
                home = home or p
    if not home:
        problems.append(f"add: {k!r} unused")
        continue
    a = slug(k)
    if a in audios:
        problems.append(f"add: audio clash {a}")
        continue
    audios.add(a)
    placement[k] = (home.replace(".json", "_words.json"), {"fr": k, "en": en, "spoken": False, "audio": a, "firstSeen": None}, count)

for k, (f, e, c) in placement.items():
    print(f"ADD {k!r:32} {c:4} uses -> {Path(f).name}")
print("\n".join(problems) or "no problems")
if dry:
    sys.exit()

for f in files:
    text, data = load(f)
    changed = False
    for w in data["words"]:
        if w["fr"] in spec["widen"] and w["en"] != spec["widen"][w["fr"]]:
            w["en"] = spec["widen"][w["fr"]]
            changed = True
    for k, (home, e, _) in placement.items():
        if home == f:
            data["words"].append(e)
            changed = True
    if changed:
        save(f, text, data)
        print("wrote", Path(f).name)
