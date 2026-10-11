# En situation — Book 2 action plan

> **For agentic workers:** Implement task by task with an independent review after each milestone. Track the checkboxes here and update this file as decisions change.

**Status:** Design reworked 2026-10-11 after the user tried the café pilot on the phone (see *Design rework* below). The pilot content and screen are superseded: short dialogues, six drill types, at most two drills per dialogue, a chat layout, and new words glossed on tap. The Test book pilot was rebuilt to the rework (eight café dialogues, all six drill types, Corriger first) and installed on the iPhone 18 Pro on 2026-10-11. Follow-up user requests are also built and installed: smooth, slightly slower transitions; a recorded list of wrong answers with a session summary; no strike line or colour flash in Corriger; and a larger English cue. A full play-through and audio feedback are pending. Full-book implementation has not started.

**New-session handoff:** [Book 2 dialogue pilot v2 handoff](2026-10-11-book-2-pilot-v2-handoff.md).

## Difficulty pilot checkpoint (2026-10-11)

The user worries the planned conversation book may be too easy and requested a phone pilot in the existing `wen.carambole.testbook` app. This probe stays in `carambole/Debug/` and does not change either production book's content, schedule, or data. It is a connected four-scene café story: an unavailable ingredient, a food wait longer than the train window, a takeaway misunderstanding, and a broken card terminal. Each scene requires listening inference followed by a constructed French reply; the third requires both correcting the assumption and asking for a box.

- Content: `carambole/Debug/testbook_situation.json`; four scenes, varied correct-choice positions, accepted reply alternatives.
- Test book UI: `carambole/Debug/SituationPilotView.swift`, launched from the existing `DrillDemo.swift` test book screen.
- Contract: `carambole/Debug/PilotScenario.swift`; focused Swift logic test `tools/pilot/PilotScenarioTests.swift` was observed failing before implementation and passing after.
- Content gate: `tools/pilot/test_content.py`; five tests pass, including shorter valid replies. The Swift scenario test also passes. Independent review found and we fixed a hidden listening correction and over-strict reply alternatives.
- Audio: `tools/pilot/generate_audio.py` generated 12 bundled MP3 files: two-voice dialogue plus model and follow-up for each scene. File format and bundle coverage pass; a human still needs to judge pronunciation, voice contrast, and loudness on the phone.
- Build and handoff: Debug simulator and signed device builds pass. The iPhone 18 Pro installed and launched bundle ID `wen.carambole.testbook` on 2026-10-11. Simulator screenshots show the reply and feedback screens with the footer action visible. Open **Test book → En situation · essai** to play all four scenes.
- Feedback-driven change: show the exchange text from the start on every scene, with audio as replay. Reading is normal use, not a graded hint. Keep this default for Book 2 unless later testing changes the decision. This revision was rebuilt, simulator checked, and reinstalled on the phone.
- User verdict on the pilot (2026-10-11): layout bad, problems too difficult, too many unknown words. Codex's content and screen are superseded by the design rework below.

## Design rework (2026-10-11, user-approved direction)

Reference mock: `https://claude.ai/artifact/WisTx5oe1Jq5ZW3h6SL6gN` (private artifact, playable; eight café dialogues across all six drill types). The user approved the layout and the decisions below. What went wrong in the pilot:

