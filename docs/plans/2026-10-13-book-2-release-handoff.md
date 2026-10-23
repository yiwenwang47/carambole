# Book 2 handoff: start here (done, installed on the phone)

**Written:** 2026-10-13, end of session.
**Original release branch:** `main`, pushed.
**Latest update:** 2026-10-22, per-drill "Trop facile" (§15), Release build installed on the iPhone.
**Previous start point:** [arc 5 done handoff](../archive/plans/2026-10-13-book-2-arc5-done-handoff.md). Its §0 has this session's commits and the release check in detail.

## 1. Current phone state

The main Carambole app (`wen.carambole`) received a Release build on 2026-10-22 (`6e454f78`). It includes the per-drill "Trop facile" in §15, the gap-word bubble fix (`91715627`), and everything before it. Book 3 is archived and not in the app. Only the user checks behavior on the phone; do not test, record, or profile there.

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
| Simulator (iPhone 18 Pro) | The Test book showed the Book 2 layout in §10. It was uninstalled after the check. |
| Checks | The latest Book 2 strict lint, 98 Python tests, Swift model test, Test book build, and Release phone build passed. |
| Release build | No `CB_*` flags. `testbook_*.json` and `pilot2_*` clips are excluded (`EXCLUDED_SOURCE_FILE_NAMES`, Release only). |

Fixed this session, after the release check:
- `4511111a` Speaker releases the audio session when a clip ends or is stopped.
- `7d767cc7` On small screens, the oldest chat line fades out under the cue.
- `f11705c1` Book 2 Réglages say "conversation moves" and "dialogues".
- `cb66c215` Test book files are kept out of Release builds.

## 4. Commands

```sh
# Release app on the phone (audio gate runs before xcodebuild)
CARAMBOLE_AUDIO_PYTHON=/path/to/python-with-numpy-scipy-lameenc tools/release_build.sh -destination 'id=00008160-001A09920AA0000A' -allowProvisioningUpdates DEVELOPMENT_TEAM=QMV4SPL476 -derivedDataPath /tmp/cb-device build -quiet
xcrun devicectl device install app --device 00008160-001A09920AA0000A /tmp/cb-device/Build/Products/Release-iphoneos/carambole.app

# Test book on the phone
xcodebuild -project carambole.xcodeproj -scheme carambole -configuration Debug -destination 'id=00008160-001A09920AA0000A' -allowProvisioningUpdates DEVELOPMENT_TEAM=QMV4SPL476 PRODUCT_BUNDLE_IDENTIFIER=wen.carambole.testbook INFOPLIST_KEY_CFBundleDisplayName='Test book' -derivedDataPath /tmp/cb-book2-pilot-device build -quiet
xcrun devicectl device install app --device 00008160-001A09920AA0000A /tmp/cb-book2-pilot-device/Build/Products/Debug-iphoneos/carambole.app
xcrun devicectl device process launch --terminate-existing --device 00008160-001A09920AA0000A wen.carambole.testbook
```

Afterwards, delete `/tmp/cb-device` and `/tmp/cb-book2-pilot-*`.

## 5. Later

- The Écrire typing drill, in its own session.

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

## 8. Book 2 card slide (2026-10-15)

Commit `851acd59` indexes the 2,194 glossary keys once per Book 2 session. `SituationCardView` uses that index for each dialogue line. It no longer scans the full glossary during every card update.

The Test book autoplay ran in the iPhone 18 Pro simulator. In comparable runs of about 35 seconds, segmentation used 3,238 ms of sampled CPU time before the fix and 31 ms after it. The largest continuous main-thread busy stretch fell from about 231 ms to 47 ms. These are CPU sample estimates, not frame times. Animation Hitches is unavailable on this simulator. A 30 fps frame strip showed the next card moving across the screen without a visible jump.

The Release build, Book 2 model tests, and situation lint passed. The model tests loaded all 3,000 items. The Python suite ran 98 tests with one skip. `devicectl` installed the main Release app from `851acd59` on the paired iPhone 18 Pro (`wen.carambole`). The fix branch and worktree were removed after a fast-forward merge to `main`.

