# En situation content contract

`situations_manifest.json` is named to avoid the flattened bundle's existing
`Topics/manifest.json`. It has `book: "fr_en_situation"` and `moduleFiles`.
A module file has `id: "sit_NN"`, `title`, `arc`, `goal`, and `elements`.
Each element has `id: "sit_NN_move"`, `title`, `note`, and 15 `items` in the
order `d01 d02 s01 d03 d04 s02 … d09 d10 s05`. An item has `id`, `place`,
`cue`, `turns`, `drills`, and `newWords`. A dialogue also has `followUp` and
optional `followUpBy`; a standalone has `standalone` and no follow-up. The
dialogue and standalone fields use the shape decoded by
`Debug/PilotScenario.swift`. The only extra nesting is module → element → item.

Each turn has `speaker: "server" | "learner"`, `text`, optional cast `name`,
optional `source: true` for Transformer, and optional `error` for Corriger.
The `error` object has `word`, `fix`, three `choices`, and a single English
`why` string. A line can contain one `___` gap for Compléter. Dialogue lines
have at most ten words; standalone lines have eight to fourteen. A dialogue
has at most three lines counting its turns plus the learner's built reply
(one extra line when it has a `reply` drill).

Each drill has `type` and `prompt`. `comprehend` has two distinct `choices`,
`correct`, and `miss`. `pick`, `complete`, and `word` have three choices,
`correct`, and a `why` array with a nonempty reason for each wrong choice.
`word` also has `target`, which must appear in a visible French turn. `reply`
has `bank`, `accepted` tile sequences, and a `model` equal to one accepted
sequence. `fix` uses its turn's `error` object. The standalone labels are
Construire (`reply`), Choisir le ton (`pick`), Corriger (`fix`), Transformer
(`reply`), and Mot en retour (`complete`); each appears once per full move.

`words.json` has `words` entries with `fr`, `en`, `spoken`, `audio`, and
`firstSeen`. Use `firstSeen: null` for a base word and an item ID for a new
word. Set phrase keys match before single words. A new word's `firstSeen`
item must list it in `newWords` and show it in a visible turn. No earlier item
may use it. It then appears in at least two later dialogues in the module,
with a later Mot or Mot en retour drill. A repeated item may list an earlier
word in `newWords` to underline it again; `firstSeen` stays the original item
ID. All tappable French tokens, including bank and choice distractors, need
glosses. Standalone items use words already taught and have `place` ending in
`· phrase seule`.

Production audio keys use the complete item ID once: `sit_06_order_d01_t0`
for turn 0 and `sit_06_order_d01_f` for its follow-up. Each word has an
independent `sitw_...` key. The linter checks all MP3s in strict mode.

The Test book pilot shows choices in stored order, so vary the slot of the
correct answer and keep `why` aligned with `choices`. The production view
(`Features/Situation/SituationSessionView.swift`) shuffles choices and reply
banks at render time and grades by choice text, so stored order never reaches
the learner there.

The app loads every module listed in `situations_manifest.json` (no Swift
change for a new module). Pure-logic tests for the production model
(`carambole/Models/Situation.swift`) run against the bundled content:

```sh
swiftc carambole/Models/Situation.swift tools/situations/SituationModelTests.swift -o /tmp/cb-sit-model-tests
/tmp/cb-sit-model-tests carambole/Resources/Situations
```

Authoring commands:

```sh
rtk python3 tools/situations/lint.py --draft --no-audio
rtk python3 tools/situations/lint.py --no-audio
rtk python3 tools/situations/lint.py
rtk python3 -m unittest tools/situations/test_lint.py
```

`--module path/to/module.json` checks one module. `--draft` permits a partial
element and delays the per-move spread and word recurrence gates, but keeps
item-level checks. A draft fragment with only `elements` can be passed with
`--module` and a custom `--words` file. `rendered_surfaces(item)` returns
filled gaps, applied fixes, accepted replies, and all choice lines for a
grammar review pass.

The full-move linter checks four dialogue drill types, at least half Répondre
and Compléter, one clarification or repetition dialogue, and two alternate
channel or social dialogues. The last two use cue/prompt and place/cast
heuristics. An author still needs to review whether the request is genuine,
whether English cues hide a needed fact, whether gender and register are
recoverable, whether distractors have unique reasons, and whether the French
sounds natural. These judgments cannot be proven from this JSON alone.
