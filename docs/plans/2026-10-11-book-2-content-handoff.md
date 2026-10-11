# Book 2 handoff — authoring the real content

> **Status 2026-10-11:** module 06 is authored and reviewed. Start from the [café handoff](2026-10-11-book-2-cafe-handoff.md) for state and next steps; this file stays the rulebook.

**Date:** 2026-10-11
**Repo:** `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole`
**Branch:** `main`. The `book2-dialogue-pilot` branch was merged and deleted. Nothing is pushed.
**Next session's goal:** write the real content for Book 2 (*En situation*), starting with module 06 *Au café*.

## 1. Read first

1. This file. It has everything needed to author.
2. [Book 2 action plan](2026-10-11-book-2-action-plan.md). The current sections are *Content direction*, the syllabus table, *Interaction and content contract* and *Implementation tasks*.
3. [Pilot v2 handoff](2026-10-11-book-2-pilot-v2-handoff.md). It covers the binding UI rules, the drill mix, review set v3 and the pilot screen as built.
4. The pilot content `carambole/Debug/testbook_situation.json`. These 9 cards are the approved style sample.
5. The two mocks (private artifacts):
   - Dialogue screen and the six dialogue drills: `https://claude.ai/artifact/WisTx5oe1Jq5ZW3h6SL6gN`
   - Drill mix with standalone drills: `https://claude.ai/artifact/8A6hQgxpcQo1Ud9hyQnvGv`
6. `CLAUDE.md` *Rendered-surface grammar* and *Prompt self-sufficiency*. Book 1's hard rules apply to Book 2 too.

## 2. Where things stand

- **Done:** the Test book pilot runs a 9-card review set. It has 6 dialogues and 3 standalone drills, uses the Lyon cast and a spoken register, and gives each character a voice. The user played it on the iPhone 18 Pro and said it works.
- **Done:** tapping anywhere off a word closes the English tooltip. Swiping up closes the "Marqué trop facile" pill in Book 1's drill session.
- **Not done:** the production Book 2 doesn't exist yet:
  - no `Resources/Situations/`,
  - no loader, shelf entry or per-book progress,
  - no `situation_attempt_log`,
  - no Écrire typing drill in Swift.
- **Not checked:** the user hasn't given feedback on the cast voices (Chirp 3 HD) on the phone yet. Ask about it early.

## 3. Binding rules (the user decided all of these; don't reopen them)

### Screen and interaction

- One locked chat card. Only the chat scrolls. The card never scrolls as a whole.
- The French is always visible. Audio is replay only.
- **English only on tap.** It shows in a tooltip right above the tapped word. It closes after about 2.6 s, on scroll, or on a tap anywhere else. Never print English automatically.
- New words are underlined. The finished card lists its new words.
- The learner's bubble uses the palette's `tileOn`. Every colour comes from `AppTheme`.
- Corriger: no strike-through and no colour flash. The wrong word gets a white highlight, and a wrong tap shakes the word.
- Motion stays at the current "slightly longer" timings. Don't speed it up.
- Wrong answers are recorded and shown back: during the retry, in "Vos erreurs" after each card, and on the "Séance terminée" summary.

### Content

- **Dialogues:**
  - 1–3 lines including the learner's, ≤10 words per line, 1–2 drills.
  - Never two drills of the same type in one dialogue.
  - Never Répondre and Choisir together.
- **Standalone drills:**
  - 1 per 2 dialogues, so 10 dialogues + 5 standalone drills per move.
  - They stay chat-like (a bubble with a sentence), labelled "phrase seule".
  - No follow-up line, 0–2 lines, exactly one drill.
- **Session order:** D D S D D S… Never the same type back to back.
- **Teach every new word.** Many new words are fine if they are taught.
  - Every word outside *Fondations* gets a gloss.
  - It is underlined on first use.
  - It recurs in at least two later dialogues of its module, and one of those is a Mot or Mot en retour drill.
  - A standalone drill uses only words already taught.
