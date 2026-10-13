# Judge findings: 17_une_galere.json, sit_17_react + sit_17_sympathise (30 items)

Checked: all 30 items against judge.md §1–9, every `key=gloss` pair in dumps/17.md for these IDs, book order of every token (0 early words; script check of each dump key's `firstSeen` against book order), audio-key collisions (none: perdu/perdue/perdre, oublié/oubliée, dur/dure, énervant all distinct), every Comprendre `correct` (all 20 point at the true choice), every Choisir le ton option (all natural French), Robin's feminine forms (all correct; `sympathise_d08` cue says "You're a woman."), grammar ceiling (no venir de / en train de / plus-que-parfait / gérondif / le mien / ce qui).

## Findings

- [MUST] sit_17_react_d04 — gloss — « Mince, il n'y a plus de croissants ! » segments as il n'y a="there isn't / there aren't" · plus de="no more" · croissants → "there aren't no more croissants" (double negative). → FIX: words.json add phrase key `{"fr": "il n'y a plus de", "en": "there's no more / there are no more", "spoken": false, "audio": "sitw_il_n_y_a_plus_de", "firstSeen": null}` (Fondations 05_negation teaches « il n'y a plus »). Book-wide check: every other use (« Il n'y a plus de pain », « …de fromage », « …de lait ») is the same sense, so the key fits all of them. Needs a plain generate_audio run.

- [MUST] sit_17_sympathise_d06 — logic — Cue: "Léa … comes home late", place « À l'appart ». Her follow-up « Oui ! Je rentre en taxi, alors. » says she is going home now, but she is already home. → FIX: `followUp` « Oui ! Je rentre en taxi, alors. » → « Oui ! Je suis rentrée en taxi. » (*rentrée* is a base entry, "come home, got back (feminine)"). Or, with no past tense: « Oui ! Et le taxi, c'était cher ! »

- [MUST] sit_17_sympathise_d04 — hidden valid reply — The bank builds « Rentre et repose-toi ! » (tiles Rentre / et / repose-toi !). It is valid French and fits "Tell Théo to go home and rest", but it is not accepted. → FIX: `accepted` add `["Rentre", "et", "repose-toi !"]`, or merge the tiles: bank `["Rentre à la maison", "et", "repose-toi !", "Rentrez à la maison", "reposez-vous !"]`, accepted/model `["Rentre à la maison", "et", "repose-toi !"]`.

- [SHOULD] sit_17_react_s01, sit_17_react_d10 — gloss — « je n'ai pas mes clés » and « je n'ai pas d'espèces » show je n'ai pas="I haven't / I didn't". With a noun object this reads "I haven't my keys" / "I didn't cash". → FIX: widen words.json `je n'ai pas` en → "I don't have / I haven't / I didn't". Book-wide uses all fit: « je n'ai pas mes clés » ×3, « je n'ai pas le ticket », « je n'ai pas d'espèces », « je n'ai pas trouvé », « je n'ai pas réservé ». The audio is unchanged.

- [SHOULD] sit_17_react_s05 — gloss — « Léa n'est pas à la maison » shows n'est="is (not)" · pas="not", which reads as a double negative. → FIX: words.json add `{"fr": "n'est pas", "en": "isn't, is not", "spoken": false, "audio": "sitw_n_est_pas", "firstSeen": null}` (Fondations 02/05). Caveat for the coordinator: « ce n'est pas grave » then segments as n'est pas · grave, not n'est · pas grave. Add a key `ce n'est pas grave` = "it's no big deal, never mind" (base) at the same time, or check the matcher's tie-breaking first. Every other book use (« ce n'est pas cher / normal / ma faute / loin », « il n'est pas là ») fits "isn't".

- [SHOULD] sit_17_react_d09 — gloss — « Encore de la pluie ce week-end ? » shows de="of / from" · la="the (feminine)", which reads as "more of the rain". This is a partitive, so the meaning is "(some) rain". → FIX: words.json add `{"fr": "de la", "en": "some / of the", "spoken": false, "audio": "sitw_de_la", "firstSeen": null}` (Fondations 11_pluriels_partitif). "of the" still covers « près de la », « à côté de la ». Or rewrite locally: « Encore la pluie ce week-end ? Sans blague ! » (the comprehend `miss` changes to match).

- [SHOULD] sit_17_react_d09 — gloss — In the gap line « Aïe ! Et ___ fait froid aussi ! », *fait* shows "does / makes / done, made / comes to", but this is weather. → FIX: words.json add `{"fr": "fait froid", "en": "is cold (weather: il fait froid)", "spoken": false, "audio": "sitw_fait_froid", "firstSeen": null}`. The filled line still matches the longer « il fait froid ».

- [SHOULD] sit_17_sympathise_d04 — gloss — In the reply « Rentre à la maison et repose-toi ! », *rentre* shows "come home / comes home", but Robin is at the café telling Théo to go home. → FIX: widen words.json `rentre` en → "go / come home, goes home". Book-wide uses fit: « Rentre vite chez toi », « Rentre à la maison, alors », « je rentre tard / à pied / en taxi ».

- [SHOULD] sit_17_react_d10 — cue leak — The cue "You want to pay by card." gives away the Comprendre answer ("The card machine isn't working" vs the coffee machine) without the learner reading « le terminal ». → FIX: `cue` → "Karim, the barista, says tu to you. You're at the counter to pay."

- [SHOULD] sit_17_react_d02 — natural French / logic — The cue says Robin is waiting for Théo alone, but her line is « Pas grave, on est au café ! » ("we're at the café"). → FIX: `cue` → "Théo, your friend, texts you. You and Léa are waiting for him at the café. He says tu to you." The gap and choices stay as they are.

- [SHOULD] sit_17_sympathise_d08 — hidden valid reply — The bank builds « Reposez-vous ! Je suis désolée, madame. », which is valid and covers both parts of the prompt. → FIX: `accepted` add `["Reposez-vous !", "Je suis désolée,", "madame."]`. Or lock the order in the prompt: "First say you're sorry, madam, then tell her to rest."

- [SHOULD] sit_17_sympathise_d10 — hidden valid reply — The bank builds « Repose-toi ! Oh, mon pauvre ! », which is valid. → FIX: `accepted` add `["Repose-toi !", "Oh,", "mon pauvre !"]`.

- [SHOULD] sit_17_sympathise_s04 — place label — The place is « Appel · Inès · phrase seule », but the cue never says it is a call. → FIX: `cue` → "You said this to Théo, your friend (tu). Now Inès, your colleague (tu, a woman), is tired too. Say it to her on the phone."

- [NIT] sit_17_sympathise_d07 — gloss — In the follow-up « Je prends le bus, alors. », *je prends* shows "I'll have / I take". "I take" works, but "I'll have the bus" reads oddly (the same issue as the 16 dinner note). → FIX (optional, book-wide): widen to "I'll have / I'll take / I take".

- [NIT] sit_17_sympathise_s01, sit_17_sympathise_d10 — gloss — In « je suis fatigué et seul » / « malade et seul », *seul* shows "alone, on (my, his) own" where "lonely" is meant. "Alone" is acceptable. → FIX (optional): « malade et tout seul » or keep.

- [NIT] sit_17_sympathise_d04 — logic — Karim asks « Tu as mal au dos, Théo ? » and immediately answers his own question with « Oh, mon pauvre ! ». → FIX: `turns[0].text` → « Mal au dos, Théo ? Oh, mon pauvre ! » (an echo of what Théo said, which is natural).

- [NIT] sit_17_sympathise_s05 — logic — Robin asks « tu es encore malade cette semaine ? » and then sympathises before any answer. → FIX: « Théo, tu es encore malade cette semaine ! Oh, ___ ! »

- [NIT] sit_17_react_s01 — natural French — The prompt makes Robin stack « Aïe ! Mince, … ». Two interjections in a row are slightly heavy. → FIX (optional): drop the "Aïe !" tile. Prompt → "Say darn, ask if she forgot her keys, and say you're coming." Bank: remove "Aïe !". accepted/model: « Mince, tu as oublié tes clés ? J'arrive ! »

## Summary
MUST 3 · SHOULD 10 · NIT 5 (18 findings). Gloss-class findings: 8 (1 MUST, 5 SHOULD, 2 NIT).
Worst: react_d04 « il n'y a plus de » double-negative gloss; sympathise_d06 follow-up has Léa going home when she is already home; sympathise_d04 « Rentre et repose-toi ! » is buildable but not accepted.
