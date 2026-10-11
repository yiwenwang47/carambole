# En situation — Book 2 action plan

> **For agentic workers:** Implement task by task with an independent review after each milestone. Track the checkboxes here and update this file as decisions change.

**Status:** Full-book plan revised 2026-10-11. User feedback: a hidden transcript makes the drills too hard. The pilot now shows the French exchange from the start; the revised Test book was installed and launched on the connected iPhone 18 Pro. Further difficulty feedback is pending. Full-book implementation has not started.

## Difficulty pilot checkpoint (2026-10-11)

The user worries the planned conversation book may be too easy and requested a phone pilot in the existing `wen.carambole.testbook` app. This probe stays in `carambole/Debug/` and does not change either production book's content, schedule, or data. It is a connected four-scene café story: an unavailable ingredient, a food wait longer than the train window, a takeaway misunderstanding, and a broken card terminal. Each scene requires listening inference followed by a constructed French reply; the third requires both correcting the assumption and asking for a box.

- Content: `carambole/Debug/testbook_situation.json`; four scenes, varied correct-choice positions, accepted reply alternatives.
- Test book UI: `carambole/Debug/SituationPilotView.swift`, launched from the existing `DrillDemo.swift` test book screen.
- Contract: `carambole/Debug/PilotScenario.swift`; focused Swift logic test `tools/pilot/PilotScenarioTests.swift` was observed failing before implementation and passing after.
- Content gate: `tools/pilot/test_content.py`; five tests pass, including shorter valid replies. The Swift scenario test also passes. Independent review found and we fixed a hidden listening correction and over-strict reply alternatives.
- Audio: `tools/pilot/generate_audio.py` generated 12 bundled MP3 files: two-voice dialogue plus model and follow-up for each scene. File format and bundle coverage pass; a human still needs to judge pronunciation, voice contrast, and loudness on the phone.
- Build and handoff: Debug simulator and signed device builds pass. The iPhone 18 Pro installed and launched bundle ID `wen.carambole.testbook` on 2026-10-11. Simulator screenshots show the reply and feedback screens with the footer action visible. Open **Test book → En situation · essai** to play all four scenes.
- Feedback-driven change: show the exchange text from the start on every scene, with audio as replay. Reading is normal use, not a graded hint. Keep this default for Book 2 unless later testing changes the decision. This revision was rebuilt, simulator checked, and reinstalled on the phone.
- Next: collect difficulty and audio feedback before expanding to the eight-element, 32-exchange content pilot or deciding how hard the complete book should be.

**Goal:** Build a second French book that trains learners to understand a short everyday exchange and form a useful response, applying grammar from *Fondations*.

**Architecture:** Reuse the existing `Book → CourseModule → GrammarElement → Exercise` hierarchy, `DrillSessionView`, FSRS implementation, database schema where possible, navigation, and visual system. Make content loading and library routing book-selectable, then add optional dialogue data and one response mode to the existing exercise path. Each book has separate content, element IDs, review state, schedule, progress, history, settings, unlocks, and completion. Keep Book 1 JSON, IDs, and existing settings keys stable.

**Tech stack:** SwiftUI, bundled JSON/MP3, `Speaker` and AVFoundation, SQLite, Python authoring tools, Xcode.

**Prior decision:** [Book 2 direction](../decisions/2026-10-10-next-book.md) prefers *En situation*, asks for short exchanges and useful responses, treats *Conversation* as a provisional shelf label, and excludes *Intermédiaire* from the current library.

## Product decision for review

Use **En situation** as the working title and shelf label. It is a practical application of *Fondations* A1–B1 material, not a CEFR certification or B1→B2 course. Success means understanding what the other speaker needs and replying to achieve a concrete outcome. *Fondations* is neither a prerequisite nor a source of unlocked lessons or review credit. The books share application code and visual design, but no learning state. The existing palette remains an app-level appearance preference. This plan assumes an adult self-study learner, offline iPhone use, and the current French UI with English learning notes; these are planning assumptions.

Three approaches were considered:

1. **Extend the current hierarchy and drill loop (recommended).** It preserves scheduling, history, settings, and styling. `GrammarElement` remains a legacy type name for a conversational move; defer a broad rename.
2. **Create a separate scenario engine.** Clear domain names, but duplicates progress and navigation and makes the books behave differently.
3. **Use only current sentence drills.** Fast, but current `Écouter` reads the model answer and cannot test comprehension before the reply. It misses the prior decision's core requirement.

