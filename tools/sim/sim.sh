#!/bin/zsh
# Simulator harness for Carambole visual checks. See README.md.
#   sim.sh build                     build Debug for $CB_SIM into $CB_DD
#   sim.sh install                   install that build (app data kept)
#   sim.sh load-db <file.sqlite>     replace the sim app's database with a copy of <file>
#   sim.sh launch [KEY=VAL ...]      relaunch with CB_* env, e.g. CB_DRILL_DEMO=el_si_synthese_01
#   sim.sh remote <action>           DemoRemote nav: openBook, openModules, startReview, ...
#   sim.sh shot <out.png>            screenshot
#   sim.sh record <out.mov> <secs>   screen recording (delete it after extracting frames!)
#   sim.sh frames <mov> <dir> <t0> <t1> <step>   extract exact-time JPEG frames
#   sim.sh clean                     delete $CB_DD, frames/recordings under $CB_OUT
set -euo pipefail
ROOT=${0:A:h:h:h}
SIM=${CB_SIM:-48420336-6EA1-4545-A656-1DF72A82089E}   # iPhone 18 Pro, iOS 27.0
DD=${CB_DD:-${TMPDIR%/}/cb-sim-dd}
OUT=${CB_OUT:-${TMPDIR%/}/cb-sim-out}
BID=${CB_BUNDLE:-wen.carambole}
APP="$DD/Build/Products/Debug-iphonesimulator/carambole.app"
cmd=${1:-help}; shift || true
case $cmd in
  build)   xcrun simctl boot $SIM 2>/dev/null || true
           xcodebuild -project $ROOT/carambole.xcodeproj -scheme carambole \
             -destination "id=$SIM" -derivedDataPath $DD ${CB_BUNDLE:+PRODUCT_BUNDLE_IDENTIFIER=$CB_BUNDLE} \
             build -quiet ;;
  install) xcrun simctl install $SIM $APP ;;
  load-db) xcrun simctl terminate $SIM $BID 2>/dev/null || true
           D=$(xcrun simctl get_app_container $SIM $BID data)/Documents
           rm -f $D/carambole.sqlite $D/carambole.sqlite-wal $D/carambole.sqlite-shm
           cp "$1" $D/carambole.sqlite ;;
  launch)  xcrun simctl terminate $SIM $BID 2>/dev/null || true
           env ${(@)@/#/SIMCTL_CHILD_} xcrun simctl launch $SIM $BID ;;
  remote)  xcrun simctl spawn $SIM notifyutil -p cb.demo.$1 ;;
  shot)    xcrun simctl io $SIM screenshot "$1" ;;
  record)  xcrun simctl io $SIM recordVideo -f "$1" & p=$!; sleep $2; kill -INT $p; wait $p ;;
  frames)  mkdir -p $OUT; [[ -x $OUT/frames ]] || swiftc -O ${0:A:h}/frames.swift -o $OUT/frames
           $OUT/frames "$@" ;;
  clean)   rm -rf $DD $OUT ${TMPDIR%/}/instruments*.ktrace(N)
           df -h /System/Volumes/Data | tail -1 ;;
  *)       sed -n 2,12p $0 ;;
esac
