#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
"${CARAMBOLE_AUDIO_PYTHON:-python3}" "$repo_root/tools/situations/audio_release_gate.py"
cd "$repo_root"
exec xcodebuild -project carambole.xcodeproj -scheme carambole -configuration Release "$@"
