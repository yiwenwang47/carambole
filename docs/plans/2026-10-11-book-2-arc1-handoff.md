# Book 2 handoff: arc 1 authored, review set v5

**Date:** 2026-10-11
**Repo:** `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole`, branch `main`. Not pushed.
**Supersedes:** the [café handoff](2026-10-11-book-2-cafe-handoff.md) as the starting point. The [content handoff](2026-10-11-book-2-content-handoff.md) is still the rulebook. The [arc-1 plan](2026-10-11-book-2-arc1-plan.md) and its five module matrices record how arc 1 was designed.

## 1. Where things stand

| Item | State |
|---|---|
| Café audio | All 379 clips generated and committed (`f7b36ac`). The strict lint (with audio) passes. The user has not spot-listened yet. |
| Tasks 2–3 (production view) | Merged. *En situation* sits on the shelf. Each book has its own progress, settings, history and overflow. `SituationSessionView` shuffles choices and keeps both café scroll/tray fixes. Schema v5 is additive. See `CLAUDE.md` and the action plan for details. |
| Tooling | Book-wide. `modules.json` holds module metadata; drafts are named `NN_<slug>_<half>.json`; `assemble.py [NN…]`; lint, deep lint, audio and review set run across all modules. New cast voices: M. Ferrand = Chirp3-HD Orus, Inès = Despina, Mme Dumas = Gacrux, anonymous female = Neural2-F (`voice: "female"`). |
| Arc 1 content | Modules 01–05 are authored: 600 items, 137 newly taught words. All reviewed by 20 judges and fixed by 10 fixers. Lint, 68 Python tests, Grammalecte (1,927 lines, 0 flags) and the Swift model test (720 items) pass. |
| Review set v5 | 9 cards in `carambole/Debug/testbook_situation.json`, with `pilot2_*` audio. Installed in the Test book on the iPhone 18 Pro **simulator** only. |
| Arc 1 audio | Generated and committed: 1,370 clips, about 33,100 API characters. The strict lint passes. M. Ferrand uses Orus (Algenib paused for about 1 s between sentences). |
| Not done | The other 19 modules (arcs 3–5, then 07–10). The Écrire drill. |

## 2. Review set v5 (for the user)

D D S order: `01_name_d02` (M. Ferrand) · `03_tutoyer_d01` (« on peut se tutoyer ? », neighbour) · `02_react_s03` (Corriger inside « moi aussi ») · `04_group_d02` (group-chat plural *vous*, *dispos*) · `03_dumas_d07` (Mme Dumas on WhatsApp) · `04_arrive_s02` (Choisir le ton with M. Ferrand) · `02_frequency_d03` (spoken *je sais pas*) · `05_call_d07` (voicemail from Inès) · `05_call_s03` (Corriger *te/vous*).

It covers all six engines and the three new voices. Phone install happens only if the user asks.

## 3. User decisions (2026-10-11, after v5)

1. **The learner is Robin from Eugene, Oregon, and Robin is female** (user, 2026-10-11; was Alex / Boston). The content still follows the content handoff's rule: it accepts both gender forms in learner lines and never genders Robin. Whether to switch the model answers to feminine (*enchantée, désolée*) and allow *madame* is an open question for the user. In French the hometown is « Eugene, dans l'Oregon » on first mention. Later mentions use « Eugene » or « l'Oregon ». 45 items were reworked and 39 clips re-recorded.
2. The partners who suggest *tu* in module 03 stay unnamed. There is no seventh cast voice.
3. **Café underlines dropped** for the ten words now taught in 01–05. An underline means "new word here" only.
4. *ah, oh, tout le monde, pas de problème, bonne journée, ça me va* stay glossed on tap only. They are not taught.
5. The channel mix stays as authored: 02, 04 and 05 are channel-heavy by design.
6. M. Ferrand's voice is **Orus** (Algenib paused for about 1 s between sentences). The user confirmed it works.
7. Still open: module 03 teaches 24 words, one under the ~25 floor (minor).

## 4. What changed in code this session