## 9. Nouveaux mots chip wrapping (2026-10-15)

The finished Book 2 card used `FlowLayout` for new-word chips. It measured every chip at unlimited width, so a long gloss such as `la bise · cheek kiss (greeting) (faire la bise = to greet with a kiss)` extended past the grey chip and the screen edge. `FlowLayout` now remeasures an oversized child at the available row width, and the chip text can grow vertically. Normal-width chips keep their intrinsic size.

The iPhone 18 Pro simulator reproduced the overflow before the fix. With the same `la bise` text, the full gloss wrapped inside the chip on two lines afterward. The dedicated Test book app also showed its original long `faire le pont` gloss wrapped inside the chip. The temporary `la bise` Test book fixture was restored; no content changed.

Commit `fcd8f539` was fast-forward merged to `main`. The strict situation lint, Swift model test (3,000 items), and Python suite (98 tests, one skip) passed. A Release build from the merged tree succeeded, and `devicectl` installed `wen.carambole` on the paired iPhone 18 Pro. Phone behavior remains for the user to check.

## 10. Book 2 drill layout (2026-10-15)

Commit `ee721aca` removes the place header and English setup cue from each Book 2 drill card. A drill shows `#tu` or `#vous` only when its active prompt, answer, or choices use that distinction. The tag uses the former setup cue's text size and color. Other drills have no top cue.

Chat bubbles have smaller side margins. The purple reply bank shows every word tile at full height and does not scroll or collapse. Only the chat scrolls. The gap below the bank is smaller.

The user approved the layout in the iPhone 18 Pro Test book simulator. The reply card at index 7 showed five candidates across four rows with `#tu`. The conditional card at index 5 showed seven candidates with no address tag. Empty, filled, dialogue, and finished states were also checked.

The strict situation lint passed for 25 modules. The Swift model test loaded all 3,000 items, and 98 Python tests passed with the Conda Python that has the audio dependencies. The Test book simulator build and the signed Release phone build passed. `devicectl` installed `wen.carambole` on the paired iPhone 18 Pro. The agent did not test the phone.

The change was fast-forward merged into `book3-pilot` and pushed to `origin/book3-pilot`. `main` was not changed in this round. The feature worktree, local branch, simulator Test book app, and temporary build caches were removed.

## 11. Audio audit and Studio A line (2026-10-16)

The user selected Studio A for Léa's « C'était top, hier ! À refaire ! ».
`sit_04_thank_d03_t0.mp3` is the selected sample. The line keeps its IPA
pronunciation in `tts_overrides.json`, and `VOICE_OVERRIDES` in
`generate_audio.py` keeps Studio A on regeneration. The original, earlier
replacement, three model candidates, and representative pause repairs are in
`docs/reports/book2_audio_before_after.html` with local MP3 files.

The audit checked all 6,459 Book 2 clips and found zero unresolved issues after
the conservative pause repair. Future production books with bundled audio must
register their clip index in `tools/situations/audio_books.json`; the Release
build wrapper blocks missing or unresolved audio. Signal checks cannot judge
pronunciation or intonation. The signed Release build passed the gate and was
installed on the paired iPhone 18 Pro. The agent did not test on the phone.

## 12. Final phone delivery (2026-10-16)

The Release build of `main` at `a40cadd0` ran through `tools/release_build.sh`.
The registered Book 2 audit checked 6,459 clips and found zero unresolved
findings. The signed build succeeded, and `devicectl` installed
`wen.carambole` on the connected iPhone 18 Pro. The audit rule remains in
`CLAUDE.md`, `tools/situations/README.md`, and the release wrapper. The agent
did not launch or test the app on the phone.

## 13. Book 2 unit completion (2026-10-17)

The fixed first pass through a Book 2 unit could end after its initial cards even
when one or more elements had no correct answer. At the end of that pass, the
learn session now adds another card for each unintroduced element. It repeats
until every element has a correct answer or a clean “Trop facile” grade. There
is no fixed drill-count limit for finishing a unit.