1. **Untaught words.** Each server line carried 3–5 words outside *Fondations* (*avoine, livraison, passer au four, un quart d'heure, régler, tomber en panne, liquide, comptoir*) with no gloss, no repeat, and grading as if known. The user is willing to learn new words; the app must teach them.
2. **Puzzles, not French.** Questions required holding an English setup paragraph in memory and doing arithmetic (*un quart d'heure* = 15 min > 10 min train window).
3. **Form layout.** A scrolling page with numbered sections, radio rows, and chunk tiles up to eight words long; it ignored the Book 1 locked drill card.

Decisions:

- **Chat layout on one locked card.** Situation cue = one English line at the top. Server turns are left bubbles, white with an ink outline and a round play button. The learner's turns are right bubbles filled with the active palette's `tileOn` (the placed-magnet colour; Acide `E5F2BC`, Iris `EAF2D6`, Surimpression `D3DCF0`). Drill area below a hairline with ~22–36 pt of space above it: word tray `tint`, play button `quietFill`, Vérifier `buttonFill`, wrong marks `fragile`. Colours come from `AppTheme`, never hard-coded. Older bubbles scroll inside the chat area only; the drill area and footer never move.
- **Reply builds in the learner's own bubble.** A dashed empty bubble fills with placed magnets; when correct it becomes a normal filled bubble and the server's follow-up line appears as the next bubble.
- **New words: underline + tap.** French always shows alone. New words (outside the *Fondations* word list) carry an underline. Tapping any word or set phrase shows its English in a tooltip directly above the tapped word; it auto-hides after ~2.5 s. English never appears without a tap. Tapping does not lower the rating. After a dialogue, its new words are listed with their English.
- **Short dialogues, many of them.** 1–3 lines in total, counting the learner's; ≤10 words per line.
- **Six drill types, ≤2 per dialogue.** See *Interaction and content contract*.
- **Dropped:** the optional ungraded speak-aloud prompt and its model-audio step. Line-by-line audio replay stays.

**Goal:** Build a second French book that trains learners to understand a short everyday exchange and form a useful response, applying grammar from *Fondations*.

**Architecture:** Reuse the existing `Book → CourseModule → GrammarElement → Exercise` hierarchy, `DrillSessionView`, FSRS implementation, database schema where possible, navigation, and visual system. Make content loading and library routing book-selectable, then add dialogue data and six drill modes to the existing exercise path. Each book has separate content, element IDs, review state, schedule, progress, history, settings, unlocks, and completion. Keep Book 1 JSON, IDs, and existing settings keys stable.

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

Target **25 modules × 8 communicative elements × 10 short dialogues = 2,000 dialogues (≈3,000 drills at 1–2 drills each), plus ≈1,000 standalone drills at 1 per 2 dialogues** for the first complete edition. The 2026-10-11 rework replaced the earlier 4 longer exchanges per element: four variants run out by the third review, and long exchanges were too slow and too hard. The earlier ten-module, 50-element proposal was too small for a full second book beside *Fondations* (25 modules, 500 elements). These counts size authoring and review; they are not CEFR standards. Each element is one reusable conversational move and the existing FSRS unit. The module note names the real-world goal; element notes explain a move in context. Group the modules into five coherent arcs so the increased count adds new communicative work rather than splitting one task into artificial chapters.

### Content direction (user decisions, 2026-10-11)

The old table was textbook units only. The user wants content that is varied and interesting, with the usual service scenes kept but not dominant, and French closer to how people talk.

- **Recurring cast.** The learner has just moved to Lyon for work. The same people come back across modules, so dialogues carry light history ("Comme d'habitude ?"). Each dialogue still makes sense alone.
  - **Léa**, flatmate, *tu*, direct.
  - **Monsieur Ferrand**, neighbour on the landing, *vous*, fussy, kind underneath.
  - **Karim**, barista at the café du coin, *vous* at first, *tu* later (module 03 sets up the switch).
  - **Inès**, colleague, *tu*.
  - **Théo**, friend, runs the group chat "Les copains".
  - **Madame Dumas**, landlady, *vous*, writes on WhatsApp.
  - Service people (pharmacist, driver, shop staff) are one-off.
- **Channels.** Most dialogues are face to face. About 2–3 of each move's 10 dialogues use another channel: text message, group chat, WhatsApp from the landlady, voicemail (audio plus text), a call, a message from a colleague. The cue line names the channel. Same card, same drills.
- **Social moves, not only transactions.** Apologise for being late, comfort a friend, complain politely, turn down an invite without offending, react to news, give a compliment, say you didn't understand.
- **Culture as moves.** *Bonjour* first; *on peut se tutoyer ?*; *la bise*; *l'apéro*; *une tradition* at the bakery; strikes; Sunday and August closures; the pharmacist as first stop. Each one also carries grammar.
- **Light twists.** A follow-up line may carry a small surprise (the barista already started your usual). Never a puzzle, never graded.
- **Register: mostly standard, sprinkled with everyday spoken French.** Mainly in *tu* dialogues: *je sais pas*, *t'as*, *ouais*, *du coup*, *on* for *nous*, *carrément*, *pas de souci*, *bref*. No slang-heavy lines, no verlan.
  - **Spoken forms carry a tap hint:** the tooltip shows an asterisk and the English, e.g. `* I don't know`. The glossary marks these entries `spoken: true`.
  - Learner replies accept the standard and the spoken form (*je ne sais pas* / *je sais pas*). The model answer is standard.
- **No texting abbreviations** (no *mdr*, *stp*, *jsp*). Text messages use normal spelling.
- **Learner gender:** the learner's own lines accept both forms (*prêt/prête*, *allé/allée*). Corriger never targets the learner's own gender. No setting.

| Arc | Module | Situation (cast · channel) | Learner outcome |
|---|---:|---|---|
| Arriver à Lyon | 01 | Faire connaissance (Léa on move-in day) | Introduce oneself and ask a follow-up |
|  | 02 | Le quotidien (Léa, Inès · texts) | Exchange routines, interests, and frequency |
|  | 03 | Tu ou vous ? (Ferrand on the landing, Karim, Inès) | Pick the register, small talk, ask to repeat, *on peut se tutoyer ?* |
|  | 04 | Inviter (group chat, Léa) | Invite to an apéro; accept or decline without offending |
|  | 05 | Fixer un rendez-vous (texts, a call) | Agree on time, place, and people; move it |
| Le quartier | 06 | Au café (Karim) | Order, specify, accept a substitute, "comme d'habitude", pay |
|  | 07 | Boulangerie et marché | *Une tradition*, quantities, prices, *c'est tout ?* |
|  | 08 | En boutique | Ask for an item or size; exchange or return |
|  | 09 | Réserver (a call, voicemail) | Book a table; confirm or change it |
|  | 10 | Se repérer (a lost delivery driver · call) | Give and follow directions |
| Les imprévus | 11 | Grève et retards (station, group chat) | Understand a cancellation; find another way |
|  | 12 | Le logement (Madame Dumas · WhatsApp, Ferrand) | Report a broken boiler, a leak, lost keys |
|  | 13 | Être en retard, annuler | Apologise, explain, propose a new plan |
|  | 14 | Santé (pharmacist, doctor's office · call) | Describe a symptom; get advice or an appointment |
|  | 15 | Ça ne marche pas (parcel, haircut, bike repair) | Complain politely and ask for a fix |
| Raconter | 16 | Raconter sa soirée (Léa) | Sequence everyday events |
|  | 17 | Une galère (Théo tells a disaster day) | React, sympathise, ask back |
|  | 18 | Comparer (flats, phone plans, bikes) | Compare advantages and drawbacks |
|  | 19 | Choisir ensemble (group chat) | Negotiate a choice and confirm it |
|  | 20 | Conseiller (Inès asks for advice) | Recommend an option with a reason |
| Échanger | 21 | Donner son avis (film, food, the neighbourhood) | State and support an opinion |
|  | 22 | D'accord ou pas (chores with Léa) | Agree, disagree, soften |
|  | 23 | Expliquer pourquoi | Give reasons, consequences, and examples |
|  | 24 | Et si… ? (a long weekend) | Explore a realistic condition and alternative |
|  | 25 | Un week-end qui déraille (whole cast) | Combine listening, repair, and response in a less routine exchange |

Pilot **Au café** (module 06) first, now with Karim and the spoken register. Its eight moves: order (with *bonjour* first); specify size or quantity; ask what's available; accept a substitute; *sur place ou à emporter*; "comme d'habitude" (Karim remembers); fix a misunderstanding; pay or sort out a payment problem. Ten short dialogues per move plus standalone drills at 1 per 2 dialogues (about 40). At least one dialogue per move uses another channel or a social move, and at least one asks for repetition or clarification. Sequence: author café → play it in Test book → freeze the content schema (Task 1) and per-book progress (Task 2) → bulk authoring. Its grammar draws mainly from *Fondations* 01, 03, 05–06, 11, and 22; the rest of the syllabus recycles questions, place words, future and past forms, pronouns, comparison, imperatives, conditional, relatives, and `si` clauses across relevant situations.

## Interaction and content contract

1. **Dialogue.** A one-line English situation cue and 1–3 French lines (≤10 words each), server and learner, shown as chat bubbles from the start with per-line audio replay. Reading and tapping words for English are normal use and never lower the rating.
2. **Drills.** Each dialogue holds one or two drills, never the same type twice, and never both Répondre and Choisir (both fill the learner's reply bubble). Two drills run in order on the same card; the chat stays put.

| Type | Learner action | Content it needs | Used in |
|---|---|---|---|
| **Comprendre** | Pick 1 of 2 answers about one fact the server said | question, 2 choices, correct index, miss note naming the line to reread | Apprendre + Réviser |
| **Répondre** | Build the reply in their own bubble from word magnets; a set phrase is one tile | goal (English), bank, accepted replies, model | Apprendre + Réviser |
| **Choisir** | Pick the reply that works out of 3 | one correct; one wrong-French; one good French that doesn't fit; a why-line for each wrong one | mostly Réviser |
| **Compléter** | Fill one gap in a line with 1 of 3 words | line with one gap, 3 choices, correct, why-lines | Apprendre + Réviser |
| **Corriger** | Tap the one wrong word in the learner's bubble, then pick its fix from 3 | line with one real learner error, wrong word, 3 fixes | Réviser |
| **Mot** | Pick the meaning of an underlined new word in context, 1 of 3 | target word/phrase, 3 English choices | Réviser, and right after a word's first dialogue |

3. **Rating** (current pattern): every drill right first try → `.good`; any miss or retry → at most `.hard`; a drill not solved after two tries → `.again` (show the answer, fill the bubble grey). A dialogue's rating is its worst drill. After the last drill the server's follow-up bubble appears, then the dialogue's new words are listed.
4. **Review unit and Réviser.** FSRS state stays per communicative element (`sit_` ID). A dialogue is that element's example. When an element is due, pick one of its dialogues the learner has not done; if all are done, the one done longest ago. Prefer a drill type different from the element's last review. An element is mastered after correct dialogues on 3 distinct dialogues covering at least 2 drill types (Book 1's distinct-correct gate plus the type condition).
5. **Words.** A per-book word list holds every word or set phrase outside the *Fondations* list: French, English gloss, audio key, first-seen dialogue. Each new word appears in at least two later dialogues of its module, and one of them uses it in a Mot drill. Words have no FSRS schedule of their own in this release. The underline stays for all new words in this release; dropping it once a word is known is a later option.
6. **Wrong answers are recorded.** The learner is asked to fix their own answers, so every wrong attempt is kept, not only the final rating:
   - During the retry, the wrong attempt stays visible. A wrong choice stays marked, and the why-line or miss note is shown. A wrong reply keeps its correct start placed (Book 1's second-try pattern), and the note quotes the full wrong attempt.
   - After the dialogue, the learner's mistakes are listed with the right answer.
   - At the end of a session, a summary shows every mistake with its reason.
   - Persist each wrong attempt in an additive `situation_attempt_log` table (element ID, dialogue ID, drill type, given answer, expected answer, timestamp), separate per book. Use it for the history page and to bring back the missed dialogue first at the next review.
   - Never cross out a word being corrected. Mark it with a white highlight on the learner bubble, not the palette `tint` (it read as a flash).
7. **Grading.** No open speech recognition or LLM grading. Every accepted reply buildable from the bank must grade correct; lint rejects a second valid reply that is not listed.

Each dialogue needs stable ID, element ID, situation cue, ordered turns (speaker, text, audio key, optional gap or error marker), 1–2 drill payloads from the table, follow-up line and audio key, new-word references, and a French explanation with English support for feedback. A reader must be able to recover number, gender, person, and formality from the visible text and cue. Audit the **rendered** dialogue with each drill answer filled in, plus every distractor, not isolated fields.

Audio is required content. Bundle every turn and follow-up, plus each new word's audio; fail validation if a reference is missing. Reuse `Speaker` and the current key convention where possible. The [Google French voice list](https://docs.cloud.google.com/text-to-speech/docs/list-voices-and-types) includes Neural2 F and G; audition both on device for pronunciation, turn separation, and loudness before choosing.

## Implementation tasks

### Task 1 — Pilot schema and validation

**Files:** Create `carambole/Resources/Situations/manifest.json` and `06_cafe.json`; extend `tools/lint_topics.py` or add a focused `tools/lint_situations.py` with Python tests.

- [ ] Define additive dialogue fields in the existing exercise DTO; Book 1 JSON must still decode unchanged.
- [ ] Author one pilot element with ten short dialogues (at least four drill types) before scaling to eight elements. Add the per-book word list file.
- [ ] Lint missing fields/audio, duplicate IDs across books, impossible banks, ambiguous comprehension choices, second valid replies, >2 drills or a repeated type per dialogue, Répondre + Choisir together, lines over 10 words, dialogues over 3 lines, words outside *Fondations* without a word-list gloss, and new words with fewer than two later appearances or no Mot drill. Check the rendered dialogue. Document the final JSON example in this file.
- [ ] Run Book 1's current linters and the new tests.

**Gate:** A reviewer can identify, for all ten dialogues, each drill's answer, all acceptable replies, and why each distractor fails; every new word is glossed and recurs.

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

- [ ] Decode optional dialogue data and the six drill modes without changing old exercise behavior.
- [ ] Implement the chat card: server/learner bubbles with palette colours, per-line audio replay, speaker labels, tap-a-word English tooltip above the word, underlined new words, and VoiceOver. Keep the card vertically locked; only the chat area scrolls. Stop old playback on interrupt, exit, and rapid replay.
- [ ] Use the current choice/token/spot components for the six drill types where practical (Répondre builds inside the learner bubble; Compléter fills an inline gap; Corriger reuses `SpotErrorView` logic). Run up to two drills in sequence on one card. Grade all accepted replies and preserve second-try/FSRS behavior; the dialogue rating is the worst drill.
- [ ] Show the follow-up bubble, the dialogue's mistakes, and its new words after the last drill; show a session summary of all mistakes; write each wrong attempt to `situation_attempt_log`. Implement Réviser dialogue selection (unseen first, then oldest; vary drill type) and the 3-dialogue/2-type mastery gate. Test tapping, retries, valid alternatives, missing audio, and exit/re-entry.

**Gate:** On a small simulator, a learner plays every drill type, taps words for English, replays audio, finishes a two-drill dialogue, and continues within the current lesson flow; the card never scrolls as a whole.

### Task 4 — Book-aware audio production and checks

**Files:** `tools/tts/extract.py`, `tools/tts/generate.py`, their tests, Book 2 lint helpers, and `Resources/Audio/`.

- [ ] Extract Book 2 utterances with stable keys and voice roles; keep Book 1's current audio-key mapping intact.
- [ ] Check that every turn, follow-up, and new-word key resolves to a bundled file. Verify audible turn separation and offline playback.
- [ ] Independently audit grammar, naturalness, pronunciation, loudness, and answer uniqueness. Automated grammar checks filter candidates; they do not prove a natural exchange.

**Gate:** Every pilot variant plays offline with no silent fallback; Book 1 audio remains complete.

### Task 5 — Complete and test the pilot

**Files:** `06_cafe.json`, pilot audio, test fixtures, this plan's audit notes.

- [ ] Expand to eight elements and 80 short dialogues. Review each dialogue, drill, reply set, word gloss, feedback, and audio.
- [ ] Test first use, partial lesson, retry, review, restart, coexistence with *Fondations*, small-screen layout, and VoiceOver.
- [ ] Run simulator build/Python tests and a signed phone listening pass using current device handoff instructions. Record findings before bulk authoring.

**Gate:** A human can complete the pilot offline without an unfair answer, unreadable state, missing voice, or cross-book progress error.

### Task 6 — Author and audit the complete book

**Files:** Remaining 24 module JSON files under `Resources/Situations/`, manifest, audio, and a content coverage report in `docs/`.

- [ ] Author the other 24 modules in syllabus order, eight moves and ten short dialogues each. Work in five- or six-module batches so content review and playable releases can follow each arc.
- [ ] Lint and independently review each module before adding it to the manifest. Reject plausible second answers and unnatural French; do not suppress warnings as a shortcut.
- [ ] Check that predictable social/service tasks lead to stories, problems, opinions, and contingencies, with earlier moves recycled.

**Gate:** 25 modules, 200 unique review elements, 2,000 dialogues, a complete word list, complete audio coverage, and a recorded audit per module.

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
5. Audio is missing/interrupted or replay is rapid → text remains and playback resets (Tasks 3–4).
6. Any missed or retried drill in a dialogue → saved rating is at most `.hard`; reading the dialogue or tapping words for English does not lower it (Task 3).
7. All of an element's dialogues done → Réviser falls back to the oldest, and mastery still needs 2 drill types (Task 3).

## Choices for review after this plan

The title and the 25-module, 2,000-dialogue syllabus remain recommendations. The pilot will settle exact JSON field names, voices, and timing. Reply construction stays constrained for fair grading; the speak-aloud step was dropped on 2026-10-11. The user has specified complete independence between books; treat that as a fixed requirement.