## Research and repository basis

- The [CEFR Companion Volume](https://rm.coe.int/cefr-companion-volume-with-new-descriptors-2020/16809ea0d4) moves from predictable short exchanges at A2 to familiar but less routine interaction at B1, including checking information and explaining problems. It covers listening and requests for clarification, but does not prescribe clip duration.
- The [Council of Europe's action-oriented guidance](https://www.coe.int/en/web/common-european-framework-reference-languages/action-orientation-in-the-classroom), [scenario workshop](https://rm.coe.int/cefr-online-workshop-series-2022-4-presentation/1680a938e4), and [assessment guidance](https://www.coe.int/en/web/common-european-framework-reference-languages/assessment) support concrete situation outcomes and aligned can-do checks.
- The repo has 25 *Fondations* modules, 500 review elements, and 2,606 examples (`Resources/Topics/manifest.json`). `ContentLoader.loadBook()`, `LibraryView`, and `HistoryViewModel` assume one live book. `Exercise` has sentence drills and correct-sentence audio, not a dialogue response.
- `BookViewModel.reviewSessionElements()` uses global `fetchOverflowElementIDs(asOf:limit:)`; SQL limits before book filtering can starve one book's queue when another book has progress. `StudySettingsStore` also uses global UserDefaults keys, and `DrillView` reads the auto-speak key directly. These all need explicit book scope.

## Syllabus and release size

Target **25 modules × 8 communicative elements × 4 varied dialogues = 800 short exchanges** for the first complete edition. The earlier ten-module, 50-element proposal was too small for a full second book beside *Fondations* (25 modules, 500 elements). These counts size authoring and review; they are not CEFR standards. Each element is one reusable conversational move and the existing FSRS unit. The module note names the real-world goal; element notes explain a move in context. Group the modules into five coherent arcs so the increased count adds new communicative work rather than splitting one task into artificial chapters.

| Arc | Module | Situation | Learner outcome |
|---|---:|---|---|
| Se rencontrer | 01 | Faire connaissance | Introduce oneself and ask a follow-up |
|  | 02 | Parler de son quotidien | Exchange routines, interests, and frequency |
|  | 03 | Garder la conversation | React, ask back, and request repetition |
|  | 04 | Inviter quelqu'un | Invite, accept, or decline politely |
|  | 05 | Fixer un rendez-vous | Agree on time, place, and people |
| Services et déplacements | 06 | Au café | Order, specify, and check an order |
|  | 07 | Au marché | Ask about quantities, prices, and alternatives |
|  | 08 | En boutique | Ask for an item, size, or exchange |
|  | 09 | Réserver | Make and confirm a booking |
|  | 10 | Se repérer | Ask for directions and confirm a route |
| Faire face aux changements | 11 | Prendre les transports | Understand a departure, transfer, or delay |
|  | 12 | À l'hôtel | Explain a need and clarify a booking |
|  | 13 | Changer un rendez-vous | Explain a change and settle a new plan |
|  | 14 | Demander de l'aide | Describe a need, check understanding, thank |
|  | 15 | Expliquer un problème | State what went wrong and request a solution |
| Raconter et décider | 16 | Raconter sa journée | Sequence everyday events |
|  | 17 | Raconter un événement | Distinguish event from background; answer follow-ups |
|  | 18 | Comparer des options | Compare practical advantages and drawbacks |
|  | 19 | Choisir ensemble | Negotiate a choice and confirm it |
|  | 20 | Conseiller quelqu'un | Recommend an option with a reason |
| Échanger des idées | 21 | Donner son avis | State and support a familiar opinion |
|  | 22 | Être d'accord ou non | Agree, disagree, and soften a response |
|  | 23 | Expliquer pourquoi | Give reasons, consequences, and examples |
|  | 24 | Et si… ? | Explore a realistic condition and alternative |
|  | 25 | Résoudre un imprévu | Combine listening, repair, and response in a less routine exchange |

Pilot **Au café** (module 06) first because a service exchange makes understanding and useful replies easy to observe. Its eight elements: request an item; specify size; specify quantity; ask about availability; respond to a substitution; correct a misunderstanding; ask the price; close/pay. Four genuinely different variants per element; at least one asks for repetition or clarification. Freeze the template after testing the pilot, then author the other modules. Its grammar draws mainly from *Fondations* 01, 03, 05–06, 11, and 22; the rest of the syllabus recycles questions, place words, future and past forms, pronouns, comparison, imperatives, conditional, relatives, and `si` clauses across relevant situations.

## Interaction and content contract

1. Show a short situation cue and the text of a **two-speaker French exchange** from the start. Allow audio playback and replay. Reading the exchange is normal use and does not lower the rating.
2. Ask one comprehension question about a fact or intent needed for the reply: quantity, time, place, request, or problem. A miss permits rereading or replay and a second try, with feedback about the missed cue. The question must require understanding, not just spotting a repeated word.
3. Ask the learner to **form a short French reply**, using existing token/build interaction adapted for a conversational goal. The authored bank has an explicit set of accepted replies; every valid reply buildable from it must grade correctly. No open-ended speech recognition or LLM grading in this release.
4. Apply the current rating pattern: first-try success `.good`; success after a comprehension error or response retry at most `.hard`; no valid reply after two tries `.again`. Show a model reply, concise form/meaning feedback, and a follow-up turn showing the outcome.
5. Offer an optional, ungraded speak-aloud prompt and model audio. Save review under the communicative element ID; later sessions rotate its dialogue variants like existing examples.

Each variant needs stable ID, situation cue, ordered speaker turns and audio keys, listening question/choices/correct answer, response goal and bank, accepted replies, model reply, follow-up, French explanation, English support, and transcript. A listener must have enough visible/audio information to choose number, gender, person, and formality. Audit the **rendered full exchange** and every distractor, not isolated fields.

Audio is required content. Bundle the turns, model, and follow-up; fail validation if a reference is missing. Reuse `Speaker` and the current key convention where possible. The [Google French voice list](https://docs.cloud.google.com/text-to-speech/docs/list-voices-and-types) includes Neural2 F and G, but audition both on device for pronunciation, turn separation, and loudness before choosing. Keep the French exchange text visible, including when offline. Tune length from pilot use; CEFR gives no seconds target.

## Implementation tasks

### Task 1 — Pilot schema and validation

**Files:** Create `carambole/Resources/Situations/manifest.json` and `06_cafe.json`; extend `tools/lint_topics.py` or add a focused `tools/lint_situations.py` with Python tests.

- [ ] Define additive dialogue fields in the existing exercise DTO; Book 1 JSON must still decode unchanged.
- [ ] Author one pilot element with four variants before scaling to eight elements.
- [ ] Lint missing fields/audio, duplicate IDs across books, impossible banks, ambiguous listening choices, and second valid replies. Check the rendered exchange. Document the final JSON example in this file.
- [ ] Run Book 1's current linters and the new tests.

**Gate:** A reviewer can identify the goal, listening answer, all acceptable replies, and why each distractor fails in all four variants.

### Task 2 — Book selection and isolated progress

**Files:** `Models/ContentLoader.swift`, `BookContent.swift`, `Features/Library/LibraryView.swift`, `Features/Book/BookView.swift` and `BookViewModel.swift`, `Features/History/HistoryView.swift`, `Core/StudySettings.swift`, and the minimal scheduler/data query change.

- [ ] Add a book catalog and explicit loader selection. Preserve *Fondations* IDs/resources; prefix every Book 2 module, element, and example ID with `sit_`.
- [ ] Pass the selected book through shelf, book, module/session, and history. Open *En situation* on the shelf once the pilot is playable; preserve the existing ribbon and screen styling.
- [ ] Scope progress, counts, history, due items, and overflow to the selected book. Fix overflow so another book's IDs cannot consume the limit. Keep any SQLite migration additive; do not reset review data.
- [ ] Scope study settings and auto-speak by book. Preserve the existing `settings.*` keys as Book 1's values; use `settings.book_fr_en_situation.*` keys for Book 2. Pass auto-speak through the selected book's settings store rather than the direct global `@AppStorage` read in `DrillView`.
- [ ] Verify both books independently with a pre-existing database snapshot, fresh install, and app restart. Change each book's settings and answer/review elements in each; the other book's settings, due count, history, unlocks, progress %, and estimated finish must not change.

**Gate:** Book 1 data and settings stay intact. Each book has an independent study state even after learning and changing settings in both.

### Task 3 — Dialogue in the existing drill loop

**Files:** `Models/Exercise.swift`, `ContentLoader.swift`, `Core/Speaker.swift`, `Features/Drill/DrillView.swift`, `DrillEngine.swift`, `DrillSessionView.swift`; add one focused dialogue view if needed.

- [ ] Decode optional dialogue data and one new input mode without changing old exercise behavior.
- [ ] Implement visible ordered turns, audio playback and replay, speaker labels, and VoiceOver. Stop old playback on interrupt, exit, and rapid replay.
- [ ] Use the current choice/token components for listening and reply where practical. Grade all accepted replies and preserve second-try/FSRS behavior.
- [ ] Show model reply and follow-up after grading. Test assistance, retries, valid alternatives, missing audio, and exit/re-entry.

**Gate:** On a small simulator and device, a learner hears, replays, answers, forms a reply, sees feedback, and continues within the current lesson flow.

### Task 4 — Book-aware audio production and checks

**Files:** `tools/tts/extract.py`, `tools/tts/generate.py`, their tests, Book 2 lint helpers, and `Resources/Audio/`.

- [ ] Extract Book 2 utterances with stable keys and voice roles; keep Book 1's current audio-key mapping intact.
- [ ] Check that every dialogue/model/follow-up key resolves to a bundled file. Verify audible turn separation and offline playback.
- [ ] Independently audit grammar, naturalness, pronunciation, loudness, and answer uniqueness. Automated grammar checks filter candidates; they do not prove a natural exchange.

**Gate:** Every pilot variant plays offline with no silent fallback; Book 1 audio remains complete.

### Task 5 — Complete and test the pilot

**Files:** `06_cafe.json`, pilot audio, test fixtures, this plan's audit notes.

- [ ] Expand to eight elements and 32 exchanges. Review each conversation, listening check, reply set, feedback, transcript, and audio.
- [ ] Test first use, partial lesson, retry, review, restart, coexistence with *Fondations*, small-screen layout, and VoiceOver.
- [ ] Run simulator build/Python tests and a signed phone listening pass using current device handoff instructions. Record findings before bulk authoring.

**Gate:** A human can complete the pilot offline without an unfair answer, unreadable state, missing voice, or cross-book progress error.

### Task 6 — Author and audit the complete book

**Files:** Remaining 24 module JSON files under `Resources/Situations/`, manifest, audio, and a content coverage report in `docs/`.

- [ ] Author the other 24 modules in syllabus order, eight moves and four varied exchanges each. Work in five- or six-module batches so content review and playable releases can follow each arc.
- [ ] Lint and independently review each module before adding it to the manifest. Reject plausible second answers and unnatural French; do not suppress warnings as a shortcut.
- [ ] Check that predictable social/service tasks lead to stories, problems, opinions, and contingencies, with earlier moves recycled.

**Gate:** 25 modules, 200 unique review elements, 800 variants, complete audio coverage, and a recorded audit per module.

### Task 7 — Release verification and docs

**Files:** `CLAUDE.md`, this plan, and the decision doc after title/scope approval.

- [ ] Run existing Book 1 lints, Book 2 lint/audio coverage, Python tests, and a clean simulator `xcodebuild` using an installed destination from `tools/sim/README.md`.
- [ ] Test old DB, new install, offline mode, both books' learn/review/history/settings/unlocks/finish estimates, audio interruption, and transcript accessibility on simulator and phone.
- [ ] Inspect shelf, progress, long French text, and all drill states. Remove demo scaffolding and record build commit/device observations.
- [ ] Update status docs with shipped title, syllabus, counts, and any remaining limitations.

**Gate:** Clean build and content gates, Book 1 regression checks, and no blocking device issue.

## Review focus

1. Other-book IDs consume the global review overflow `LIMIT` → selected book still gets eligible items (Task 2).
2. Book IDs collide → lint rejects them before review state can mingle (Tasks 1–2).
3. A setting or review event in one book changes the other book → settings, history, unlocks, progress, and estimate stay separate (Task 2).
4. A second valid reply is buildable → it grades correct (Tasks 1 and 3).
5. Audio is missing/interrupted or replay is rapid → transcript remains and playback resets (Tasks 3–4).
6. Missed comprehension or a retried reply followed by a correct reply → saved rating is at most `.hard`; reading the visible exchange does not lower it (Task 3).

## Choices for review after this plan

The title and 25-module, 800-variant syllabus remain recommendations. The pilot will settle exact JSON field names, voices, and timing. The plan proposes constrained reply construction for fair grading and optional ungraded speaking. The user has specified complete independence between books; treat that as a fixed requirement.
