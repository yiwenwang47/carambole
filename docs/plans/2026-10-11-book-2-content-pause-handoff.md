# Book 2 café content — paused handoff (superseded)

**Superseded on 2026-10-11 by the [café handoff](2026-10-11-book-2-cafe-handoff.md).** Start there. This file records the pause state only.

**Paused:** 2026-10-11 at the user's request. Do not resume authoring until asked.
**Repo:** `/Users/yiwenwang/Documents/CMU/research/personal/carambole/carambole`
**Branch:** `book2-cafe-content` (created from local `main`; nothing pushed).
**Scope:** the first content gate in [the Book 2 content handoff](2026-10-11-book-2-content-handoff.md): module 06, *Au café*. The remaining 24 modules, production loader/UI, and book progress are outside this pause checkpoint.

## Saved work

- `carambole/Resources/Situations/situations_manifest.json`, `06_au_cafe.json`, and `words.json`: production-shaped content. The module currently has 8 moves, 80 dialogues, and 40 standalone cards. `words.json` has 212 entries after the latest assembly.
- `tools/situations/drafts/06_cafe_first_half.json` and `06_cafe_second_half.json`: authored source halves; adjacent `*_words.json` files hold their candidate glossary entries. **Edit these sources, then run `assemble.py`**. Direct edits to production JSON will be overwritten.
- `docs/plans/2026-10-11-book-2-cafe-first-half-matrix.md` and `...second-half-matrix.md`: item plans and vocabulary recurrence maps.
- `tools/situations/lint.py`, `test_lint.py`, `README.md`: schema, structural/content lint, and tests. The manifest name avoids the Xcode bundle's flattened `Topics/manifest.json` collision. Production item audio keys are `<item-id>_t<turn-index>` and `<item-id>_f`; word keys use `sitw_...`.
- `tools/situations/assemble.py`, `deep_lint.py`, `review_set.py`, `generate_audio.py`, `test_tools.py`: assembly, French grammar checking, review export, audio generation, and adapter tests.

Three authoring and schema agents were used, followed by independent French reviews of both content halves and a schema review. Reviewers found answer echoes, unnatural role assignments, cue-only facts, mismatched follow-ups, hidden valid replies, and duplicate audio keys. Most were sent back for correction. Both author agents were interrupted when the user asked to pause; inspect their final draft files before making further assumptions about which review notes they completed.

## Current verification (fresh at pause)

Commands were run after `rtk python3 tools/situations/assemble.py`:

- `rtk python3 -m unittest tools/situations/test_lint.py tools/situations/test_tools.py tools/pilot/test_content.py` — **46 tests passed**.
- `rtk python3 tools/situations/deep_lint.py` — **286 correctly rendered French lines, 0 Grammalecte grammar flags**. This does not establish naturalness or answer uniqueness.
- `rtk python3 tools/situations/lint.py --no-audio` — **3 errors remain**: `sit_06_pay_d04` lacks gloss `alors`; `sit_06_pay_s03` lacks gloss `payer` (also fails standalone taught-word check).
- `rtk git diff --check` — passed. Book 1's `lint_topics.py` and `deep_lint.py` passed earlier in this session, before the final drafts (the Book 1 files were not edited).

**Audio is not generated.** Strict `rtk python3 tools/situations/lint.py` will therefore report missing MP3s. The Test book's `carambole/Debug/testbook_situation.json` was not replaced, and the app was not built or installed. No phone testing occurred.

## Open content review

The first-half judge's scoped re-review found four concrete issues after most earlier fixes were addressed. Check the current drafts, then resolve any that remain:

1. `order_d06`: the `Je veux` bank tile can form a plausible unaccepted polite answer.
2. `order_d08`: after the server line changed to `Tu veux un café ?`, the comprehension prompt and miss quote still referred to `On prend un café`.
3. `size_d03`: the cue described two coffees while `Un café pour deux ?` meant one shared coffee.
4. `available_d03`: the cue said *only* two teas remain, while the French stated only that two teas remain.

