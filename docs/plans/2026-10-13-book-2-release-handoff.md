# Book 2 handoff: start here (done, installed on the phone)

**Written:** 2026-10-13, end of session.
**Repo:** `carambole/`, branch `main`, **pushed**.
**Previous start point:** [arc 5 done handoff](../archive/plans/2026-10-13-book-2-arc5-done-handoff.md). Its §0 has this session's commits and the release check in detail.

## 1. Start here: install on the phone

The user asked to do the installation in this session.

1. Ask which build to install: the main Carambole app (`wen.carambole`), the Test book (`wen.carambole.testbook`), or both. The phone has Test book v10 and an older main app.
2. Check that the phone is connected and unlocked: `xcrun devicectl list devices`.
3. Install with the commands in §4.
4. Ask the user to check the items in §2 on the phone. Never test, record or profile on the phone yourself.

## 2. Checks only the phone can do

- **Background audio:** play music, then play a clip in the app. The music should drop while the clip plays and come back to full volume after it (`4511111a`). The simulator can't show this.
- **Interruption:** a call or Siri during a clip, then go back to the app.
- **VoiceOver:** one Book 2 dialogue from the start to the summary, by swiping.
- **Real taps:** Apprendre and Réviser in both books, hint bubbles, the History "Erreurs" tab.
- **Book 1 progress:** the main app keeps its progress after the install. On the simulator, the real v4 export upgraded to v5 with every row kept.

## 3. State

| Area | State |
|---|---|
| Content | 25 modules, 3,000 items, 2,194 glosses. No gloss is longer than 60 characters. |
| Audio | 6,459 / 6,459 clips, all normalised. |
| Hint bubble | Wraps (at most 260 pt), stays on screen. The last bracket group shows as a small grey second line. |
| Simulator (iPhone 18 Pro) | Test book with all of the above, including today's fixes. The main app's simulator database was restored to what it was before the release check. |
| Checks | All lints and tests pass (Book 1 lints, Book 2 strict lint, 88 + 57 Python tests, pilot tests, Swift model test, Debug and Release builds). |
| Release build | No `CB_*` flags. `testbook_*.json` and `pilot2_*` clips are excluded (`EXCLUDED_SOURCE_FILE_NAMES`, Release only). |

Fixed this session, after the release check:
- `4511111a` Speaker releases the audio session when a clip ends or is stopped.
- `7d767cc7` On small screens, the oldest chat line fades out under the cue.
- `f11705c1` Book 2 Réglages say "conversation moves" and "dialogues".
- `cb66c215` Test book files are kept out of Release builds.

## 4. Commands

```sh
# main app on the phone
xcodebuild -project carambole.xcodeproj -scheme carambole -configuration Debug -destination 'id=00008160-001A09920AA0000A' -allowProvisioningUpdates DEVELOPMENT_TEAM=QMV4SPL476 -derivedDataPath /tmp/cb-device build -quiet
xcrun devicectl device install app --device 00008160-001A09920AA0000A /tmp/cb-device/Build/Products/Debug-iphoneos/carambole.app

# Test book on the phone
xcodebuild -project carambole.xcodeproj -scheme carambole -configuration Debug -destination 'id=00008160-001A09920AA0000A' -allowProvisioningUpdates DEVELOPMENT_TEAM=QMV4SPL476 PRODUCT_BUNDLE_IDENTIFIER=wen.carambole.testbook INFOPLIST_KEY_CFBundleDisplayName='Test book' -derivedDataPath /tmp/cb-book2-pilot-device build -quiet
xcrun devicectl device install app --device 00008160-001A09920AA0000A /tmp/cb-book2-pilot-device/Build/Products/Debug-iphoneos/carambole.app
xcrun devicectl device process launch --terminate-existing --device 00008160-001A09920AA0000A wen.carambole.testbook
```

Afterwards, delete `/tmp/cb-device` and `/tmp/cb-book2-pilot-*`.

## 5. Later

- The Écrire typing drill, in its own session.
- Release-mode install (optional): add `-configuration Release` to the main app build. It drops the Test book files.

## 6. Done (later on 2026-10-13)

The main app is installed on the iPhone 18 Pro from `main` (`37df6776`). The user checked every item in §2 on the phone and it passed.

Fixed in this session:
- `d0d766cb`, `37df6776`: background music. The silent star video keeps the audio session active. Changing the category on an active session stopped Apple Music. Now: `.ambient` outside clips; for each clip, release → `.playback` + `[.mixWithOthers, .duckOthers]` → activate; then release with notify → `.ambient`. The phone log confirms that music keeps playing and is lowered during clips. Debug builds write `Documents/audio_diag.txt`.
- `53f123a8`: "Trop facile" in Book 2, with the same code and logic as Book 1 (`Features/Drill/TooEasy.swift`). This is a hard rule for every book (CLAUDE.md).
- The `round-history` branch and worktree are deleted. Only `main` is left.

Book 2 is done.

## 7. Final state (end of 2026-10-13)

- **Phone:** a **Release** build of `main` is installed (`wen.carambole`). It has no Test book files, no `CB_*` flags and no audio log. The Test book app was uninstalled at the user's request.
- **Repo:** only `main`, clean and pushed. `CLAUDE.md` is trimmed to the current rules, commands and open items. Finished plans are in `docs/archive/` (`git mv`, history kept), and references point there. The 3.9 GB of old Instruments traces (`tools/perf/out`) and the caches were deleted.
- **Kept by decision:** `tools/situations/drafts/`. `assemble.py` builds every Book 2 module and `words.json` from it, and `apply_gloss_spec.py` edits it. It is the source for any later Book 2 content fix.
- **Kept:** the Test book code (`carambole/Debug/`, `pilot2_*` clips, `tools/pilot/`). Debug builds only; use it for hand testing new drills.

Still open, each only when the user asks:
- The Écrire typing drill, in its own session.
- The other open items in `CLAUDE.md` (Book 1 English explanations, Iris iridescence, the remaining swipe-back guards, stutter leads).
