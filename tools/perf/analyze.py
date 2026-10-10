"""Join Instruments hitches with harness segments. usage: analyze.py run1 run2 ..."""
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).parent / "out"


def export(run: str, schema: str) -> ET.Element:
    cache = HERE / f"{run}.{schema}.xml"
    if not cache.exists():
        xml = subprocess.run(
            ["xcrun", "xctrace", "export", "--input", str(HERE / f"{run}.trace"), "--xpath",
             f'/trace-toc/run[@number="1"]/data/table[@schema="{schema}"]'],
            capture_output=True, text=True, check=True).stdout
        cache.write_text(xml)
    return ET.parse(cache).getroot()


def rows(root: ET.Element) -> list[list[ET.Element]]:
    ids: dict[str, ET.Element] = {}
    out = []
    for row in root.iter("row"):
        cells = []
        for c in row:
            if "ref" in c.attrib:
                c = ids[c.attrib["ref"]]
            else:
                for e in c.iter():
                    if "id" in e.attrib:
                        ids[e.attrib["id"]] = e
            cells.append(c)
        out.append(cells)
    return out


def analyze(run: str) -> dict:
    ti = rows(export(run, "time-info"))[0]
    mach0 = int(ti[1].text)
    num, den = (int(f.text) for f in ti[3].iter("mach-timebase-info-field"))
    hitches = []
    for r in rows(export(run, "hitches")):
        start, dur = int(r[0].text), int(r[1].text)
        proc = r[2].attrib.get("fmt", "")
        why = r[7].attrib.get("fmt", "") if len(r) > 7 else ""
        hitches.append((start, dur, proc, why))
    perf = json.loads((HERE / f"{run}.json").read_text())
    out = {}
    for seg in perf["results"]:
        if "startMach" not in seg:
            continue
        a = (seg["startMach"] - mach0) * num // den
        b = (seg["endMach"] - mach0) * num // den
        hs = [h for h in hitches if a <= h[0] < b]
        whys = defaultdict(int)
        for h in hs:
            whys[h[3]] += 1
        out[seg["segment"]] = {
            "n": len(hs), "ms": sum(h[1] for h in hs) / 1e6,
            "ratio": sum(h[1] for h in hs) / 1e6 / ((b - a) / 1e9),
            "worst": max((h[1] for h in hs), default=0) / 1e6,
            "why": dict(whys), "main_worst": seg["worstFrameMs"], "depth": seg["depth"],
        }
    out["_total"] = {"n": len(hitches), "ms": sum(h[1] for h in hitches) / 1e6}
    return out


if __name__ == "__main__":
    runs = sys.argv[1:]
    res = {r: analyze(r) for r in runs}
    (HERE / "summary.json").write_text(json.dumps(res, indent=1))
    segs = [s for s in res[runs[0]] if not s.startswith("_")]
    print("hitch ms per segment (count)   [Instruments, all hitch types]")
    print(f"{'segment':16}" + "".join(f"{r:>16}" for r in runs))
    for s in segs:
        print(f"{s:16}" + "".join(
            f"{res[r].get(s, {}).get('ms', 0):10.0f} ({res[r].get(s, {}).get('n', 0):2d})" for r in runs))
    print(f"{'TOTAL trace':16}" + "".join(f"{res[r]['_total']['ms']:10.0f} ({res[r]['_total']['n']:2d})" for r in runs))
    print("\nhitch reasons per run:")
    for r in runs:
        agg = defaultdict(int)
        for s in segs:
            for k, v in res[r].get(s, {}).get("why", {}).items():
                agg[k] += v
        print(" ", r, dict(agg))