The first-half author received these findings just before interruption. The second-half author received the full independent review and was revising its role, answer-echo, and follow-up issues when interrupted. Important items to recheck in the current file: `takeaway_s05`, `usual_s05` (speaker point of view); `takeaway_d02/d04/d05`, `pay_d02/d04`, `mixup_d04/d05` (answer printed before a gap); `pay_d08/d09`, `usual_d08`, `takeaway_d08`, `mixup_d08` (follow-up logic); `mixup_d02/d06` (wrong size recoverable from French); `pay_d10` (change versus small change); and spoken-form first teaching. Run another independent scoped review after fixes. The currently passing grammar checker cannot judge these semantic issues.

## Resume sequence

1. Read this file, the original [content handoff](2026-10-11-book-2-content-handoff.md), and `tools/situations/README.md`. Check `rtk git status --short --branch` before editing.
2. Resolve the three current lint errors in the **second-half candidate words**, and audit the open review IDs above in the draft fragments. Run `rtk python3 tools/situations/assemble.py`, then `rtk python3 tools/situations/lint.py --no-audio`, the 46 tests, and `rtk python3 tools/situations/deep_lint.py`.
3. Re-review all corrected cards for natural spoken French, answer uniqueness, cue self-sufficiency, and gloss accuracy. The large baseline `firstSeen:null` vocabulary still deserves an audit against *Fondations*, especially café/payment terms; every tappable token has a gloss, but that alone does not prove new words were taught before grading.
4. Select about nine representative cards in D D S order, covering all six engines and risky moves. Export with `rtk python3 tools/situations/review_set.py <nine item IDs>`. `review_set.py` enforces D D S and no repeated boundary drill type. Then run the pilot content and Swift contract tests.
5. Generate audio only after the content and voices are settled: `rtk python3 tools/situations/generate_audio.py --dry-run` to inspect coverage; `--review` for the Test book clips; the default mode for production item and word clips. Re-run strict lint with audio. The current cast uses the existing Karim, Léa, and Théo Chirp 3 HD voice mapping; no new cast voice was chosen.
6. Build and inspect the Test book on a simulator, then show only the small review set to the user. Do not install on the phone without a new user request. Café approval is the gate before expanding the other 24 modules or starting the production book integration.

**Answered 2026-10-11 (resume):** the Karim/Léa/Théo voices are fine, and Karim switches to *tu* inside café move `usual`, using *vous* everywhere else in module 06.

Two questions were sent asynchronously but no answer had arrived at pause: whether Karim/Léa/Théo sound right on the phone, and whether Karim changes to *tu* in café move `usual`. The current draft assumes the handoff's recommendation: the switch happens inside `usual`; Karim otherwise uses *vous* in module 06.

## Resumed 2026-10-11 — status

- Both halves were reworked, then reviewed by four independent judges (two moves each); all findings applied (`ed2f09f`, `0a419c7`). Full lint, 48 Python tests, Swift pilot contract test and Grammalecte (310 lines, 0 flags) pass.
- Choice order is now spread across slots in the content, because the pilot view does not shuffle choices. The production view should shuffle choices at render time (as Book 1's `displayBank` does) before this matters.
- New lint check: a dialogue's turns plus its built reply must not exceed 3 lines.
- Words wrongly treated as *Fondations* (bonjour, merci, pardon, s'il te plaît, encore, euros, erreur, espèces…) are now taught or avoided. Compositional forms of taught words (*donné*, *m'a*, *me faire*, *au lait*) stay base.
- Review set v4 (9 cards, D D S, all six engines): order_d02, takeaway_d07, size_s03, usual_d04, mixup_d08, available_s02, pay_d04, substitute_d06, usual_s05. Written to `carambole/Debug/testbook_situation.json` with `pilot2_*` audio; built and installed on the iPhone 18 Pro simulator. The old v2 pilot is kept as `tools/pilot/fixtures/testbook_situation_v2.json` for the Swift segmentation tests.
- **Next:** user reviews the 9 cards. Production audio (`generate_audio.py` default mode) only after approval; then the café gate opens Tasks 2–3 and the other 24 modules.
