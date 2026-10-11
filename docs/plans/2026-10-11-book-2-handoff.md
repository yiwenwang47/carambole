# Book 2 handoff

**Date:** 2026-10-11  
**Repo:** `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole`  
**Branch:** `book2-dialogue-pilot`  
**Pilot UI commit:** `8aafdad` (`Show situation text by default in Test book`)

## Read first

1. Read the [Book 2 action plan](2026-10-11-book-2-action-plan.md). It contains the syllabus, research links, architecture, tasks, and gates.
2. Read the [earlier Book 2 decision](../decisions/2026-10-10-next-book.md).
3. Follow the repo instructions in `AGENTS.md` and `/Users/yiwenwang/.codex/RTK.md`. Prefix shell commands with `rtk`.

## User decisions

- Build a second French book about practical exchanges and useful replies. *En situation* is the working title.
- Keep the two books completely independent in the app. Separate their content, progress, review schedule, history, settings, unlocks, and completion.
- Respect the current codebase. Reuse the existing book model, drill flow, scheduler, and design where practical.
- The proposed full size is 25 modules, 200 review elements, and 800 varied exchanges. This is a plan, not finished content.
- The French exchange text must be visible from the start. The user tried the audio-first phone pilot and said that drills without visible text were too hard. Audio remains available to play and replay. Reading does not count as a hint.

## What exists now

- A four-scene café difficulty pilot runs in the DEBUG **Test book** app. Open **Test book → En situation · essai**.
- The scenes form one story: unavailable oat milk, a food delay, a takeaway misunderstanding, and a broken card terminal.
- Each scene shows a French two-speaker exchange, asks an English comprehension question, then asks the learner to build a useful French reply.
- The pilot has 12 bundled MP3 files: a two-voice exchange, model reply, and follow-up for each scene.
- The pilot keeps state in memory. It is separate from Book 1. The full Book 2 content, storage isolation, and shelf entry do not exist yet.

Key files:

| File | Purpose |
|---|---|
| `carambole/Debug/DrillDemo.swift` | Adds the Test book entry point. |
| `carambole/Debug/SituationPilotView.swift` | Runs the four-scene pilot. Shows text from the start. |
| `carambole/Debug/PilotScenario.swift` | Decodes and validates the pilot contract. |
| `carambole/Debug/testbook_situation.json` | Holds the four scenes and accepted replies. |
| `carambole/Resources/Audio/pilot_*.mp3` | Holds the 12 audio clips. |
| `tools/pilot/test_content.py` | Checks content and shorter valid replies. |
| `tools/pilot/PilotScenarioTests.swift` | Checks the Swift scenario model. |
| `tools/pilot/generate_audio.py` | Regenerates pilot audio through Google TTS. |

## Checks and phone state

- Five Python content tests passed.
- The Swift scenario test passed.
- The Debug simulator build and signed device build passed after the visible-text change.
- A simulator screenshot showed the French turns and comprehension question together. The reply and feedback layouts were checked earlier.
- The revised Test book app was installed and launched on the connected iPhone 18 Pro. Its bundle ID is `wen.carambole.testbook`.
- A human has not yet reported difficulty after the visible-text change. A human has not yet checked pronunciation, voice contrast, or loudness on the phone.

The device ID used in this session was `00008160-001A09920AA0000A`. The simulator ID was `48420336-6EA1-4545-A656-1DF72A82089E`. Device IDs can change or become unavailable.

## Next session

1. Start from the action plan and this handoff. Check the branch and current file state before edits.
2. Use the user's next feedback on the visible-text pilot to set the difficulty. Do not restore the hidden transcript.
3. If the user asks for the full book, build the eight-element café content pilot first. Use the action plan's task gates before bulk authoring.
4. Scope every progress query and setting by book. In particular, fix the global overflow query before both books can have review items.
5. Keep Book 1 IDs, JSON, audio keys, and existing settings keys stable. Test an existing database as well as a fresh install.
6. Keep the action plan and this handoff current after each milestone.

## Build commands used

Run these from the repo directory. Use a current destination ID if the listed device is unavailable.

```sh
rtk python3 -m unittest tools/pilot/test_content.py
rtk proxy swiftc -D DEBUG carambole/Debug/PilotScenario.swift tools/pilot/PilotScenarioTests.swift -o /tmp/cb-pilot-scenario-tests
rtk proxy /tmp/cb-pilot-scenario-tests
rtk xcodebuild -project carambole.xcodeproj -scheme carambole -configuration Debug -destination 'id=48420336-6EA1-4545-A656-1DF72A82089E' PRODUCT_BUNDLE_IDENTIFIER=wen.carambole.testbook INFOPLIST_KEY_CFBundleDisplayName='Test book' CODE_SIGNING_ALLOWED=NO -derivedDataPath /tmp/cb-book2-pilot-sim build -quiet
rtk xcodebuild -project carambole.xcodeproj -scheme carambole -configuration Debug -destination 'id=00008160-001A09920AA0000A' -allowProvisioningUpdates DEVELOPMENT_TEAM=QMV4SPL476 PRODUCT_BUNDLE_IDENTIFIER=wen.carambole.testbook INFOPLIST_KEY_CFBundleDisplayName='Test book' -derivedDataPath /tmp/cb-book2-pilot-device build -quiet
```

For device install and launch, see `tools/sim/README.md`. Do all tests and profiling on the simulator. The phone is for a signed install and a human listening pass.