The module list now shows **Appris** when all its elements have been introduced
correctly. A wrong attempt does not finish the unit or unlock the next one.
**Maîtrisé** and the book progress bar still mean long-term FSRS graduation after
spaced reviews. Existing progress is read from `review_status`; no migration is
needed.

The Swift model test passed across all 3,000 items, 116 Python tests passed,
and the release audio gate checked 6,459 clips with zero unresolved findings.
The signed Release build succeeded, and `devicectl` installed `wen.carambole`
on the paired iPhone 18 Pro. Phone behavior remains for the user to check.

## 14. Hidden-cue drills (2026-10-18)

The user hit `sit_10_door_d01`: "Say yes, and give him the code" with
« deux, cinq, huit » and « deux, six, huit » in the bank. The code was only in
the English cue, which dialogue cards have hidden since `ee721aca` (§10).

Commit `35ef8d60`:
- **Persona:** `situations_manifest.json` has `persona` ("You're Robin, a woman
  from Eugene, Oregon."). Every Book 2 Leçon intro shows it once under
  **Vous**. Cards don't repeat it.
- **Content:** all 2,000 dialogue items were reviewed against what the card
  shows. Seven prompts now carry the missing fact: `sit_06_available_d06`,
  `sit_06_mixup_d02`, `sit_06_mixup_d04`, `sit_10_door_d01`,
  `sit_10_door_d08`, `sit_13_late_d06`, `sit_25_gite_d10`. The door-code cues
  use digits (2-5-8), which also stops `sit_10_door_s01` showing the answer.
- **Address tag:** `addressTag(for:)` now shows the scene's `#tu`/`#vous` when
  the choices differ only by verb ending (*tourne* / *tournez*,
  *Excuse-moi* / *Excusez-moi*, *regarde* / *regardez*).
- **Lint:** `lint.py` fails a dialogue whose answer appears only in the cue
  (`cue_only_answers`, with a unit test).

The strict lint, 117 Python tests and the Swift model test (3,000 items)
passed. The simulator showed the Leçon persona line, the door card's new
prompt and `#vous` on `sit_13_late_d06`. The Release build passed the audio
gate, and `devicectl` installed `wen.carambole` on the iPhone 18 Pro. The agent
did not test on the phone.

## 15. Per-drill "Trop facile" (2026-10-22)

The user asked for "Trop facile" to belong to one drill, not the whole
dialogue. Before, an armed card resolved only when the dialogue finished, and
removed the element only if every drill was right first time.

Commit `6e454f78`:
- **Arm on one drill.** The gate resolves when that drill closes
  (`SituationCardView.closeDrill` → `SituationSessionView.resolveTooEasy`):
  right first time removes the element (.easy + suspend, undo pill); otherwise
  it cleans the element. The element's later cards leave the queue at once.
- **The rest of the card grades normally** (user's choice). The armed drill is
  left out of the card's normal grade (`SituationTooEasy.gradedOutcome`), so it
  never grades twice. The item log still keeps the whole dialogue's outcome.
- **Once per card.** After a drill resolves the gate, the control stays hidden
  for the rest of that card (`showsControl(..., resolved:)`).
- The shared `TooEasyGate` and Book 1 are unchanged.

Known effect: after a removal, a miss on a later drill of the same card grades
.again on the removed element. It stays suspended and maîtrisé (only Annuler
brings it back).

The Swift model test (new `gradedOutcome` and `resolved` cases, 3,000 items)
passed. On the simulator (`CB_SIT_ITEMS=sit_01_greet_d01,sit_01_greet_d02,sit_01_name_d01`,
`CB_SIT_TOO_EASY=1`, `CB_SIT_AUTOPLAY=1`), the frames showed the pill after
drill 1, the queue going from 3 to 2, and no control on drill 2. The database
had `sit_01_greet` suspended and graduated, with drill 2's grade on top. The
Release build passed the audio gate and was installed on the iPhone 18 Pro.
The agent did not test on the phone.
