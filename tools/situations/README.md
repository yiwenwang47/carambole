# En situation content contract

`situations_manifest.json` is named to avoid the flattened bundle's existing
`Topics/manifest.json`. It has `book: "fr_en_situation"` and `moduleFiles`
in numeric module order. A module file has `id: "sit_NN"` (`sit_01`–`sit_25`),
`title`, `arc`, `goal`, and `elements`. Each element has `id: "sit_NN_move"`
(move: lowercase letters only), `title`, `note`, and 15 `items` in the
order `d01 d02 s01 d03 d04 s02 … d09 d10 s05`. An item has `id`, `place`,
`cue`, `turns`, `drills`, and `newWords`. A dialogue also has `followUp` and
optional `followUpBy`; a standalone has `standalone` and no follow-up. The
dialogue and standalone fields use the shape decoded by
`Debug/PilotScenario.swift`. The only extra nesting is module → element → item.

Each turn has `speaker: "server" | "learner"`, `text`, optional cast `name`,
optional `source: true` for Transformer, and optional `error` for Corriger.
An unnamed server turn may set `voice: "female"` (or `"male"`, the default)
to pick the anonymous Neural2 voice; a role label in `name` such as
« Pharmacienne » also gets the male default unless it is in the cast table.
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

`words.json` is one book-wide file. Entries have `fr`, `en`, `spoken`,
`audio`, and `firstSeen`. Use `firstSeen: null` for a base word and an item ID
for a new word. Set phrase keys match before single words. A new word's
`firstSeen` item must list it in `newWords` and show it in a visible turn.

Book order is module number, then element (move) order, then item order. No
item earlier in the book may use a new word, so module 03 cannot use a word
first taught in module 05, and a word taught in module 01 is free everywhere
after. Inside the module that teaches it, the word then appears in at least two
later dialogues, with a later Mot or Mot en retour drill. A later item, in the
same or a later module, may list an earlier word in `newWords` to underline it
again; `firstSeen` stays the original item ID. All tappable French tokens,
including bank and choice distractors, need glosses. Standalone items use only
words taught earlier in the book and have `place` ending in `· phrase seule`.

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

## Cast names and voices

Use exactly these `name` strings in turns and `followUpBy`. The lint rejects
the long forms (« Monsieur Ferrand », « Madame Dumas »). The voice map is
`CAST` in `tools/pilot/generate_audio.py`.

| `name` | Role | Register | Voice |
|---|---|---|---|
| `Karim` | barista | *vous* in 06 (except `usual`), *tu* later | `fr-FR-Chirp3-HD-Charon` |
| `Léa` | flatmate | *tu* | `fr-FR-Chirp3-HD-Aoede` |
| `Théo` | friend, group chat | *tu* | `fr-FR-Chirp3-HD-Achird` |
| `M. Ferrand` | older neighbour, fussy | *vous* | `fr-FR-Chirp3-HD-Orus` |
| `Inès` | young colleague | *tu* | `fr-FR-Chirp3-HD-Despina` |
| `Mme Dumas` | older landlady, WhatsApp | *vous* | `fr-FR-Chirp3-HD-Gacrux` |
| (no name or a role) | one-off staff | *vous* | `fr-FR-Neural2-G`; `voice: "female"` → `fr-FR-Neural2-F` |

The three new voices were checked against the live fr-FR voice list but not
yet auditioned by the user. Word audio uses `fr-FR-Neural2-G`.

## Drafts and modules.json

`tools/situations/modules.json` lists each module's `id`, `title`, `arc`,
`goal`, output `file` (e.g. `06_au_cafe.json`) and ordered `moves`. Add a
module's entry before its first assemble.

Drafts live in `tools/situations/drafts/` as pairs named

```
NN_<slug>_<part>.json        {"elements": [...]}
NN_<slug>_<part>_words.json  {"words": [...]}
```

`NN` is the two-digit module number; `<slug>` and `<part>` use lowercase
letters, digits and `_` (e.g. `07_boulangerie_first_half.json` and
`07_boulangerie_first_half_words.json`). Each author edits only their own
pair. A module may have any number of parts; together they must hold each
move in `moves` exactly once. Every elements draft needs its `_words` file.

`assemble.py` builds each named module in `moves` order and rewrites the
single `words.json` from the drafts of every manifest module plus the named
ones. For a `fr` key in several drafts, the entry with the earliest
`firstSeen` in book order wins, and a taught entry beats `null`. `en`,
`spoken` and `audio` must agree, or assemble fails and prints both entries.
The named modules are added to `situations_manifest.json` in numeric order.
A manifest module without drafts is an error, because its words would be
dropped.

## Commands

```sh
rtk python3 tools/situations/assemble.py                  # every module with drafts
rtk python3 tools/situations/assemble.py 07               # one module (+ book-wide words)
rtk python3 tools/situations/lint.py --draft --no-audio
rtk python3 tools/situations/lint.py --no-audio           # all manifest modules, book order
rtk python3 tools/situations/lint.py                      # strict, with audio
rtk python3 tools/situations/lint.py --no-audio --module carambole/Resources/Situations/07_boulangerie.json
rtk python3 tools/situations/deep_lint.py [--module 07]   # Grammalecte on rendered lines
rtk python3 tools/situations/generate_audio.py --dry-run [--module 07] [--limit N]
rtk python3 tools/situations/generate_audio.py --review   # pilot2_* clips for the review set
rtk python3 tools/situations/review_set.py <nine item IDs from any modules>
rtk python3 -m unittest tools/situations/test_lint.py tools/situations/test_tools.py tools/pilot/test_content.py
```

`lint.py` without `--module` checks every manifest module in book order with
the book-wide `words.json`. `--module path/to/module.json` checks one module,
still against the book-wide words and the other manifest modules' item order.
`--draft` permits a partial element and delays the per-move spread and word
recurrence gates, but keeps item-level checks. A draft fragment with only
`elements` can be passed with `--module` and a custom `--words` file; its
header comes from `modules.json`. `generate_audio.py --module NN` makes only
that module's turn and follow-up clips plus the words it first teaches; base
words come from a run without `--module`. `rendered_surfaces(item)` returns
filled gaps, applied fixes, accepted replies, and all choice lines for a
grammar review pass.

The full-move linter checks four dialogue drill types, at least half Répondre
and Compléter, one clarification or repetition dialogue, and two alternate
channel or social dialogues. The last two use cue/prompt and place/cast
heuristics: a dialogue counts as another channel when its `place` differs from
the module's most common dialogue place, or as social when it has Léa, Théo,
Inès, M. Ferrand or Mme Dumas. An author still needs to review whether the request is genuine,
whether English cues hide a needed fact, whether gender and register are
recoverable, whether distractors have unique reasons, and whether the French
sounds natural. These judgments cannot be proven from this JSON alone.