- **Corriger inside a set phrase** (`Models/Situation.swift`, `Debug/PilotScenario.swift`): `segments(…, keepApart:)` stops a multi-word phrase from swallowing the error word. Before, « moi aussi » and « s'il vous plaît » made Corriger impossible to solve (this affected café `usual_s03` too). `SituationModelTests` now checks every Corriger item.
- The pilot validator allows standalone lines up to 14 words (it was 10, which disagreed with the content rule).
- `lint.py`: the clarification regex matches "Clarify". *dispo, dispos, boulot* were added to the spoken list.
- **Book-wide glosses widened** (one gloss per word for the whole book): fais, fait, reste, restes, café, la, sur, bien, combien, par, là, aussi, se, moi c'est, lui, à moi/toi/vous, vite, excuse-moi, excusez-moi, s'il vous plaît, voilà, on peut se tutoyer, encore, temps, plus, bureau, entre, va, chez vous, à côté, si, je prends, rendez-vous, ça marche. These were also changed in the café drafts.

## 5. Lessons for the next batches

- **Gloss conflicts are the main merge cost.** Ten authors each glossed base words their own way, which left 33 conflicts. Give authors a list of shared base-word glosses up front, or have one agent build the batch's base words first.
- **One gloss per word bites.** Judges flagged about 35 glosses that were wrong in context (*fais* = "make" in « tu fais quoi »). Prefer wide glosses ("do / make") from the start.
- **The judges found the same classes again:**
  - hidden valid replies (the most common: a reply without « Pardon ? », or a swapped clause order);
  - standalone place labels: authors used the move's home place, but the label must name the setting of the cue;
  - cue leaks and answer echo;
  - a speaker answering their own question;
  - « repeat » asked of a text message;
  - learner gender (« madame », « voisins »).
- **A phrase key can match across a comma** (« avec moi, c'est tu » matches *moi c'est*). This is handled by the gloss "I'm… / for me, it's…". Watch for other phrase keys.
- **Process that worked:** a planner writes the matrices → 2 authors per module → coordinator assembles and harmonises glosses → 4 read-only judges per module (spec in a shared file) → one fixer per draft half → coordinator applies gloss changes centrally.

## 6. Next steps

1. The user plays review set v5. Ask about the voices (M. Ferrand, Inès, Mme Dumas) and §3.
2. Fold feedback in, then generate production audio for 01–05: `rtk python3 tools/situations/generate_audio.py --dry-run`, then run it without flags (about 2,000 clips). Run the strict lint, then commit.
3. Next batch: arc 3 « Les imprévus » (11–15) or finish arc 2 (07–10, beside café). Use the same pipeline; reuse `scratchpad`-style JUDGE/FIXER specs (copied into §7).
4. Still open from the content handoff §10: build Écrire? Port swipe-up "trop facile" to the main app?

## 7. Commands

```sh
rtk python3 tools/situations/assemble.py                 # all modules with drafts
rtk python3 tools/situations/lint.py --no-audio
rtk python3 -m unittest tools/situations/test_lint.py tools/situations/test_tools.py tools/pilot/test_content.py
rtk python3 tools/situations/deep_lint.py
swiftc carambole/Models/Situation.swift tools/situations/SituationModelTests.swift -o /tmp/cb-sit-model-tests && /tmp/cb-sit-model-tests carambole/Resources/Situations
rtk python3 tools/situations/review_set.py <nine IDs>     # boundary drill types must differ; adjacent dialogue drill pairs must differ
rtk python3 tools/situations/generate_audio.py --review
```

**Judge spec in brief** (one judge per two moves, read-only, writes a findings file): check naturalness, register, answer uniqueness (enumerate bank orders), cue leaks / answer echo, follow-up logic, learner gender, false errors, untaught words, place labels and glosses in context. Output one line per finding: `[MUST|SHOULD|NIT] id — class — problem → FIX: exact change`.

**Fixer spec in brief:** edits only its own draft half. Applies every MUST and SHOULD. Fixes every standalone place label and every hidden reply in its half. Never edits existing glosses; it reports them to the coordinator instead.
