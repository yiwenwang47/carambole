"""What runs while the main thread is off-CPU during a switch freeze.

usage: gap.py <run> <segment> [top]
Finds the longest main-thread sample gap in the first 600 ms of the segment
and lists, per thread, the heaviest frames sampled during it.
"""
import sys
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict

from profile import export, segments


def all_threads(run: str):
    ids: dict[str, ET.Element] = {}
    for _, row in ET.iterparse(export(run, "time-profile")):
        if row.tag != "row":
            continue
        for e in row.iter():
            if "id" in e.attrib:
                ids[e.attrib["id"]] = e

        def get(tag):
            e = row.find(tag)
            return ids.get(e.attrib["ref"], e) if e is not None and "ref" in e.attrib else e

        th = get("thread")
        bt = get("tagged-backtrace")
        bt = bt if bt is not None else get("backtrace")
        frames = []
        if bt is not None:
            for f in bt.iter("frame"):
                f = ids.get(f.attrib["ref"], f) if "ref" in f.attrib else f
                frames.append(f.attrib.get("name", "?"))
        yield int(get("sample-time").text), int(get("weight").text), th.attrib.get("fmt", "?"), frames
        row.clear()


run, seg = sys.argv[1], sys.argv[2]
top = int(sys.argv[3]) if len(sys.argv) > 3 else 8
a, b = next((x, y) for n, x, y in segments(run) if n == seg)
rows = [r for r in all_threads(run) if a <= r[0] < min(b, a + 600_000_000)]
main = [r[0] for r in rows if r[2].startswith("Main Thread")]
gaps = sorted(((main[i + 1] - main[i], main[i]) for i in range(len(main) - 1)), reverse=True)[:3]
print("largest main gaps (ms @ offset ms):", [(round(g / 1e6), round((t - a) / 1e6)) for g, t in gaps])
g, t0 = gaps[0]
per = defaultdict(Counter)
busy = Counter()
for t, w, th, frames in rows:
    if t0 < t < t0 + g:
        busy[th] += w / 1e6
        for f in dict.fromkeys(frames):
            per[th][f] += w / 1e6
for th, ms in busy.most_common(6):
    print(f"\n{ms:6.1f} ms  {th}")
    for f, v in per[th].most_common(top):
        print(f"   {v:5.1f}  {f[:130]}")