- **Harder means:** longer sentences (8–14 words in standalone drills), two grammar points in one item, near-miss distractors and less help.
- **Harder never means:**
  - logic puzzles,
  - arithmetic,
  - facts that exist only in the English cue,
  - untaught words.
- **Register:**
  - Mostly standard French, sprinkled with everyday spoken forms, mainly in *tu* exchanges: *je sais pas*, *t'as*, *t'es*, *y a*, *ouais*, *du coup*, *carrément*, *bref*, *pas de souci*, *top*, *ça marche*, and *on* for *nous*.
  - No slang-heavy lines and no verlan.
  - Each spoken form is a glossary entry marked spoken. The tooltip shows `* English`.
  - Learner replies accept both the standard and the spoken form. The model answer is standard.
- **No texting abbreviations** (*mdr*, *stp*, *jsp*, *slt*…). Text messages use normal spelling.
- **Learner gender (changed 2026-10-11):** the learner is **Robin, a woman** from Eugene, Oregon.
  - Her own lines use feminine agreement only (*prête*, *allée*, *enchantée*, *désolée*). Masculine forms are wrong answers and may serve as decoys.
  - Corriger may target her agreement (*Je suis prêt* → *prête*).
  - Others may address her as *madame*.
  - When an answer hinges on her gender, the cue says "You're a woman." (prompt self-sufficiency).
  - `lint.py` flags masculine first-person forms in learner lines, accepted replies and correct picks.
- **Variety:**
  - Textbook service scenes stay, but they must not dominate.
  - About 2–3 of each move's 10 dialogues use another channel or a social move.
  - Add culture moves and light twists in follow-ups (never graded, never a puzzle).

## 4. Cast bible

The learner has just moved to Lyon for work. People recur across modules. **Every dialogue must still make sense on its own,** because Réviser serves a move's dialogues in any order. So:
- history only shows in the cue line ("Karim knows you by now"),
- the cue always makes tu/vous, gender, number and person recoverable.

| Character | Role | Register with you | Voice (Google TTS) | Notes |
|---|---|---|---|---|
| Karim | barista, café du coin | *vous* in module 06, except the "Passer au tu" dialogues; *tu* in later modules | `fr-FR-Chirp3-HD-Charon` | warm, teasing, remembers your order |
| Léa | flatmate | *tu* | `fr-FR-Chirp3-HD-Aoede` | direct, texts a lot |
| Théo | friend, runs the group chat "Les copains" | *tu* | `fr-FR-Chirp3-HD-Achird` | enthusiastic, plans things |
| Monsieur Ferrand | neighbour on the landing | *vous* | pick a male Chirp 3 HD voice not used above (e.g. `Algenib`), audition first | fussy, kind underneath |
| Inès | colleague | *tu* | pick a female Chirp 3 HD voice (e.g. `Despina`), audition first | practical, asks for advice |
| Madame Dumas | landlady, WhatsApp | *vous* | pick a female Chirp 3 HD voice (e.g. `Erinome`), audition first | formal, brief |
| one-off staff | pharmacist, driver, shop staff | *vous* | `fr-FR-Neural2-G` / `-F` | no name, label "Serveur" or a role |

Run `GET https://texttospeech.googleapis.com/v1/voices?languageCode=fr-FR` to list voices. Only 2 Neural2 voices exist (F, G); Chirp 3 HD has 30. Ask the user to listen before you settle new cast voices.

**Karim and *tu* (my recommendation, confirm with the user):**
- The *tu* switch happens inside module 06, in the "comme d'habitude" move.
- Module 03's syllabus row no longer lists Karim.
- All other module-06 Karim dialogues use *vous*, so any review order stays consistent.

## 5. Module 06 *Au café* plan

Eight moves (FSRS elements). Each has 10 dialogues (`d01`–`d10`) and 5 standalone drills (`s01`–`s05`).

