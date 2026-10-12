# Judge: 13 `sit_13_reason` + `sit_13_wait`

Module file: `carambole/Resources/Situations/13_en_retard_annuler.json`. I checked every token used against `words.json`; all are glossed and in book order (no untaught words). Robin's own lines and every correct answer are feminine; masculine forms appear only as decoys or as the Corriger error.

## sit_13_reason
- [SHOULD] sit_13_reason_d08 — cue leak — The reply prompt "Answer: because of the strike!" comes before the Comprendre. It shows the question was "why", so the choice "Where you are" is easy to rule out without the French. → FIX: comprehend `choices` ["Where you are", "Why you're late"] → ["Why you're not coming", "Why you're late"] (`correct` stays 1). Also make `miss` match the line: « Pourquoi tu es en retard ? » → « Robin, pourquoi tu es en retard ? ».
- [SHOULD] sit_13_reason_d03 — logic — Robin blames her alarm clock for being late to the cinema. People don't need an alarm for a film outing. → FIX: change `cue` to "Théo, your friend, texts you. You're late for a morning coffee with him at the café. He says tu to you."; turn 0 « T'as oublié ? On t'attend au cinéma ! » → « T'as oublié ? On t'attend au café ! »; `followUp` « Bon, le film commence dans dix minutes ! » → « Bon, on prend un café en attendant ! » (*en attendant* is taught in 11).
- [SHOULD] sit_13_reason_d09 — logic — « J'ai oublié mon téléphone à la maison. » is not a reason for being late unless she went back for it. → FIX: learner turn → « J'ai ___ mon téléphone, je suis rentrée. » (*rentrée* is glossed as base; the line is 6 words). Choices and `why` stay the same.
- [NIT] sit_13_reason_d04 — logic — The follow-up « je t'attends au café » assumes a meeting the cue never mentions. → FIX: `cue` → "Karim, your friend from the café, texts you. You're on your way to meet him there. He says tu to you."

## sit_13_wait
- [SHOULD] sit_13_wait_s02 — natural French (Choisir le ton) — The wrong-register option « Ouais, pas grave, bref ! » is not natural French: *bref* doesn't close a reassurance. Choisir le ton needs all three options to be good French. → FIX: choice 1 → « Ouais, pas grave, à tout à l'heure ! »; why[1] → "« Ouais » is too casual for your landlady. She says vous to you."
- [SHOULD] sit_13_wait_d06 — false error — « T'inquiètes » (with -s) is a very common spelling in friends' texts, and this is a text from Théo. A learner who picks it would feel cheated. → FIX: choice 2 « T'inquiètes » → « Ne t'inquiète »; why[2] → "« Ne » needs « pas »: « ne t'inquiète pas », or just « t'inquiète »."
- [SHOULD] sit_13_wait_d04 — false error — Same problem: the bank decoy « t'inquiètes ! ». → FIX: in `bank`, « t'inquiètes ! » → « inquiète ! » (glossed "worried (feminine) / worry"; « Non, cinq minutes, inquiète ! » is not valid French). `accepted` is unchanged.
- [SHOULD] sit_13_wait_d09 — one right answer — « Depuis toujours ! Une heure ! » works as a joking exaggeration ("forever! an hour!"). That undercuts why[1] ("means forever, not one hour"). → FIX: choice 1 « toujours » → « beaucoup » (base word); why[1] → "Not French: « depuis beaucoup ». Say « depuis longtemps »."
- [NIT] sit_13_wait_d02 — natural French — Théo is "presque là", so « à tout à l'heure » (later today) sounds off. → FIX: `followUp` « Super, à tout à l'heure ! » → « Super, à tout de suite ! » only if *à tout de suite* gets glossed. Otherwise use « Super, j'arrive ! ».
- [NIT] sit_13_wait_d08 — natural French — The same problem for Mme Dumas, who is almost there. → FIX: `followUp` « Merci. À tout à l'heure. » → « Merci. J'arrive. »
- [NIT] sit_13_wait_d01 — gloss in context — The model ends with « Ça va ! » ("it's fine"), but the book-wide gloss for *ça va* is "how are you? / I'm fine". → FIX: in `words.json`, change `ça va` `en` → "how are you? / I'm fine / it's fine".
- [NIT] sit_13_wait_d09 — logic — Karim asks « Léa est en retard ? », but the cue never says Robin is waiting for Léa. → FIX: `cue` → "Karim, your friend, works at the café. You're waiting there for Léa. He says tu to you."

Summary: 0 MUST, 7 SHOULD, 5 NIT (12 findings).
reason: 0 MUST / 3 SHOULD / 1 NIT · wait: 0 MUST / 4 SHOULD / 4 NIT.
