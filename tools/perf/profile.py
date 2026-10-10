"""Main-thread Time Profiler breakdown per harness segment.

usage: profile.py <run> [segment ...]   (run recorded with TEMPLATE='Time Profiler')

For each segment, prints main-thread ms and the heaviest frames by inclusive
time: app frames (carambole) and notable framework frames.
"""
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

HERE = Path(__file__).parent / "out"


def export(run: str, schema: str) -> Path:
    cache = HERE / f"{run}.{schema}.xml"
    if not cache.exists():
        xml = subprocess.run(
            ["xcrun", "xctrace", "export", "--input", str(HERE / f"{run}.trace"), "--xpath",
             f'/trace-toc/run[@number="1"]/data/table[@schema="{schema}"]'],
            capture_output=True, text=True, check=True).stdout
        cache.write_text(xml)
    return cache


def samples(run: str) -> list[tuple[int, int, list[tuple[str, str]]]]:
    """(time ns, weight ns, [(frame name, binary)] leaf first) for main-thread rows."""
    ids: dict[str, ET.Element] = {}
    out = []
    for _, row in ET.iterparse(export(run, "time-profile")):
        if row.tag != "row":
            continue
        for e in row.iter():
            if "id" in e.attrib:
                ids[e.attrib["id"]] = e

        def get(tag: str) -> ET.Element | None:
            e = row.find(tag)
            return ids.get(e.attrib["ref"], e) if e is not None and "ref" in e.attrib else e

        thread = get("thread")
        if thread is None or not thread.attrib.get("fmt", "").startswith("Main Thread"):
            continue
        bt = get("tagged-backtrace")
        bt = bt if bt is not None else get("backtrace")
        frames = []
        if bt is not None:
            for f in bt.iter("frame"):
                f = ids.get(f.attrib["ref"], f) if "ref" in f.attrib else f
                b = f.find("binary")
                if b is not None and "ref" in b.attrib:
                    b = ids.get(b.attrib["ref"])
                frames.append((f.attrib.get("name", "?"), b.attrib.get("name", "") if b is not None else ""))
        out.append((int(get("sample-time").text), int(get("weight").text), frames))
        row.clear()
    return out


def segments(run: str) -> list[tuple[str, int, int]]:
    """(name, begin ns, end ns) from the harness's os_signpost intervals."""
    ids: dict[str, ET.Element] = {}
    open_: dict[str, tuple[str, int]] = {}
    out = []
    for _, row in ET.iterparse(export(run, "os-signpost")):
        if row.tag != "row":
            continue
        for e in row.iter():
            if "id" in e.attrib:
                ids[e.attrib["id"]] = e
        cells = {c.tag: ids.get(c.attrib["ref"], c) if "ref" in c.attrib else c for c in row}
        sub = cells.get("subsystem")
        if sub is None or sub.attrib.get("fmt") != "wen.carambole.perf":
            continue
        t = int(cells["event-time"].text)
        sid = cells["os-signpost-identifier"].attrib.get("fmt", "")
        kind = cells["event-type"].attrib.get("fmt")
        if kind == "Begin":
            open_[sid] = (cells["os-log-metadata"].attrib.get("fmt", "?"), t)
        elif kind == "End" and sid in open_:
            name, a = open_.pop(sid)
            out.append((name, a, t))
    return out


def main() -> None:
    burst_only = "--burst" in sys.argv
    args = [x for x in sys.argv[1:] if x != "--burst"]
    run, wanted = args[0], set(args[1:])
    perf = {s["segment"]: s for s in json.loads((HERE / f"{run}.json").read_text())["results"]}
    all_samples = samples(run)
    for name, a, b in segments(run):
        if wanted and name not in wanted:
            continue
        seg = perf.get(name, {"segment": name})
        ss = [s for s in all_samples if a <= s[0] < b]
        # The freeze: longest run of back-to-back main-thread samples (gap < 3 ms).
        bursts, cur = [], []
        for smp in ss:
            if cur and smp[0] - cur[-1][0] > 3_000_000:
                bursts.append(cur)
                cur = []
            cur.append(smp)
        if cur:
            bursts.append(cur)
        if burst_only and bursts:
            ss = max(bursts, key=lambda r: sum(w for _, w, _ in r))
            a, b = ss[0][0], ss[-1][0] + ss[-1][1]
        total = sum(w for _, w, _ in ss) / 1e6
        app, fw = Counter(), Counter()
        for _, w, frames in ss:
            seen = set()
            for name, binary in frames:
                key = (name, binary)
                if key in seen:
                    continue
                seen.add(key)
                (app if binary == "carambole" else fw)[name] += w / 1e6
        print(f"\n=== {seg['segment']}  main busy {total:.0f} ms / {(b - a) / 1e6:.0f} ms"
              f"  worst frame {seg.get('worstFrameMs', 0):.0f} ms")
        for name, ms in app.most_common(14):
            print(f"  app {ms:6.1f}  {name[:120]}")
        for name, ms in fw.most_common(40):
            if any(k in name for k in ("RealityKit", "RealityView", "Mesh", "Entity", "Material", "Text",
                                       "CoreText", "Shader", "Metal", "MTL", "Font", "layout", "Layout",
                                       "Graph", "update", "render", "commit", "Commit")):
                print(f"  fw  {ms:6.1f}  {name[:120]}")


if __name__ == "__main__":
    main()
