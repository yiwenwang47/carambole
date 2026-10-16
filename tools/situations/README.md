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
to pick the anonymous Neural2 voice. Every unnamed server turn also needs a
display-only `role`: the capitalised French label shown above its bubble
(« Vendeuse », « Livreur », « Boulangère », « Passant », « Messagerie »). Its
gender matches the voice (`voice: "female"` → « Serveuse », not « Serveur »).
`role` never changes audio, and only unnamed server turns may carry it; the
app shows `name ?? role` and no label at all when both are missing. The
follow-up bubble takes `followUpBy`, else the first named server, else the
first server's role; a dialogue may set `followUpRole` when its follow-up is
someone else (a voicemail answered by the restaurant calling back). The strict
lint requires `role`; `--draft` lets it wait.
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
| (no name; set `role`) | one-off staff | *vous* | `fr-FR-Neural2-G`; `voice: "female"` → `fr-FR-Neural2-F` |

The three new voices were checked against the live fr-FR voice list but not
yet auditioned by the user. Word audio uses `fr-FR-Neural2-G`.
The line `sit_04_thank_d03_t0` uses `fr-FR-Studio-A` by user selection;
`VOICE_OVERRIDES` in `tools/situations/generate_audio.py` preserves that choice
when the clip is regenerated. Its IPA pronunciation remains in
`tts_overrides.json`.

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
rtk python3 tools/situations/normalize_audio.py --all --check   # loudness report, no changes
rtk python3 tools/situations/normalize_audio.py --all           # normalise any new/untagged clip
rtk python3 tools/situations/audio_audit.py                     # hard audio gate; JSON + playable HTML report
rtk python3 tools/situations/repair_audio.py --apply           # shorten flagged quiet gaps; saves originals in /tmp
rtk python3 tools/situations/gloss_dump.py MODULE.json carambole/Resources/Situations/words.json [--moves a,b]
rtk python3 tools/situations/apply_gloss_spec.py SPEC.json [--dry]   # book-wide gloss widenings + new base keys
rtk python3 -m unittest tools/situations/test_lint.py tools/situations/test_tools.py tools/pilot/test_content.py tools/situations/test_normalize_audio.py
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

**Glosses (user rule, 2026-10-12): every gloss must be correct in every drill.**
Each key has one book-wide `en`; the app (`SituationText.segments`) matches
keys longest-first, left to right, across commas but not across a free-standing
« ! » « ? » « : » or a `___` gap, and keeps a Corriger error word apart.
`gloss_dump.py` prints every tappable line with the gloss each token shows,
segmented the same way; judges read it pair by pair. Fix a wrong gloss by
widening the entry (check every other use), adding a longer phrase key
(`firstSeen: null`; check it swallows nothing else), or rewriting the line.
`apply_gloss_spec.py` applies a spec `{"widen": {key: en}, "add": {key: en}}`
to every draft words file and `words.json` (rewrites stay manual), then run
`assemble.py`. New keys need audio from a plain `generate_audio.py` run. Specs
so far: `docs/archive/plans/arc4-judges/gloss_spec.json`, `docs/archive/plans/gloss-sweep/spec2.json`.

The full-move linter checks four dialogue drill types, at least half Répondre
and Compléter, one clarification or repetition dialogue, and two alternate
channel or social dialogues. The last two use cue/prompt and place/cast
heuristics: a dialogue counts as another channel when its `place` differs from
the module's most common dialogue place, or as social when it has Léa, Théo,
Inès, M. Ferrand or Mme Dumas. An author still needs to review whether the request is genuine,
whether English cues hide a needed fact, whether gender and register are
recoverable, whether distractors have unique reasons, and whether the French
sounds natural. These judgments cannot be proven from this JSON alone.

## Audio loudness

Every bundled clip (Book 1, Book 2, Test book) is normalised by
`normalize_audio.py`, and both `generate_audio.py` scripts call it on each new
clip right after writing it. Needs macOS `afconvert`, numpy, scipy and
`lameenc` (`pip install lameenc`); the generators stop before any TTS call if
the codec is missing.

- **Bursts:** the loudest 400 ms block (momentary loudness) is capped at
  -15.5 LUFS; a clip with an emphatic word is turned down as a whole until it
  fits, so it may sit below -18 integrated. Added after the user heard
  Théo's « Je ne sais pas ! » as loud at -18.
