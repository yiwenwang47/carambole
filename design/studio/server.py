#!/usr/bin/env python3
"""Carambole design studio: a tiny local server for mark reviews and drag layouts.

Serves this folder on http://127.0.0.1:8765 and stores what the user saves:
  GET  /api/prefs/<name>  -> prefs/<name>.json (or {})
  POST /api/prefs/<name>  -> writes prefs/<name>.json, appends to prefs/history.jsonl

Run: python3 design/studio/server.py   (localhost only)
"""

from __future__ import annotations

import http.server
import json
import re
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PREFS = ROOT / "prefs"
PORT = 8765
NAME = re.compile(r"^[a-z0-9-]{1,40}$")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def _name(self) -> str | None:
        if not self.path.startswith("/api/prefs/"):
            return None
        name = self.path.removeprefix("/api/prefs/").split("?")[0]
        return name if NAME.match(name) else None

    def _json(self, code: int, body: bytes) -> None:
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def end_headers(self) -> None:
        # Always serve the latest mock files while iterating.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self) -> None:
        if self.path.startswith("/api/"):
            name = self._name()
            if name is None:
                return self._json(400, b'{"error":"bad name"}')
            path = PREFS / f"{name}.json"
            return self._json(200, path.read_bytes() if path.exists() else b"{}")
        super().do_GET()

    def do_POST(self) -> None:
        name = self._name()
        if name is None:
            return self._json(400, b'{"error":"bad name"}')
        length = int(self.headers.get("Content-Length", "0"))
        if length > 1_000_000:
            return self._json(413, b'{"error":"too large"}')
        try:
            data = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            return self._json(400, b'{"error":"bad json"}')
        PREFS.mkdir(exist_ok=True)
        stamp = time.strftime("%Y-%m-%d %H:%M:%S")
        data["savedAt"] = stamp
        (PREFS / f"{name}.json").write_text(json.dumps(data, indent=2, ensure_ascii=False))
        with (PREFS / "history.jsonl").open("a") as f:
            f.write(json.dumps({"name": name, "at": stamp, "data": data}, ensure_ascii=False) + "\n")
        self._json(200, json.dumps({"ok": True, "savedAt": stamp}).encode())

    def log_message(self, fmt: str, *args) -> None:
        if self.command == "POST":
            super().log_message(fmt, *args)


if __name__ == "__main__":
    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"Carambole studio on http://127.0.0.1:{PORT}/", flush=True)
    server.serve_forever()