| Element ID | Move | Must include |
|---|---|---|
| `sit_06_order` | Order a drink (*bonjour* first) | the "Bonjour quand même" culture dialogue |
| `sit_06_size` | Specify size or quantity | *pour deux*, *un grand / une petite* agreement |
| `sit_06_available` | Ask what's available | *il reste… ? / y a encore… ?* |
| `sit_06_substitute` | Accept or refuse a substitute | *plus de…*, *à la place* |
| `sit_06_takeaway` | Eat in or take away | *sur place / à emporter*, a bag |
| `sit_06_usual` | "Comme d'habitude" and passing to *tu* | Karim remembers; *on peut se tutoyer ?* |
| `sit_06_mixup` | Fix a misunderstanding | wrong order, *je crois qu'il y a une erreur* |
| `sit_06_pay` | Pay, or sort out a payment problem | *ça fait…*, terminal *en panne*, *espèces*, *monnaie* |

Per move:
- At least 4 drill types among the dialogues; Répondre + Compléter make up at least half the drills.
- At least 1 dialogue asks for repetition or clarification.
- At least 2 dialogues use another channel or a social move: Léa or Théo texting about the café, the group chat, a voicemail from Karim about a lost card.
- The 5 standalone drills spread across the types: Construire, Choisir le ton, Corriger, Transformer and Mot en retour. Écrire waits for its Swift build.

Rework the 9 pilot cards into this structure rather than throwing them away.

## 6. File layout and JSON shape (Task 1)

Create:

```
carambole/Resources/Situations/manifest.json      {"book": "fr_en_situation", "moduleFiles": ["06_au_cafe.json"]}
carambole/Resources/Situations/words.json         book word list (one entry per word or set phrase)
carambole/Resources/Situations/06_au_cafe.json    one module
tools/situations/lint.py + tests                  port tools/pilot/test_content.py, add the checks in §7
tools/situations/review_set.py                    export a ~9-card sample to carambole/Debug/testbook_situation.json
```

The Xcode bundle flattens `Resources/*` to the bundle root. Keep filenames unique, and don't reuse `manifest.json` names that clash with `Topics/manifest.json`. Name the file `situations_manifest.json` if needed, and check how `ContentLoader` finds it.

**Module file.** Each dialogue and standalone item keeps exactly the pilot shape, so the pilot view can play it unchanged:

```json
{
  "id": "sit_06",
  "title": "Au café",
  "arc": "Le quartier",
  "goal": "Order, specify, accept a substitute, pay.",
  "elements": [
    {
      "id": "sit_06_usual",
      "title": "Commander comme d'habitude",
      "note": "English learner note about the move.",
      "items": [
        {
          "id": "sit_06_usual_d01",
          "place": "Au café",
          "cue": "Karim, the barista, knows you by now.",
          "turns": [{"speaker": "server", "name": "Karim", "text": "Bonjour ! Comme d'habitude ?"}],
          "drills": [
            {"type": "comprehend", "prompt": "What is Karim asking?", "choices": ["If you want your usual", "If you want to pay"], "correct": 0, "miss": "Reread: « comme d'habitude » means as usual."},
            {"type": "reply", "prompt": "Say yes: a large coffee with soy milk.",
             "bank": ["Oui,", "un", "grand", "café", "au soja,", "s'il vous plaît.", "grande", "une"],
             "accepted": [["Oui,", "un", "grand", "café", "au soja,", "s'il vous plaît."]],
             "model": "Oui, un grand café au soja, s'il vous plaît."}
          ],
          "followUp": "C'est déjà prêt, en fait !",
          "newWords": ["comme d'habitude", "au soja", "en fait"]
        },
        {
          "id": "sit_06_usual_s01",
          "place": "Au café · phrase seule",
          "standalone": "Mot en retour",
          "cue": "Which French words mean “as usual”?",
          "turns": [{"speaker": "server", "name": "Karim", "text": "Bonjour ! ___ ?"}],
          "drills": [{"type": "complete", "prompt": "as usual", "choices": ["Comme d'habitude", "Du coup", "Quand même"], "correct": 0, "why": ["", "« Du coup » means so.", "« Quand même » means all the same."]}],
          "newWords": []
        }
      ]
    }
  ]
}
```

