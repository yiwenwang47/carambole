#!/bin/zsh
# usage: run.sh <name> [ENV=1 ...]
D=00008160-001A09920AA0000A
cd "${0:A:h}/out" 2>/dev/null || { mkdir -p "${0:A:h}/out"; cd "${0:A:h}/out"; }
name=$1; shift
envs=(--env CB_PERF=1)
for e in "$@"; do envs+=(--env $e); done
rm -rf $name.trace
xcrun xctrace record --template "${TEMPLATE:-Animation Hitches}" --device $D --time-limit ${LIMIT:-90s} --output $name.trace $envs --launch -- wen.carambole > $name.xctrace.log 2>&1
xcrun devicectl device copy from --device $D --domain-type appDataContainer --domain-identifier wen.carambole --source Documents/perf.json --destination $name.json > /dev/null 2>&1
echo "$name done: $(tail -1 $name.xctrace.log)"
