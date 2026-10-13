# Judge findings: 18_comparer.json, sit_18_pros + sit_18_decide (30 items)

## Gloss findings (dump check of every key=gloss pair)

- [MUST] sit_18_pros_d05 — gloss — The follow-up « Pardon ! Un inconvénient : il n'y a pas de balcon. » segments as `il n'y a`=there isn't / there aren't · `pas`=not · `de`=of / from. The learner reads "there isn't · not · of/from balcony", which is a double negative. → FIX: in words.json, add the phrase key `{"fr": "il n'y a pas de", "en": "there's no, there isn't any", "spoken": false, "audio": "sitw_il_n_y_a_pas_de", "firstSeen": null}` (Fondations). Add its elided twin `{"fr": "il n'y a pas d'", "en": "there's no, there isn't any", "spoken": false, "audio": "sitw_il_n_y_a_pas_d", "firstSeen": null}` too, for the other modules' « Il n'y a pas d'eau chaude ». A book-wide grep shows that every « il n'y a pas de/d' » in 01–20 means "there's no" (réseau ×2, balcon, eau chaude ×3), so the new key is safe everywhere. Then run generate_audio for the two new keys.
- [SHOULD] sit_18_pros_d05 — gloss — The agent's turn « Il y a un inconvénient : pas de balcon. » shows bare `pas`=not · `de`=of / from, so the learner reads "not · of/from balcony". A general « pas de » key is not safe, because « Tu n'es pas de Lyon » / « je ne suis pas de… » mean "not from". → FIX: turns[0].text « Il y a un inconvénient : pas de balcon. » → « Un inconvénient : il n'y a pas de balcon. » This is 8 words, and the key above covers it. The follow-up stays « Pardon ! Un inconvénient : il n'y a pas de balcon. » That is the same line, said again, which suits a repeat request. Regenerate the audio for sit_18_pros_d05_t0.

I checked every other pair under the 30 IDs and found nothing else. A few were close calls but fit their sentences: `plus`=more / most / no more in « plus rapide », « le plus lumineux » (the right sense comes first); `moins`=less in « le moins cher » ("the less expensive" one of two); `n'es`=are (not) (tu); `temps`=time / weather in « ça dépend du temps »; `prend`=takes in « Inès prend l'appartement ? »; `entre`=between, among; `comment`=how in « Il est comment ? »; `par`=by / per in « convaincue par ». Decoys keep their real glosses, which is the convention.

**Gloss findings: 2 (1 MUST, 1 SHOULD).**

## Other findings

- [SHOULD] sit_18_pros_s01 — natural French — Inès asks « Il est comment ? » and Robin answers « Cet appartement a un avantage… ». Repeating the demonstrative right after the question sounds stiff. People say « Il a un avantage… ». "Karim's flat" is also an odd, unexplained detail. → FIX: turns[0].text → « Tu as visité un appartement ce matin ? Il est comment ? » (10 words). Cue → "Inès, your colleague, asks about a flat you visited. She says tu to you." (unchanged). In bank, replace tile "Cet appartement" with "Il". accepted[0] and model → « Il a un avantage : il est près du métro, mais il est petit. » (12 words). The other decoys stay.
- [SHOULD] sit_18_pros_d10 — natural French — « Un inconvénient de ton quartier ? » is telegraphic and textbook-like. → FIX: turns[0].text → « Et ton quartier, il a un inconvénient ? ». In the comprehend drill, miss → "Reread: « ton quartier, il a un inconvénient ? »". Reply, bank and follow-up stay unchanged. The decoy tile "il a" still fails, because « Par contre, il a près du métro » is not French.
- [SHOULD] sit_18_pros_d04 — natural French — Karim's « Le vélo, c'est un avantage pour toi ! » is vague. An advantage for her compared with what? → FIX: turns[0].text → « Venir à vélo, c'est un avantage pour toi ! ». Every word here is taught or base. Mot target « avantage » stays visible, and the reply « Oui, c'est plus rapide que le métro ! » still fits.
- [SHOULD] sit_18_decide_d08 — miss quote — The miss quotes « Inès prend l'appartement ? », but that is not the printed line. → FIX: miss → "Reread: « Votre amie Inès prend l'appartement, madame ? »".
- [NIT] sit_18_pros_d01 — natural French — « Le centre-ville, c'est un avantage ! » is understandable, but a speaker would say what about the centre helps. → FIX (optional): turns[0].text → « Habiter au centre-ville, c'est un avantage ! ». Check that *habiter* is a base word (Fondations). If it is not, keep the line. The comprehend prompt still works.
- [NIT] sit_18_decide_s04 — logic/place — If Robin is at the agency, "send me photos" is an odd request. → FIX: place « À l'agence · phrase seule » → « Appel · agence · phrase seule ». Cue → "You texted this to Inès (tu) about photos of a flat. Now say it to the estate agent (vous) on the phone."
- [NIT] sit_18_decide_s02 — natural French — In the correct option, « Ça dépend du prix, je crois. » hedges about Robin's own deciding factor, which reads a little oddly. → FIX (optional): choices[1] → « J'hésite encore, madame. Ça dépend du prix. ». The *vous* cue still comes from « madame »; the why lines are unchanged.

## Checks passed

- I checked all 30 items. Every Comprendre `correct` points at the true choice (pros d01, d02, d03, d06, d08, d09, d10; decide d01, d02, d03, d06, d08, d09, d10).
- The two Choisir le ton items (pros_s02, decide_s02) have three natural French options each, and only one is in the right register. Neither uses bref or ouais.
- No verb and past participle share an audio key. hésite, hésites, hésiter, convaincu, convaincue, convaincus, dépend, dépends and dépendre each have their own slug.
- Robin's lines are feminine (convaincue in decide d03, d07, s04; s03 corrects convaincu → convaincue). No masculine self-form appears in learner lines, accepted replies or correct picks.
- No grammar goes beyond Fondations.
- Book order is OK: avantage d01, inconvénient d02, par contre d03, j'hésite d01, ça dépend d02 and convaincue d03 are not used early. ça vaut le coup (better) comes before decide.
- Each reply has one valid sequence, or every valid order is in `accepted`. Dropping the last tile never gives an accepted reply.
- Place labels match their cues. No repeat request goes to a text. Register is right everywhere.

## Summary

MUST 1 · SHOULD 5 · NIT 3 (9 findings; gloss findings 2).
Worst: (1) pros_d05: « il n'y a pas de » shows "there isn't · not" (needs the new key); (2) pros_d05: « pas de balcon » shows "not · of/from" (rewrite the turn); (3) pros_s01: the stiff « Cet appartement a… » answer to « Il est comment ? ».