Field reference (decoded by `carambole/Debug/PilotScenario.swift` today; Task 3 moves it into production):

| Field | Where | Meaning |
|---|---|---|
| `place` | item | label above the cue: place or channel (`Texto · Léa`, `Les copains · groupe`, `Messagerie · Karim`). Add `· phrase seule` for standalone items |
| `cue` | item | one English line, 21 pt. Must make tu/vous, gender, number and the goal recoverable |
| `standalone` | item | drill label for a standalone item: `Construire`, `Choisir le ton`, `Corriger`, `Transformer`, `Mot en retour` (later `Écrire`). No `followUp` |
| `turns[].speaker` | turn | `server` (any other voice) or `learner` |
| `turns[].name` | turn | cast name shown above the bubble and used for the voice. Omit it for an anonymous server |
| `turns[].source` | turn | `true` = the grey "Vous · avant" line to rewrite (Transformer) |
| `turns[].error` | learner turn | Corriger: `{word, fix, choices[3], why}` |
| `___` | any line | the gap for Compléter or Mot en retour (exactly one per item) |
| `followUp` / `followUpBy` | dialogue | closing line (required for dialogues) and its speaker if not the first named server |
| `newWords` | item | glossary keys first taught or reinforced here; underlined |
| drill `type` | drill | `comprehend` (2 choices), `reply` (bank/accepted/model), `pick` (3 choices + why), `complete` (3 choices + why), `fix`, `word` (3 choices + `target`) |

How drill labels map to engines:

| Label | Engine |
|---|---|
| Comprendre | `comprehend` |
| Répondre, Construire, Transformer | `reply` |
| Choisir, Choisir le ton | `pick` |
| Compléter, Mot en retour | `complete` |
| Corriger | `fix` |
| Mot | `word` |

**Words file.** Move from the pilot's `* ` gloss prefix to a field:

```json
{"words": [
  {"fr": "du coup", "en": "so", "spoken": true, "audio": "sitw_du_coup", "firstSeen": "sit_06_available_d03"},
  {"fr": "comme d'habitude", "en": "as usual", "spoken": false, "audio": "sitw_comme_d_habitude", "firstSeen": "sit_06_usual_d01"}
]}
```

- The tooltip renders `* ` + `en` when `spoken` is true. `review_set.py` writes the `* ` prefix into the pilot glossary.
- **Every tappable token needs a gloss.** Tapping any word shows its English, including *Fondations* words like *un*, *café*, *oui*. Keep the base words in `words.json` too, with `firstSeen: null` and no underline.
- Set phrases are matched longest first, so add a phrase entry when the words mean something different together (*quand même*, *ça marche*).

**ID rules:**
- Module `sit_06`, element `sit_06_<move>`, dialogue `sit_06_<move>_dNN`, standalone `sit_06_<move>_sNN`.
- IDs are stable forever once shipped. Never reuse an ID.
- Audio keys: `sit_<item id>_t<turn index>` and `sit_<item id>_f`; word audio `sitw_<slug>`.

## 7. Authoring procedure

Work in this order. Show the user small review sets only. They said: "i dont wanna go through the whole cafe module in the test book. just give me a few drills and i will review."

1. **Plan the module on paper first.** Make a table of the 8 moves × 15 items with these columns:
   - situation,
   - channel,
   - cast,
   - drill types,
   - new words,
   - which later items reuse each new word.

   Check the type spread, the 1:2 ratio, the word recurrence and channel variety before writing any French.