- **Loudness:** -18 LUFS integrated (ITU-R BS.1770, gated), true peak
  ≤ -1.5 dBTP (a 5 ms look-ahead limiter at -2 dBTP; then the decoded MP3 is
  checked and re-encoded if the codec's ~-0.45 dB shift or overshoot moved it).
  -18 rather than -16 because TTS speech peaks ~15 dB over its loudness, so
  -16 would push most clips into the limiter.
- **De-harsh:** a clip with more than -23 dB of its energy above 5 kHz (+1 dB
  tolerance) gets a 6 kHz high shelf cut by the excess, at most 4 dB.
  Despina, Gacrux, Orus and sibilant words are the usual cases. A word still
  mostly hiss after that (above -12 dB, e.g. « ce », « six ») is aimed below
  -18 by the remainder, at most 8 dB.
- **Format:** same name, MP3, 24 kHz mono and CBR bitrate as the TTS output.
  Silent codec delay/padding frames are trimmed so the decoded length and
  timing match the original; an edge frame with sound is kept (24 ms longer).
- **Idempotent:** a processed file carries an ID3 `TXXX` tag
  `carambole-normalize` and is skipped next time. `--force` re-processes
  tagged files; use it only on originals, or the shelf compounds.

When a line's text changes, delete its clip and regenerate it; the new clip is
normalised as it is written.

## Audio pronunciation and pause gate

**Mandatory for every future production book with bundled speech:** add the book
to `audio_books.json` before its first Release build. A situation-schema book
points to its manifest directory. Any other book supplies a JSON index of
`{ "key": "clip_basename", "text": "spoken line", "voice": "voice name" }`
rows. Point to its audio directory and report path too. Run
`audio_release_gate.py` for all books, or use `tools/release_build.sh`, which
runs the gate before `xcodebuild`. A missing or unresolved clip stops the build.
Book 3 *Nuances* is integrated as a text-only production book. It has no
bundled speech or audio controls, so it has no entry in `audio_books.json`.
If spoken French is added, create its complete clip index, register the book,
and pass this gate before a Release build.

Every new Book 2 clip is checked immediately after generation and normalisation.
Excessive quiet gaps are shortened automatically, without changing the spoken
samples; a clip that still fails stops generation. `repair_audio.py --apply`
does the same for existing clips. It builds and checks a candidate first,
backs up the original in `/tmp/carambole_audio_backups`, then replaces it.
The strict `lint.py` release check also runs the full audit; `--no-audio`
skips it during authoring. Run `audio_audit.py` to write the review queue. It checks every
expected MP3 for absence, corruption, silence, excessive padding, and long
pauses that do not align with punctuation. The command exits nonzero while
any finding remains unresolved. Its JSON report and playable HTML review queue
go to `docs/reports/book2_audio_audit.*` by default.

**Pronunciation remains a separate judgment.** A waveform cannot tell whether
`c'était` was spoken as `/setɛ/`; the pause check only caught the conspicuous
gap in that clip. If a clip sounds wrong, regenerate it with an exact-text
SSML/IPA entry in `tts_overrides.json`, then rerun the audit. If an unresolved
timing finding is actually a natural pause, listen to it and record the clip's
report SHA-256, all finding codes, and a nonempty reason in
`audio_audit_reviews.json`. Reviews stop applying if the MP3 changes. Never
approve a clip based only on the signal report.

```json
{
  "sit_01_example_t0": {
    "sha256": "the hash shown in the report",
    "codes": ["internal_pause"],
    "reason": "Listened to the whole clip; this pause follows the full stop."
  }
}
```

The same audit can check future books with this situation schema using
`--situations PATH --audio-dir PATH`; another audio format can supply a JSON
`--index PATH` list of `{ "key": ..., "text": ..., "voice": ... }` rows.

## Agent prompts

`agents/planner.md`, `agents/author.md`, `agents/judge.md` and `agents/fixer.md` are the prompts for the batch pipeline: plan, then two authors per module, four judges per module, and one fixer per draft half. The coordinator assembles and harmonises glosses. See the latest Book 2 handoff in `docs/plans/`.