2. **Write the lint (`tools/situations/lint.py`) before the content**, with tests that fail first. Port every check in `tools/pilot/test_content.py`, then add these:
   - unique IDs across both books (and the `sit_` prefix);
   - ≤10 words per dialogue line;
   - 1–3 lines per dialogue, 0–2 per standalone item;
   - 1–2 drills per dialogue, one per standalone item;
   - no repeated type in a dialogue, and no Répondre + Choisir together;
   - 10 dialogues + 5 standalone drills per element;
   - every `reply` accepted answer can be built from the bank, and the model is accepted;
   - `comprehend` has 2 distinct choices, `pick`/`complete`/`word` have 3, with a why-line for every wrong one;
   - `fix` word is in its learner line, and its fix is among the choices;
   - exactly one gap for complete;
   - every tappable token has a gloss;
   - every `newWords` key exists and appears in the item;
   - each new word recurs in ≥2 later items of the module, one of them a `word` or Mot en retour item;
   - standalone items use no untaught word;
   - spoken entries are in the spoken list;
   - no texting abbreviations (block-list);
   - no masculine first-person adjective or participle in learner lines, accepted replies or correct Choisir options (Robin is a woman);
   - audio exists for every server turn and follow-up.
3. **Author move by move.** For each move write all 15 items, then run the lint.
4. **Rendered-surface grammar.** Fill each gap with each choice, apply each fix, and build each accepted reply. Run the rendered French through Grammalecte (`tools/deep_lint.py` and the vendored engine; adapt its input to the situations files). Every distractor must be wrong for a stated reason (wrong French, or good French that doesn't fit), and no second reply buildable from the bank may be valid unless it is listed in `accepted`. Book 1's bank lint found 77 hidden ambiguities this way. Expect the same here.
5. **Independent review with subagents** (Book 1 content was authored and audited this way; ask the user before spawning many). Give each judge one move and ask it to check:
   - natural, current spoken French (would a Lyonnais say this?),
   - register consistency with the cue,
   - answer uniqueness,
   - whether gender, number and tu/vous can be recovered,
   - that no line needs untaught words,
   - that every English gloss is accurate in context.

   Then read every flagged item yourself.
6. **Audio.** Extend `tools/pilot/generate_audio.py` into `tools/situations/generate_audio.py`. It keeps the `CAST` voice map, skips files that already exist and never prints tokens. It needs `gcloud auth application-default` credentials, which currently work. Generate the server turns, follow-ups and word audio. Note the API characters used in the handoff.
7. **Review set for the user.** Run `review_set.py` to pick about 9 cards that cover the new features, risky items and every drill type (D D S order). Write them into `carambole/Debug/testbook_situation.json`, generate their `pilot2_*` audio, run the pilot tests, build and install the Test book (§9), and ask for feedback. Fold their notes back into the rules here, then do the next batch.
8. Only after café is approved: Task 1's gate, then Tasks 2–3 (per-book progress, production view), then the other 24 modules in batches of 5–6 (one arc), each with lint, a judge pass and a review set.

## 8. Item-writing checklist

- **Cue:** one English sentence that says who you're talking to and what you want. Include the channel's context if it isn't face to face. Don't put the answer's facts only in the cue.
- **Server line:** natural, ≤10 words. At most 1–2 new words, plus spoken forms only when the speaker is casual.
- **Comprendre:** asks about one fact said in French. The wrong choice is plausible. The miss note quotes the line to reread.
- **Répondre / Construire / Transformer:**
  - bank = answer + 2–3 near-miss decoys (gender, person, tense, register);
  - a set phrase is one tile (`s'il vous plaît.`);
  - punctuation rides on the tile;
  - list every valid order in `accepted`.
- **Choisir / Choisir le ton:**
  - Choisir: one right, one wrong French, one good French that doesn't fit.
  - Choisir le ton: all three good French, only one fits the register.
  - Write a why-line for each wrong option.
- **Compléter / Mot en retour:** exactly one gap; 3 choices from the same word class; each wrong one fails for a stated reason; pre-elide around the gap when needed.
- **Corriger:** one real learner error with a unique fix. It may target Robin's feminine agreement. Never a second possible fix (lock the subject if needed). Write a why-line.
- **Mot:** the target is a new word from this or an earlier item; 3 English meanings, all plausible in context.
- **Follow-up:** short, natural, and may carry a light twist. Its new words are glossed.
- **Typography:**
  - French spacing before `?` `!` `:` (the app glues lone punctuation to the word before);
  - straight apostrophes `'`;
  - `« »` in English notes when quoting French;
  - `…` stays attached to its word.

## 9. Commands

```sh
# pilot tests (Test book content)
rtk python3 -m unittest tools/pilot/test_content.py
rtk proxy swiftc -D DEBUG carambole/Debug/PilotScenario.swift tools/pilot/PilotScenarioTests.swift -o /tmp/cb-pilot-scenario-tests
rtk proxy /tmp/cb-pilot-scenario-tests carambole/Debug/testbook_situation.json
# pilot audio (cast voices; skips existing files)
python3 tools/pilot/generate_audio.py
# Book 1 linters must stay green
python3 tools/lint_topics.py && python3 tools/deep_lint.py
# simulator build (iPhone 18 Pro, iOS 27.0)
rtk xcodebuild -project carambole.xcodeproj -scheme carambole -configuration Debug -destination 'id=48420336-6EA1-4545-A656-1DF72A82089E' PRODUCT_BUNDLE_IDENTIFIER=wen.carambole.testbook INFOPLIST_KEY_CFBundleDisplayName='Test book' CODE_SIGNING_ALLOWED=NO -derivedDataPath /tmp/cb-book2-pilot-sim build -quiet
# screenshots: launch flags CB_TEST_BOOK=1 CB_TB_OPEN=situation CB_PILOT_INDEX=n [CB_PILOT_STAGE=fill|done] [CB_PILOT_TIP=<key>] [CB_PILOT_AUTOPLAY=1|wrong]
# zsh: build the env list as an array, e.g.
#   args=(SIMCTL_CHILD_CB_TEST_BOOK=1 SIMCTL_CHILD_CB_TB_OPEN=situation SIMCTL_CHILD_CB_PILOT_INDEX=3); env "${args[@]}" xcrun simctl launch <sim> wen.carambole.testbook
# phone install (only when the user asks; never test or record on the phone)
rtk xcodebuild -project carambole.xcodeproj -scheme carambole -configuration Debug -destination 'id=00008160-001A09920AA0000A' -allowProvisioningUpdates DEVELOPMENT_TEAM=QMV4SPL476 PRODUCT_BUNDLE_IDENTIFIER=wen.carambole.testbook INFOPLIST_KEY_CFBundleDisplayName='Test book' -derivedDataPath /tmp/cb-book2-pilot-device build -quiet
xcrun devicectl device install app --device 00008160-001A09920AA0000A /tmp/cb-book2-pilot-device/Build/Products/Debug-iphoneos/carambole.app
xcrun devicectl device process launch --terminate-existing --device 00008160-001A09920AA0000A wen.carambole.testbook
```

Afterwards, delete `/tmp/cb-book2-pilot-*`, recordings, frame folders and screenshot folders. Check `df -h /` before any large job.

## 10. Questions for the user at the start of the next session

1. Do the cast voices (Karim, Léa, Théo) sound right on the phone?
2. Should Karim's switch to *tu* happen inside module 06 (recommended), or in module 03?
3. Is the module 06 move list in §5 right?
4. Should the Écrire typing drill be built in Swift now (so café can include it), or wait?
5. Should the main Carambole app get the swipe-up "trop facile" change now? Only the Test book has it so far.
