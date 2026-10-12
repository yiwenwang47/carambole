# Book 2, arc 2 *Le quartier*: plan for modules 07–10

**Date:** 2026-10-11
**Status:** paper plan only. No French is authored. Nothing is committed. `modules.json` is unchanged (entries in §10).
**Matrices:** [07](2026-10-11-book-2-arc2-module-07-matrix.md) · [08](2026-10-11-book-2-arc2-module-08-matrix.md) · [09](2026-10-11-book-2-arc2-module-09-matrix.md) · [10](2026-10-11-book-2-arc2-module-10-matrix.md)
**Rulebook:** [content handoff](2026-10-11-book-2-content-handoff.md) §3–§8; [café handoff](2026-10-11-book-2-cafe-handoff.md) §3; [next-session handoff](2026-10-11-book-2-next-session-handoff.md) §2 (binding user decisions) and §4 (judge finds); `tools/situations/README.md`.

Module 06 *Au café* opens the arc and is done. Everything 01–06 teaches is known here (159 taught words in `words.json`), and every café phrase (*ça fait, il reste, plus de, à la place, par carte, en espèces, monnaie, en panne, je crois, une erreur, comme d'habitude…*) is free to use.

Each matrix has one row per item (8 moves × 15 items = 120 per module) in the arc 1 format, plus a new-word table with the exact `en` / `spoken` / `audio` for every new word. A validator (in the planning scratchpad, not in the repo) checked all 480 rows before the matrices were written: item order and standalone labels; 1–2 drills per dialogue, no repeated type, no Répondre + Choisir; no same drill engine back to back across item boundaries; ≥4 dialogue types and Répondre + Compléter ≥ half per move; one *Clarify* dialogue per move, never on a text, group chat or voicemail; ≥2 dialogues off the home channel; ≤2 new words per item, each printed in its first-seen item; each new word in ≥2 later dialogues and a later Mot or Mot en retour inside its own move; Mot targets visible in a quoted line; book order for every quoted token and every choice (against *Fondations* answers, `words.json` and this batch's own order); answer echo in every Fill row; new phrase keys against all earlier module text; audio-key collisions.

## 1. Fixed decisions this plan builds on

- **Robin** is a woman from Eugene, Oregon. Her lines are feminine only (*désolée, perdue, remboursée, je me suis trompée*). A cue says "You're a woman." wherever an answer hinges on it (08 `refund`, 09 `name d07` and `arrive s03`, 10 `ask`).
- **Karim** says *tu* everywhere in this arc (after café `usual`), and Robin says *tu* to him. He appears in 07 `pastry`, 07 `hours`, 09 `book`, 09 `voicemail`, 10 `turn`, 10 `transit`.
- **M. Ferrand** and **Mme Dumas**: *vous* always. **Léa, Inès, Théo**: *tu*. In the group chat Théo's *vous* is plural; the cue says « vous = you all ».
- **One-off staff are unnamed** (baker, stallholders, shop staff, waiters, the delivery driver, passers-by). The matrices give a role in the Cast column only so the author can set `voice: "female"` for a woman; the `name` field stays empty. Staff always say *vous* and may call Robin « madame ».
- **Underlines** mean "new here" only (user decision 4). A word taught in 01–06 is never put back in `newWords`.
- **Glossed base words** that stay untaught: *tout le monde, ah, oh, pas de problème, bonne journée, ça me va* (user decision 5), plus *c'est tout* (§6).
- Per move: 10 dialogues + 5 standalones (Construire, Choisir le ton, Corriger, Transformer, Mot en retour).

## 2. Conventions new in this arc

1. **Fixed facts (Robin's street).** Robin and Léa live at **« huit, rue Pasteur »**, **au troisième étage**, in an *immeuble* whose front door Mme Dumas has just painted **blue** (08 `colour d10`). The door code is **« deux, cinq, huit »**. The building is **next to the bakery** (*à côté de la boulangerie*, *juste après la boulangerie*) and **opposite the pharmacy** at the corner of the street (*la pharmacie au coin, en face*). The market and the station are nearby. Each dialogue still stands alone: a cue restates any fact the answer needs, exactly like Eugene in arc 1. Open question 1.
2. **Numbers stay words.** The book has no digits in French lines, so addresses, codes and prices are written in words (*huit, rue Pasteur*; *trois euros le kilo*). Prices are small whole numbers and never need arithmetic.
3. **Places** (`place`, plain text): `À la boulangerie`, `Au marché`, `En boutique`, `Au restaurant`, `Dans la rue`, `À l'appart` (the book-wide home label, used since 01), `Sur le palier`, `Au bureau`, `Au café`, `Texto · <name>`, `Les copains · groupe`, `WhatsApp · Mme Dumas`, `Appel · <name>`, `Messagerie · <name>`, and for staff `Appel · restaurant`, `Texto · restaurant`, `Messagerie · restaurant`, `Appel · livreur`, `Appel · boutique`. Do not print *appart* in a French line: it was never glossed (only the arc 1 label « À l'appart » uses it); lines say *à la maison*.
4. **Standalone place labels match the cue** (judge find §4). The matrices give each standalone its own setting plus « · phrase seule » (for example `WhatsApp · Mme Dumas · phrase seule`, `Texto · Léa · phrase seule`), not the move's home place.
5. **Standalone sketches are short.** Lint wants 8–14 words in a standalone line, so the author lengthens each Corriger, Transformer and Mot en retour line to that range with taught words only.
6. **Elided forms are separate keys.** The lint splits on spaces, so *l'immeuble* is not the key *immeuble*. Each new word is planned so that its first-seen item, its Mot drill and its two counted recurrences use the bare key form (*votre immeuble, son anniversaire, au troisième arrêt*). Elided forms that appear later (*l'immeuble, l'adresse, l'arrêt, l'anniversaire, l'échanger*) get a `firstSeen: null` entry with the same gloss prefixed by "the" or the pronoun, and only after the bare word is taught.
7. **Key form is the printed form.** *Croissants, tomates, fraises, abricots, mûres, soldes, personnes* are keyed in the plural, because that is how the lines use them; the singular is an inflection entry. *Bien cuite, je me suis trompée, végétarienne* are keyed in the feminine, because Robin, the bread or Inès needs that form.
8. **New phrase keys checked against earlier text.** None of the 103 new keys matches any line in 01–06. Two candidates were dropped for that reason: spoken *y a* (01 prints « Il y a du pain », and the lint counts any « y a » inside « il y a » as an early use) and *c'est tout* as a taught word (01 prints « Ferrand, c'est tout ! »). See §6.
9. **Gloss traps in existing entries** (judge find "glosses wrong in context"). Authors must not write: *lit* as "reads" (glossed "bed"), *la place* as "square" (glossed "place, instead"), *une livre* as "half a kilo" (glossed "book"), a bare *carte* (untaught; *par carte* only), *ligne A* without its phrase entry (the token *a* is glossed "has"), *je regarde* for "I'm just looking" (02 uses *je regarde* = watch; the new key is *je regarde juste*), *ça te va / ça vous va* for "it looks good on you" (05's keys mean "does that suit you?"; the new keys are *ça te va bien / ça vous va bien*), *merci de* except before an infinitive (« merci pour le message »), and *goûter* as the snack noun.
10. **Phrase keys across a comma** (judge find). Keys match through punctuation, so never write « Ça vous va, bien sûr ? » (matches *ça vous va bien*), « Merci, de rien » (matches *merci de*) or « C'est, tout… ».
11. **Wide glosses for words later modules will reuse:** *ticket* = "receipt, ticket" (transport tickets in 11), *ligne* = "line (metro, tram, phone)", *laisser* = "to leave, let", *perdu* = "lost" (lost keys in 12), *tradition* = "traditional baguette / tradition", *je descends* = "I'm coming down / I get off".
12. **Drafts:** `NN_<slug>_first_half.json` / `_second_half.json`, each with its `_words.json` (`07_boulangerie_et_marche_first_half.json`, `08_en_boutique_…`, `09_reserver_…`, `10_se_reperer_…`).

## 3. Move lists

Moves 1–4 go to author agent 1 (first half) and moves 5–8 to author agent 2 (second half). Each new word belongs to the half where it first appears, and its recurrences and Mot drill stay inside its own move, so the halves never depend on each other's drafts. A second-half item that reuses a first-half word copies its entry from the matrix's word table, which already fixes `en`, `spoken` and `audio`.

### 07 *Boulangerie et marché*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_07_bread` | Commander du pain | 1st | 4 (baguette, tradition, boulangerie, bien cuite) | The culture move: *une tradition* rather than a plain *baguette*, and how you like it baked (*bien cuite*). *Bonjour* first, from café. |
| `sit_07_pastry` | Les viennoiseries | 1st | 3 (croissants, pain au chocolat, tarte) | *Croissant, pain au chocolat, une tarte aux pommes*; *en* with a number (« j'en prends deux ») and *aux* for a flavour. |
| `sit_07_quantity` | Les quantités au marché | 1st | 3 (tomates, barquette, fraises) | Market quantities: *un kilo de*, *une barquette de*, and *de* (not *des*) after a quantity. |
| `sit_07_price` | Demander le prix | 1st | 3 (c'est combien, le kilo, prix) | *C'est combien ?*, prices *le kilo* and *la barquette*, *cher* with *c'est* (always masculine). Prices stay small whole numbers in words; no arithmetic. |
| `sit_07_taste` | Choisir et goûter | 2nd | 3 (goûter, mûres, abricots) | Market small talk: *goûter* before buying, *bien mûres*, and agreement (*mûres* with *fraises*, *mûrs* with *abricots*). |
| `sit_07_anything` | « Et avec ceci ? » | 2nd | 3 (et avec ceci, ce sera tout, douzaine) | The shop ritual: *Et avec ceci ?* — *Ce sera tout* / *C'est tout*, plus *une douzaine*. *C'est tout* is a glossed base phrase (01 already prints it). |
| `sit_07_hours` | Horaires et fermetures | 2nd | 4 (fermé, ouvert, jusqu'à, août) | Culture move: shops close on Monday, the market is Sunday morning, and the whole street shuts *en août*. *Ouvert / fermé* agree with the shop (*la boulangerie est fermée*). |
| `sit_07_errand` | Faire les courses pour quelqu'un | 2nd | 3 (frigo, liste, je m'en occupe) | Social move: errands for the flat and the group. *le frigo*, *la liste*, and *je m'en occupe* to volunteer. |

### 08 *En boutique*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_08_browse` | Entrer et regarder | 1st | 3 (je cherche, je regarde juste, pull) | The shop opening: *Je peux vous aider ?* — *Je cherche…* or *Non merci, je regarde juste.* Saying you're just looking is the polite default. |
| `sit_08_size` | Demander une taille | 1st | 3 (taille, pantalon, au-dessus) | Sizes without numbers: *ce n'est pas ma taille*, *trop grand / trop petit*, *la taille au-dessus*. Agreement with the item (*le pantalon… il est trop petit*). |
| `sit_08_fitting` | Essayer | 1st | 4 (essayer, cabine, ça vous va bien, ça te va bien) | *Je peux essayer ?*, *la cabine*, and the compliment *ça vous va bien / ça te va bien* (looks good on you). New phrase keys, kept apart from 05's *ça te va ?* (does it suit you). |
| `sit_08_colour` | Choisir une couleur | 1st | 3 (couleur, bleu, chemise) | *Une autre couleur*, *en bleu*, and colour agreement (*un pull bleu, une chemise bleue*). Mme Dumas paints the building door blue, a fact module 10 reuses. |
| `sit_08_gift` | Acheter un cadeau | 2nd | 3 (c'est pour offrir, anniversaire, paquet cadeau) | Social and culture move: buying for someone's *anniversaire*, *c'est pour offrir ?*, the shop's free *paquet cadeau*. *Son anniversaire* (son before a vowel, even for a woman). |
| `sit_08_checkout` | Payer et les soldes | 2nd | 4 (payer, caisse, soldes, ticket) | *Payer* (café avoided it), *la caisse*, *le ticket*, and *les soldes* (the culture of the January and July sales). *Par carte / en espèces* come back from café. |
| `sit_08_exchange` | Échanger | 2nd | 3 (échanger, abîmé, rapporter) | Going back to the shop: *échanger*, *rapporter*, *abîmé*, always with *le ticket*. Includes a phone call to the shop. |
| `sit_08_refund` | Se faire rembourser | 2nd | 3 (rembourser, vendeuse, responsable) | Asking for a refund politely: *rembourser*, *être remboursée* (Robin is a woman: Corriger and Compléter target it), *la vendeuse*, *le responsable*. |

### 09 *Réserver*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_09_book` | Réserver une table | 1st | 3 (personnes, jeudi, un instant) | The call: *je voudrais réserver une table* (a *Fondations* sentence), *pour combien de personnes ?*, a day, and *un instant* while they check. |
| `sit_09_slot` | Trouver un horaire | 1st | 3 (complet, mercredi, ça vous irait) | When the slot is gone: *c'est complet*, another day (*mercredi*), and the polite offer *ça vous irait ?* (conditional, *Fondations* 22). |
| `sit_09_name` | Donner son nom | 1st | 3 (à quel nom, au nom de, numéro) | *À quel nom ?* — *au nom de Robin*, and *votre numéro de téléphone*. No spelling and no phone numbers on screen. |
| `sit_09_options` | Terrasse ou intérieur | 1st | 3 (en terrasse, à l'intérieur, végétarienne) | Choosing where to sit (*en terrasse*, *à l'intérieur*) and checking a friend's diet (*végétarienne*: Inès). Weather words from 03 decide it. |
| `sit_09_voicemail` | Laisser un message | 2nd | 4 (laisser, message, bip, rappelez-moi) | Voicemail both ways: understand the greeting (*laisser un message après le bip*) and leave one (*rappelez-moi*). Nobody asks a voicemail to repeat: the clarification is a live call. |
| `sit_09_confirm` | Confirmer | 2nd | 3 (réservation, confirmer, merci de) | The restaurant's text: *votre réservation*, *merci de confirmer*, and your short written answer. Prices, times and names come back. |
| `sit_09_change` | Modifier une réservation | 2nd | 3 (modifier, avancer, mardi) | Changing the booking: *modifier*, *avancer* (the opposite of 05's *décaler*), and *mardi*. Groups negotiate it in the chat first. |
| `sit_09_arrive` | Au restaurant | 2nd | 3 (bonsoir, suivez-moi, installez-vous) | On the night: *bonsoir* (new: the evening greeting), *j'ai réservé au nom de…*, *suivez-moi*, *installez-vous*. Corriger targets the tempting *j'ai réservée*. |

### 10 *Se repérer*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_10_address` | Donner son adresse | 1st | 3 (adresse, immeuble, troisième) | The fixed facts of arc 2: Robin lives *huit, rue Pasteur*, *au troisième étage*, in an *immeuble* with a blue door (08). Cues restate them every time. |
| `sit_10_lost` | Le livreur est perdu | 1st | 4 (livreur, colis, perdu, je ne trouve pas) | The syllabus scene: a delivery driver with *un colis* who is *perdu* and *ne trouve pas* the street. Robin calms him down and guides him. |
| `sit_10_landmark` | Donner des repères | 1st | 3 (pharmacie, au coin, vous voyez) | Landmarks before turns: *la pharmacie au coin*, *vous voyez… ?*, plus *en face* and *à côté* from 03. The pharmacy is set up here for module 14. |
| `sit_10_turn` | Tourner | 1st | 3 (au feu, deuxième, pont) | Turns: *tournez à droite / à gauche* (*Fondations* 20) at *le feu*, *la deuxième rue*, after *le pont*. *Tu* and *vous* imperatives side by side. |
| `sit_10_straight` | Tout droit | 2nd | 3 (au bout de, juste après, derrière) | Distance words: *tout droit* (*Fondations* 20), *jusqu'au bout de la rue* (*jusqu'à* from 07), *juste après*, *derrière*. |
| `sit_10_door` | En bas de l'immeuble | 2nd | 4 (code, interphone, je descends, en bas) | The last metres: *le code*, *l'interphone*, *je descends*, *en bas*. Robin's code is « deux, cinq, huit » (the cue restates it). |
| `sit_10_ask` | Demander son chemin | 2nd | 3 (c'est par où, je me suis trompée, chemin) | Now Robin is the lost one: *c'est par où ?*, *le chemin*, and *je me suis trompée de rue* (feminine: Corriger and Compléter target it; cues say "You're a woman"). |
| `sit_10_transit` | Métro et tram | 2nd | 3 (ligne, arrêt, tram) | Public transport directions: *la ligne*, *l'arrêt*, *le tram*, *descendez à…* (Lyon's metro lines are letters, so *ligne A / ligne B* get phrase glosses). |

## 4. Totals

| Module | New words (1st / 2nd half) | Spoken forms | Dialogues not face to face (of 80) | Channel mix (dialogues) |
|---|---|---|---|---|
| 07 Boulangerie et marché | 26 (13 / 13) | — | 23 | face to face 57, Texto 12, Les copains 9, WhatsApp 1, Appel 1 |
| 08 En boutique | 26 (13 / 13) | — | 22 | face to face 58, Texto 11, Les copains 9, WhatsApp 1, Appel 1 |
| 09 Réserver | 25 (12 / 13) | — | 65 | Appel 37, face to face 15, Texto 12, Les copains 8, Messagerie 8 |
| 10 Se repérer | 26 (13 / 13) | — | 62 | Appel 34, Texto 20, face to face 18, WhatsApp 4, Les copains 4 |
| **Arc 2 (07–10)** | **103** | **0** | **172 of 320** | |

07 and 08 are mostly face to face because the syllabus puts them at the counter and in the shop; texts, the group chat, the landing and the office give each move its 3–5 off-home dialogues. 09 and 10 follow the syllabus channels (calls, voicemail, the lost driver's call). No spoken form is new in this arc: the service scenes are *vous*, and the *tu* exchanges reuse *t'es, t'as, ouais, top, carrément, pas de souci, je sais pas* (open question 3). Per move, every new word recurs in at least two later dialogues of the same move and gets a later Mot or Mot en retour drill; no item introduces more than two new words.

## 5. Cross-module word progression

Each word is taught once, in the earliest module that needs it. Later modules reuse it freely and never put it back in `newWords`.

| Module | Words taught (book-wide first) | Carried into later arc-2 modules |
|---|---|---|
| 07 | *baguette*; *tradition*; *boulangerie*; *bien cuite*; *croissants*; *pain au chocolat*; *tarte*; *tomates*; *barquette*; *fraises*; *c'est combien*; *le kilo*; *prix*; *goûter*; *mûres*; *abricots*; *et avec ceci*; *ce sera tout*; *douzaine*; *fermé*; *ouvert*; *jusqu'à*; *août*; *frigo*; *liste*; *je m'en occupe* | *boulangerie* (10); *fermé* (10); *ouvert* (10); *jusqu'à* (08, 10); *je m'en occupe* (09) |
| 08 | *je cherche*; *je regarde juste*; *pull*; *taille*; *pantalon*; *au-dessus*; *essayer*; *cabine*; *ça vous va bien*; *ça te va bien*; *couleur*; *bleu*; *chemise*; *c'est pour offrir*; *anniversaire*; *paquet cadeau*; *payer*; *caisse*; *soldes*; *ticket*; *échanger*; *abîmé*; *rapporter*; *rembourser*; *vendeuse*; *responsable* | *je cherche* (09); *bleu* (10) |
| 09 | *personnes*; *jeudi*; *un instant*; *complet*; *mercredi*; *ça vous irait*; *à quel nom*; *au nom de*; *numéro*; *en terrasse*; *à l'intérieur*; *végétarienne*; *laisser*; *message*; *bip*; *rappelez-moi*; *réservation*; *confirmer*; *merci de*; *modifier*; *avancer*; *mardi*; *bonsoir*; *suivez-moi*; *installez-vous* | *au nom de* (10); *laisser* (10) |
| 10 | *adresse*; *immeuble*; *troisième*; *livreur*; *colis*; *perdu*; *je ne trouve pas*; *pharmacie*; *au coin*; *vous voyez*; *au feu*; *deuxième*; *pont*; *au bout de*; *juste après*; *derrière*; *code*; *interphone*; *je descends*; *en bas*; *c'est par où*; *je me suis trompée*; *chemin*; *ligne*; *arrêt*; *tram* | — (11 onward) |

**Vocabulary audit** (grep of every new key against the answer sentences in `Resources/Topics/*.json`): 102 of the 103 keys are absent from *Fondations*. The exception is *perdu*: Book 1 has it once, in « j'ai perdu mes clés » (lost an object). It is taught here in the sense "lost, can't find the way", like *courir* and *passer* in arc 1 (open question 4). The reverse also holds: these *Fondations* phrases are the core of 09–10 but stay **base** (glossed, never underlined), because Book 1 has them in exactly this sense: *je voudrais réserver une table* (22), *tournez à gauche / à droite*, *continuez tout droit*, *prenez la première rue* (20), *combien ça coûte* (06), *cher* (19), *un kilo de pommes* (11), *premier étage* (14), *restaurant, menu, robe, manteau*. The new words in 09–10 are built around them.

## 6. Words moved between modules, avoided or deferred

- **From café or arc 1: none.** Arc 2 comes after café in book order, so no café word has to move earlier, and no arc-1 entry changes.
- **Within the batch** (taught once, reused later): *jusqu'à* (07 → 08, 10), *boulangerie, fermé, ouvert* (07 → 10), *je m'en occupe* (07 → 09), *je cherche* (08 → 09), *bleu* (08 → 10, the blue door), *au nom de, laisser* (09 → 10). *Payer*, which café deliberately avoided, is taught in 08 `checkout`.
- ***c'est tout* becomes a glossed base phrase** (`firstSeen: null`, en "that's all / is that all?"). 01 already prints « Ferrand, c'est tout ! », so a taught key would fail the book-order lint. The syllabus's « c'est tout ? » is still drilled in 07 `anything` (with the taught *et avec ceci ?* and *ce sera tout*). Open question 2.
- **Spoken *y a* is not taught.** It is in `SPOKEN` in `lint.py`, but a taught key "y a" would match « il y a » in 01 (`flat d01`, `d04`, `s04`) and fail the book-order lint. 07 `errand` uses *le frigo* instead. Open question 3.
- **Deferred to later modules on purpose:** *annuler* (13, *Être en retard, annuler*), *pharmacien(ne)* and *ordonnance* (14; 10 only teaches *pharmacie*), *un avoir* (store credit; the noun clashes with the verb's gloss), *la place* = square, *une livre* = pound weight, and digits.

## 7. Grammar recycled from *Fondations*

Book 1 module numbers are in brackets.

- **07:** *en* with a number (« j'en prends une », « je veux bien en goûter un », 18); quantity + *de* (« un kilo de tomates », « une barquette de fraises », Corriger on *des*, 11); *aux* for a flavour (« une tarte aux pommes », 10); adjective agreement *cuite, mûres/mûrs, fermée, ouverte* (07); *c'est* + invariable *cher* (07); *pas trop* / *très* before an adjective, *beaucoup* as a wrong option (03 recap); imperative + pronoun *prends-la* (20); *ce sera* as a fixed shop future (21); *est-ce que* questions (06); *il n'y a plus de* (05); *je la prends* (17).
- **08:** adjective agreement with the item (*un pull bleu / une chemise bleue*, *trop petit / petite*, *abîmé / abîmée*, 07); *être remboursée* (Robin, feminine, 14); object pronouns *le / la / les* (« je le prends », « je la prends », 17) and *lui* (« qu'est-ce qu'on lui apporte ? », 17); *son* before a vowel (« son anniversaire », Corriger on *sa*, 08); *pouvoir* + infinitive vs past participle (*payer / payé*, *essayer / essayé*, 13); *vous pourriez* for politeness (22); futur proche (« je vais payer », 12); passé composé (« j'ai rapporté », 13); negation with *ne… pas* in shop refusals (05).
- **09:** days and times with *à* (« jeudi à vingt heures », 10); *ça vous irait ?* as polite conditional (22); *pour* + number + *personnes* and the plural (11); passé composé with *avoir*, no agreement with Robin (« j'ai réservé », Corriger on *réservée*, 13); *ne… pas de* after negation (« je n'ai pas réservé de table », 05); *vous* imperatives (*rappelez-moi, suivez-moi, installez-vous*, 20) against *tu* forms (*rappelle-moi, installe-toi*); object pronouns *me / vous / le* (« tu me rappelles ? », « je vous le donne », 17); *mieux* vs *meilleur* (19); futur proche (« je vais modifier », 12).
- **10:** *vous* and *tu* imperatives side by side (*tournez / tourne, prenez / prends, allez / va, descendez / descends, continue*, 20); ordinals *deuxième, troisième* and *premier* (Book 1 *premier étage*, 14); place prepositions *à côté de, en face de, devant, derrière, au coin de, au bout de* with *de + le = du* (10); *je me suis trompée*: pronominal passé composé with *être*, feminine agreement for Robin (14–15); *perdu* agreeing with the man (*il est perdu*, Corriger on *perdue*, 07); *lui* as indirect object (« je lui ai donné l'adresse », « vous pouvez lui ouvrir ? », 17); passé composé negative (« je n'ai pas trouvé », 13); futur proche (« je vais descendre », 12); *à le → au* (10).

## 8. Shared base glosses (copy byte for byte)

Arc 1 had 33 gloss conflicts at assembly, mostly from two authors glossing the same word differently. Give this section to every author. It has three parts.

### 8.1 Existing `words.json` entries the sketches use in two or more halves

Copied from `words.json`. The last column is the halves whose sketches use the entry (07a = module 07 first half). Copy the entry exactly; never edit it in a draft. Entries used by only one half are not listed here: look them up in `words.json`.

| fr | en | spoken | audio | Used by |
|---|---|---|---|---|
| a | has |  | `sitw_a` | 07a, 07b, 08b, 09a, 09b, 10a, 10b |
| ah | ah / oh |  | `sitw_ah` | 07a, 07b, 10a |
| ah bon | oh really? |  | `sitw_ah_bon` | 07b, 10a |
| ai | have |  | `sitw_ai` | 07b, 10a, 10b |
| allez | go / are doing (vous) |  | `sitw_allez` | 07a, 07b, 10b |
| alors | so / then |  | `sitw_alors` | 07b, 08b, 09a |
| amie | friend (female) |  | `sitw_amie` | 08a, 08b, 09a |
| apporte | bring / am bringing |  | `sitw_apporte` | 08b, 09b |
| après | after |  | `sitw_apres` | 09b, 10a, 10b |
| arrive | is coming / arrives |  | `sitw_arrive` | 09a, 10a, 10b |
| as | have |  | `sitw_as` | 07a, 07b, 08a, 09a, 09b, 10a |
| attends | wait |  | `sitw_attends` | 09a, 10b |
| au | at the / to the |  | `sitw_au` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| aujourd'hui | today |  | `sitw_aujourd_hui` | 07a, 07b, 08b |
| aussi | also / too |  | `sitw_aussi` | 07a, 07b, 08a, 08b |
| avec | with |  | `sitw_avec` | 07a, 07b, 08a, 08b, 10a |
| avez | have |  | `sitw_avez` | 08a, 08b, 09a, 09b |
| beaucoup | a lot / very much |  | `sitw_beaucoup` | 07a, 09a |
| bien | well / good |  | `sitw_bien` | 07a, 07b, 08a, 08b, 09a, 09b, 10a |
| bien sûr | of course |  | `sitw_bien_sur` | 08b, 09b |
| bon | well / OK (also: good) |  | `sitw_bon` | 07a, 07b, 08a, 08b, 09b, 10a |
| bonjour | hello |  | `sitw_bonjour` | 07a, 08a, 08b, 09a, 09b, 10a |
| bonne | good (feminine) |  | `sitw_bonne` | 07b, 08a, 08b, 09a |
| bonne journée | have a good day |  | `sitw_bonne_journee` | 07b, 08b, 09a |
| c'est | it is |  | `sitw_c_est` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| c'est noté | noted |  | `sitw_c_est_note` | 09a, 09b, 10a, 10b |
| café | coffee / café |  | `sitw_cafe` | 07b, 09b, 10a, 10b |
| carrément | totally, definitely | yes | `sitw_carrement` | 08b, 09a |
| ce | this |  | `sitw_ce` | 07a, 07b, 08a, 08b, 09a, 09b |
| ce matin | this morning |  | `sitw_ce_matin` | 07a, 07b |
| ce soir | this evening |  | `sitw_ce_soir` | 07a, 07b, 09a, 09b |
| cette | this (feminine) |  | `sitw_cette` | 08a, 08b |
| chez | at (someone's place) |  | `sitw_chez` | 07b, 10a, 10b |
| cinq | five |  | `sitw_cinq` | 07a, 10b |
| combien | how much / how many |  | `sitw_combien` | 07a, 09a |
| comme | like / as |  | `sitw_comme` | 07a, 08a |
| d'accord | OK, agreed |  | `sitw_d_accord` | 07b, 08a, 08b, 09a, 09b, 10b |
| dans | in |  | `sitw_dans` | 07b, 08a, 08b, 10a, 10b |
| de | of / from |  | `sitw_de` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| demain | tomorrow |  | `sitw_demain` | 07a, 08a, 08b, 09b |
| demander | to ask |  | `sitw_demander` | 08b, 09a |
| des | some |  | `sitw_des` | 07a, 07b, 08a, 08b, 10b |
| deux | two |  | `sitw_deux` | 07a, 07b, 08a, 09b, 10a, 10b |
| devant | in front of, outside |  | `sitw_devant` | 07b, 08a, 09a, 10a, 10b |
| dimanche | Sunday |  | `sitw_dimanche` | 07a, 07b, 09a, 10a |
| dis | say |  | `sitw_dis` | 09a, 10b |
| donner | to give |  | `sitw_donner` | 07b, 09a |
| du | some / of the |  | `sitw_du` | 07a, 07b, 09a, 09b, 10a, 10b |
| désolée | sorry (feminine) |  | `sitw_desolee` | 07a, 08b, 10a, 10b |
| dîner | dinner |  | `sitw_diner` | 09a, 09b |
| elle | she / it |  | `sitw_elle` | 07a, 07b, 08a, 08b, 09b, 10a |
| en | in / by |  | `sitw_en` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| en face | opposite, across the street |  | `sitw_en_face` | 10a, 10b |
| en retard | late |  | `sitw_en_retard` | 09b, 10b |
| es | are (tu) |  | `sitw_es` | 07a, 09b, 10a, 10b |
| est | is |  | `sitw_est` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| est-ce que | (question marker) |  | `sitw_est_ce_que` | 07b, 08b |
| et | and |  | `sitw_et` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| euros | euros |  | `sitw_euros` | 07a, 07b |
| excusez-moi | sorry / excuse me (vous) |  | `sitw_excusez_moi` | 07a, 08b, 10b |
| fais | do / make (je, tu) |  | `sitw_fais` | 07b, 08b, 09b |
| fait | does / makes / comes to |  | `sitw_fait` | 07a, 09a |
| fromage | cheese |  | `sitw_fromage` | 07a, 07b |
| gare | station |  | `sitw_gare` | 08a, 10a, 10b |
| gauche | left |  | `sitw_gauche` | 08a, 10a, 10b |
| gentil | kind |  | `sitw_gentil` | 07a, 07b, 08a, 08b, 09b, 10a |
| gentille | kind (feminine) |  | `sitw_gentille` | 07a, 07b, 08a, 08b, 09b, 10a |
| gentilles | kind (feminine plural) |  | `sitw_gentilles` | 08b, 10a |
| gentils | kind (plural) |  | `sitw_gentils` | 07a, 07b, 08a, 08b, 09b |
| heure | hour / o'clock |  | `sitw_heure` | 07b, 09b, 10a |
| heures | o'clock / hours |  | `sitw_heures` | 07b, 09a, 09b |
| huit | eight |  | `sitw_huit` | 09a, 10a, 10b |
| ici | here |  | `sitw_ici` | 07a, 08a, 09b |
| idée | idea |  | `sitw_idee` | 08a, 08b |
| il | he / it |  | `sitw_il` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| il reste | there is some left |  | `sitw_il_reste` | 07a, 07b, 08a |
| il y a | there is / there are |  | `sitw_il_y_a` | 07a, 07b, 08b, 10a, 10b |
| ils | they |  | `sitw_ils` | 07b, 08a |
| j'ai | I have |  | `sitw_j_ai` | 07a, 08a, 08b, 09a, 09b, 10a, 10b |
| j'arrive | I'm on my way, I'm coming |  | `sitw_j_arrive` | 09b, 10a, 10b |
| j'en | I … some (of it) |  | `sitw_j_en` | 07b, 09b |
| je | I |  | `sitw_je` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| je n'ai pas | I haven't / I didn't |  | `sitw_je_n_ai_pas` | 08a, 08b, 09a, 10a |
| je peux | I can |  | `sitw_je_peux` | 07b, 08a, 08b |
| je prends | I'll have / I take |  | `sitw_je_prends` | 07a, 07b, 08a, 10a, 10b |
| je voudrais | I would like |  | `sitw_je_voudrais` | 07a, 07b, 08a, 08b, 09a, 09b |
| je vous entends mal | I can't hear you well (vous) |  | `sitw_je_vous_entends_mal` | 09a, 09b, 10a, 10b |
| je vous rappelle | I'll call you back (vous) |  | `sitw_je_vous_rappelle` | 09a, 09b |
| jour | day |  | `sitw_jour` | 08b, 09a, 09b |
| journée | day |  | `sitw_journee` | 07b, 08b, 09a |
| karim | Karim |  | `sitw_karim` | 07b, 09b, 10b |
| l' | the |  | `sitw_l` | 08b, 09b, 10b |
| la | the (feminine) / it, her |  | `sitw_la` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| le | the (masculine) |  | `sitw_le` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| les | the (plural) |  | `sitw_les` | 07a, 07b, 08a, 08b |
| leur | (to) them |  | `sitw_leur` | 09a, 10a, 10b |
| libre | free (not busy) |  | `sitw_libre` | 09a, 09b |
| libres | free (plural) |  | `sitw_libres` | 09a, 09b |
| livre | book |  | `sitw_livre` | 09a, 09b |
| loin | far |  | `sitw_loin` | 10a, 10b |
| lui | (to) him / her |  | `sitw_lui` | 08b, 10a, 10b |
| lundi | Monday |  | `sitw_lundi` | 07b, 08a |
| là | there / here |  | `sitw_la_there` | 07a, 08a, 08b, 09b, 10a, 10b |
| léa | Léa |  | `sitw_lea` | 07a, 07b, 08a, 08b, 10b |
| ma | my (feminine) |  | `sitw_ma` | 08a, 08b, 09a, 09b, 10a |
| madame | madam / Mrs |  | `sitw_madame` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| maintenant | now |  | `sitw_maintenant` | 08a, 10a |
| mais | but |  | `sitw_mais` | 07b, 08a, 09a, 09b |
| marché | market |  | `sitw_marche_market` | 07a, 07b, 10a |
| matin | morning |  | `sitw_matin` | 07a, 07b |
| me | me |  | `sitw_me` | 07b, 08a, 08b, 09a, 09b, 10b |
| merci | thank you |  | `sitw_merci` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| midi | noon |  | `sitw_midi` | 07b, 09a, 09b |
| minutes | minutes |  | `sitw_minutes` | 10a, 10b |
| moi | me |  | `sitw_moi` | 07a, 07b, 08a, 08b, 09a, 09b, 10b |
| mon | my (masculine) |  | `sitw_mon` | 08a, 08b, 09a, 09b, 10a |
| monde | people / world |  | `sitw_monde` | 08a, 09b |
| monsieur | sir / Mr |  | `sitw_monsieur` | 07b, 08a, 08b, 09b, 10a, 10b |
| n'est | is (not) |  | `sitw_n_est` | 08a, 08b, 09a, 09b |
| ne | not (with pas) |  | `sitw_ne` | 07a, 08b, 09b, 10a, 10b |
| non | no / right? |  | `sitw_non` | 07a, 07b, 08a, 08b, 10a, 10b |
| non plus | either / neither (after a negative) |  | `sitw_non_plus` | 07a, 07b |
| noté | noted |  | `sitw_note_past` | 09a, 09b, 10a |
| nouveau | new |  | `sitw_nouveau` | 08a, 10b |
| oh | oh |  | `sitw_oh` | 07a, 08b, 10a |
| on | we / one | yes | `sitw_on` | 07b, 08a, 08b, 09a, 09b, 10b |
| ou | or |  | `sitw_ou` | 07a, 08a, 09a, 09b, 10b |
| ouais | yeah | yes | `sitw_ouais` | 07a, 08a, 09a, 09b, 10a |
| oui | yes |  | `sitw_oui` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| où | where |  | `sitw_ou_where` | 10a, 10b |
| pain | bread |  | `sitw_pain` | 07a, 07b, 09b |
| par | by / per |  | `sitw_par` | 08b, 10b |
| pardon | sorry / excuse me |  | `sitw_pardon` | 07a, 07b, 10a, 10b |
| parfait | perfect |  | `sitw_parfait` | 08a, 09a, 09b |
| parfaite | perfect (feminine) |  | `sitw_parfaite` | 08a, 09a |
| parfaits | perfect (plural) |  | `sitw_parfaits` | 08a, 09a |
| pas | not |  | `sitw_pas` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| pas de problème | no problem |  | `sitw_pas_de_probleme` | 08b, 09a, 10a |
| pas de souci | no worries | yes | `sitw_pas_de_souci` | 07a, 07b, 08b, 09a, 09b, 10a |
| passe | drop by |  | `sitw_passe` | 07a, 07b, 08b |
| passer | to drop by |  | `sitw_passer` | 07b, 08b |
| passes | drop by (tu) |  | `sitw_passes` | 07a, 08b |
| petit | small (masculine) |  | `sitw_petit` | 08a, 08b |
| peu | a little |  | `sitw_peu` | 07a, 09b |
| peut | can |  | `sitw_peut` | 08a, 08b, 09b |
| peux | can (informal) |  | `sitw_peux` | 07b, 08a, 08b, 09a, 09b |
| place | place (à la place = instead) |  | `sitw_place` | 07a, 10a |
| plaît | pleases |  | `sitw_plait` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| plus | more / most / no more |  | `sitw_plus` | 07a, 07b, 08a, 08b |
| plus de | no more |  | `sitw_plus_de` | 07a, 07b, 08b |
| porte | door |  | `sitw_porte` | 08a, 10a, 10b |
| possible | possible |  | `sitw_possible` | 09a, 09b |
| pour | for |  | `sitw_pour` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| pour deux | for two people |  | `sitw_pour_deux` | 07a, 09b |
| pouvez | can (polite) |  | `sitw_pouvez` | 08b, 09b, 10b |
| pouvoir | to be able to |  | `sitw_pouvoir` | 08a, 08b |
| prend | takes |  | `sitw_prend` | 07b, 08a, 10b |
| prendre | to have / to take |  | `sitw_prendre` | 07b, 08a, 10b |
| prends | take |  | `sitw_prends` | 07a, 07b, 08a, 08b, 10a, 10b |
| problème | problem |  | `sitw_probleme` | 08b, 09a, 10a |
| préfère | prefer / prefers |  | `sitw_prefere` | 08a, 09a |
| préfères | prefer (tu) |  | `sitw_preferes` | 08a, 09a |
| quand | when |  | `sitw_quand` | 07b, 08b |
| quatre | four |  | `sitw_quatre` | 07a, 07b, 09a, 09b, 10b |
| que | that / which |  | `sitw_que` | 07b, 08a, 08b |
| quel | which / what |  | `sitw_quel` | 07a, 09a, 09b, 10b |
| quelle | which / what (feminine) |  | `sitw_quelle` | 07b, 08a, 10a, 10b |
| quelque chose | something |  | `sitw_quelque_chose` | 07b, 08a |
| qui | who |  | `sitw_qui` | 07a, 07b, 09a |
| quoi | what (informal) |  | `sitw_quoi` | 10a, 10b |
| rappelle | call back |  | `sitw_rappelle` | 09a, 09b |
| regarde | watch / watches |  | `sitw_regarde` | 08a, 09a, 10a |
| reste | stay(s) / remains |  | `sitw_reste` | 07a, 07b, 08a |
| retard | delay (en retard = late) |  | `sitw_retard` | 09b, 10b |
| robin | Robin |  | `sitw_robin` | 09a, 09b, 10b |
| s'il | if it |  | `sitw_s_il` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| s'il te plaît | please (to a friend) |  | `sitw_s_il_te_plait` | 07a, 07b, 08b, 09b |
| s'il vous plaît | please (vous) |  | `sitw_s_il_vous_plait` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| sa | his / her |  | `sitw_sa` | 08b, 09b |
| salut | hi / bye (informal, tu) |  | `sitw_salut` | 07a, 07b, 09a, 09b, 10b |
| samedi | Saturday |  | `sitw_samedi` | 07b, 08a, 08b, 09a |
| sans | without |  | `sitw_sans` | 08b, 09a |
| se | oneself / each other |  | `sitw_se` | 08a, 09b |
| si | if / yes (to a negative) |  | `sitw_si` | 07a, 08a |
| si vous voulez | if you like (vous) |  | `sitw_si_vous_voulez` | 07a, 08a |
| six | six |  | `sitw_six` | 07a, 09a, 10b |
| soir | evening |  | `sitw_soir` | 07a, 07b, 08b, 09a, 09b |
| sont | are (plural) |  | `sitw_sont` | 07a, 07b, 08a, 08b |
| suis | am |  | `sitw_suis` | 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| super | great |  | `sitw_super` | 07a, 07b, 08a, 08b, 09b, 10a |
| sur | on / about |  | `sitw_sur` | 09a, 10a |
| t'attends | am waiting for you |  | `sitw_t_attends` | 10a, 10b |
| t'es | you are (tu es) | yes | `sitw_t_es` | 07b, 09b, 10a, 10b |
| table | table |  | `sitw_table` | 09a, 09b |
| te | you (informal) |  | `sitw_te` | 07a, 07b, 08a, 08b, 09a, 09b |
| théo | Théo |  | `sitw_theo` | 07b, 08a, 08b, 09b, 10a |
| toi | you (informal) |  | `sitw_toi` | 08a, 09a, 09b, 10a, 10b |
| ton | your (informal) |  | `sitw_ton` | 08a, 08b, 10a |
| top | great | yes | `sitw_top` | 08b, 09a, 09b |
| tout | all / everything |  | `sitw_tout` | 07a, 07b, 08a, 09b, 10a, 10b |
| tout le monde | everyone |  | `sitw_tout_le_monde` | 08a, 09b |
| trois | three |  | `sitw_trois` | 07a, 07b, 10a |
| trop | too / too much |  | `sitw_trop` | 07a, 07b, 08a, 08b, 09a |
| très | very |  | `sitw_tres` | 07a, 07b, 08a, 08b, 09a, 09b |
| très bien | very well / very good |  | `sitw_tres_bien` | 07a, 08a, 09a |
| tu | you (friend) |  | `sitw_tu` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| tu peux | can you (tu) |  | `sitw_tu_peux` | 07b, 08b, 09a, 09b |
| un | a |  | `sitw_un` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| un peu | a little |  | `sitw_un_peu` | 07a, 09b |
| une | a |  | `sitw_une` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| va | goes / is going to / is doing / suits |  | `sitw_va` | 08a, 08b, 09a, 09b, 10b |
| vais | go / am going |  | `sitw_vais` | 08b, 09b, 10b |
| vers | around (a time) |  | `sitw_vers` | 07b, 09a |
| veux | want |  | `sitw_veux` | 07a, 07b, 08a, 08b |
| viens | come (je / tu) |  | `sitw_viens` | 08a, 10b |
| vingt | twenty |  | `sitw_vingt` | 09a, 09b |
| vite | quick / quickly |  | `sitw_vite` | 08a, 08b, 10b |
| voilà | here is / here you are / there you go |  | `sitw_voila` | 07a, 07b, 08a, 08b, 09b |
| vois | see (je, tu) |  | `sitw_vois` | 07a, 10a |
| votre | your (polite) |  | `sitw_votre` | 08a, 08b, 09a, 09b, 10a, 10b |
| voudrais | would like |  | `sitw_voudrais` | 07a, 07b, 08a, 08b, 09a, 09b |
| voulez | want (polite) |  | `sitw_voulez` | 07a, 07b, 08a, 08b, 09a, 09b |
| vous | you (polite) |  | `sitw_vous` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| vous pouvez | can you (polite) |  | `sitw_vous_pouvez` | 08b, 09b, 10b |
| vous pouvez répéter | could you repeat? |  | `sitw_vous_pouvez_repeter` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| vu | seen |  | `sitw_vu` | 07a, 08a |
| y | there |  | `sitw_y` | 07a, 07b, 08b, 10a, 10b |
| à | to / at |  | `sitw_a_prep` | 07a, 07b, 08a, 08b, 09a, 09b, 10a, 10b |
| à côté | nearby / next door / next to |  | `sitw_a_cote` | 08a, 09a, 10a, 10b |
| ça | that / it |  | `sitw_ca` | 07a, 08a, 09a, 09b |
| ça me va | that suits me |  | `sitw_ca_me_va` | 09a, 09b |
| ça te va | does that suit you? (tu) |  | `sitw_ca_te_va` | 08a, 09a |
| ça va | how are you? / I'm fine |  | `sitw_ca_va` | 09a, 09b |
| ça vous va | does that suit you? (vous) |  | `sitw_ca_vous_va` | 08a, 09a |
| êtes | are (vous) |  | `sitw_etes` | 07b, 08a, 08b, 10a |

### 8.2 New base entries this batch needs (not in `words.json` yet)

These are *Fondations* words (or a name, or a fixed phrase around one) that the sketches use and `words.json` does not have yet. All have `firstSeen: null` and `spoken: false`. Use exactly these values in every half that needs them; the coordinator's conflict scan should then find nothing for them.

| fr | en | audio | Needed in |
|---|---|---|---|
| à droite | on the right, to the right | `sitw_a_droite` | 07–10 (directions, shop layout) |
| à gauche | on the left, to the left | `sitw_a_gauche` | 08, 10 (01 already prints it; gloss now via the phrase) |
| droite | right (side) | `sitw_droite` | 10 |
| tout droit | straight on | `sitw_tout_droit` | 10 |
| tournez | turn (vous) | `sitw_tournez` | 10 |
| prenez | take (vous) | `sitw_prenez` | 07, 10 |
| continuez | carry on, keep going (vous) | `sitw_continuez` | 10 |
| rue | street | `sitw_rue` | 07–10 |
| étage | floor, storey | `sitw_etage` | 10 |
| pasteur | Pasteur (street name) | `sitw_pasteur` | 10 |
| bellecour | Bellecour (square, metro stop) | `sitw_bellecour` | 10 |
| ligne a | line A (metro) | `sitw_ligne_a` | 10 |
| ligne b | line B (metro) | `sitw_ligne_b` | 10 |
| c'est tout | that's all / is that all? | `sitw_c_est_tout` | 07 (01 already prints « Ferrand, c'est tout ! ») |
| kilo | kilo | `sitw_kilo` | 07 |
| pommes | apples | `sitw_pommes` | 07, 08 |
| œufs | eggs | `sitw_ufs` | 07 |
| eau | water | `sitw_eau` | 09 |
| viande | meat | `sitw_viande` | 09 |
| plat | dish | `sitw_plat` | 09 |
| menu | menu | `sitw_menu` | 09 |
| restaurant | restaurant | `sitw_restaurant` | 09, 10 |
| réserver | to book, reserve | `sitw_reserver` | 09 |
| déjeuner | lunch | `sitw_dejeuner` | 09 |
| cher | expensive, dear | `sitw_cher` | 07, 08 |
| chère | expensive (feminine) | `sitw_chere` | 07 |
| aux | to the / at the / with (à + les) | `sitw_aux` | 07 |
| fond | back, bottom (au fond = at the back) | `sitw_fond` | 08 |
| noir | black | `sitw_noir` | 08 |
| noire | black (feminine) | `sitw_noire` | 08 |
| blanche | white (feminine) | `sitw_blanche` | 10 |
| robe | dress | `sitw_robe` | 08 |
| ciel | sky | `sitw_ciel` | 08 |
| match | match, game | `sitw_match` | 08 |
| bons | good (plural) | `sitw_bons` | 07 |
| meilleur | better, best | `sitw_meilleur` | 09 |
| meilleure | better, best (feminine) | `sitw_meilleure` | 09 |
| son | his / her / its | `sitw_son` | 08 |
| ferme | closes, shuts | `sitw_ferme` | 07 |
| faut | (il faut) you have to, you need | `sitw_faut` | 08 |
| attend | waits, is waiting | `sitw_attend` | 09 |
| explique | explain(s) | `sitw_explique` | 10 |
| ouvrir | to open | `sitw_ouvrir` | 10 |
| parler | to speak, talk | `sitw_parler` | 08 |
| pourriez | could (vous) | `sitw_pourriez` | 08 |
| prochaine | next (feminine) | `sitw_prochaine` | 08 |
| serai | will be (je) | `sitw_serai` | 07 |
| seras | will be (tu) | `sitw_seras` | 07 |
| été | been | `sitw_ete` | 08 |
| écrit | written / writes | `sitw_ecrit` | 07 |
| habitons | live (nous) | `sitw_habitons` | 10 |
| sonné | rang | `sitw_sonne` | 10 |
| voiture | car | `sitw_voiture` | 10 |
| téléphone | phone | `sitw_telephone` | 09 |
| personne | person / nobody | `sitw_personne` | 09 (distractor) |
| litre | litre | `sitw_litre` | 07 (distractor) |
| magasin | shop | `sitw_magasin` | 08 |

Notes: adding the phrase *à gauche* changes 01 `flat`'s tooltip from "left" to "on the left, to the left", which is still right there. *ligne a / ligne b* exist only so the token *A* is not glossed "has"; drop them if you avoid letter lines (open question 5). *Pasteur* and *Bellecour* are names, glossed like *Eugene*.

### 8.3 Inflections

Each matrix ends with the inflections and distractor forms its sketches use (*traditions, bleue, abîmée, remboursée, perdue, trompé, réservée…*). Gloss them from their base, adding the form in brackets the way `words.json` already does (*désolée* = "sorry (feminine)", *libres* = "free (plural)"): for example *bleue* = "blue (feminine)", *remboursée* = "refunded (feminine)", *trompé* = "got it wrong (said by a man)". When two halves need the same inflection, the half that owns the base word writes it and the other copies it.

## 9. How each matrix blocks the judges' recurring errors

The next-session handoff §4 lists the classes judges keep finding; the planner spec adds four more. What the plan does about each, with the module-specific risks:

| Error class | Whole batch | 07 | 08 | 09 | 10 |
|---|---|---|---|---|---|
| **Hidden valid replies** (mostly a reply without « Pardon ? » or with clauses swapped) | Every *Clarify* row asks the author to accept the reply with and without « Pardon, ». Two-clause replies (« Oui, au nom de Robin, pour quatre. ») need both orders in `accepted` or a bank that fixes the order. Fill distractors were chosen so that only one is valid French in context. | *pas ___ cuite*: (trop / beaucoup / tout), not *très*; *ce ___ tout*: (sera / serai / seras), not *est*; *Non, je voudrais ___ des œufs*: (aussi / non plus / trop), not *encore*. | *Je ___ par carte*: (paie / paies / payer), so the equally right *paye* is not offered; *gentille* against *gentil* only where *c'est* or the speaker's sex settles it. | *merci ___*: (beaucoup / très / trop), not *bien*; *mieux / meilleur*; *vers / devant / sur* before a time, not *à*. | *ouverte ___ quelle heure*: (jusqu'à / jusqu'au / jusque), not *depuis*; *c'est à ___ du café*: (côté / côte / coté). |
| **Standalone place labels** set to the home place instead of the cue's setting | Every standalone row carries its own place (§2.4). | `bread s02` Texto · Léa; `bread s04` Sur le palier; `taste s04` À l'appart. | `fitting s02` Au bureau; `fitting s04` WhatsApp · Mme Dumas; `gift s04` Les copains. | `slot s04` WhatsApp · Mme Dumas; `voicemail s02/s04` Messagerie · Mme Dumas; `change s02/s05` Les copains. | `door s05` Texto · Léa; `straight s02` Sur le palier. |
| **Cue leaks and answer echo** | The validator rejected any Fill whose correct choice is printed in another line of the item; 11 sketches were changed (e.g. 07 `bread d07` dropped *aussi* from the server line, 08 `colour d09` *La chemise* → *Cette chemise*, 09 `name d06` « au nom de qui » → « à quel nom »). Quoted French is never cue text, and the cue must not state the fact a Comprendre asks. | Prices: the cue never gives the price the seller says. | Sizes and colours: the cue never names the size or colour the seller offers. | Days and times: the cue never gives the slot the restaurant offers. | Directions: the cue gives only Robin's own fixed facts (§2.1), never the route the other speaker gives. |
| **A speaker answering their own question** | Where a question must be followed by its answer, the learner's question is a printed learner line and the other speaker answers (07 `price d01`, `d04`; 09 `change d01`; 10 `ask d01`). No server line asks and answers itself. | Seller's « Ce sera tout ? » is always answered by Robin. | | | |
| **« Repeat » asked of a text** | *Clarify* rows are face to face or live calls only; the validator rejected any *Clarify* on Texto, Les copains, WhatsApp or Messagerie. | `errand d05` is a call (Appel · Léa), not a text. | | `voicemail d05` is a live call to the restaurant, never the voicemail itself. | `address/lost/turn/door d05` are live calls with a bad line. |
| **Glosses wrong in context** | §2.9 lists the traps; §2.11 widens the new glosses; §8 fixes every shared gloss. | *tradition* gloss widened; *lit* stays a distractor only. | *ça te va bien / ça vous va bien* as new keys, apart from 05's *ça te va ?*; *je regarde juste* apart from *je regarde* (watch). | *merci de* only before an infinitive. | *ligne A*; *je descends* gloss covers "get off". |
| **Phrase key across a comma** | §2.10. | *c'est tout* (base) never split by a comma. | *ça vous va bien* never as « ça vous va, bien… ». | *merci de* never as « Merci, de… ». | *au coin*, *en bas* never split. |
| **Follow-ups that ignore the learner** | A Répondre follow-up must fit every accepted reply. Rows where Robin may say yes or no (07 `bread d01`, 08 `browse d04`, 09 `slot d01`) need a neutral follow-up or a bank that only allows one answer. | `anything d01` / `d10`: the follow-up must fit both « c'est tout » and an extra item. | `browse d10`: fits « just looking » and « a black jumper ». | `book d01`: party size stated in the cue. | `lost d01`: fits any "I'm at home" reply. |
| **False errors** | Corriger never targets an accepted spoken form or a common variant. | *cuit → cuite*, *des → de* after a quantity, *mûrs → mûres*, *fermé → fermée*, *occupes → occupe*. | *une pull*, *bleu → bleue*, *sa anniversaire*, *payé → payer*, *abîmé → abîmée*, *remboursé → remboursée* (Robin). « En carte » is never an error. | *personne → personnes*, *complète → complet*, *à le → au*, *mon réservation*, *modifié → modifier*, *réservée → réservé* (avoir). | *étages*, *perdue → perdu* (the driver), *droit / droite* both ways, *descende*, *trompé → trompée* (Robin), *à le → au*. |
| **Logic puzzles** | No gap depends on reasoning about who owns what or on arithmetic; prices are printed when needed (07 `price d09`). | Quantities are stated, never computed. | | Days: the cue states Robin's own availability. | Routes are given step by step in French; Robin never infers a route. |
| **Untaught words used early** | Every quoted token and choice was checked in book order against *Fondations*, `words.json` and this batch (§0). Caught and fixed: *abricots* in 07 `price` (before `taste`), *réservation* in 09 `voicemail` (before `confirm`), *immeuble* in 08 (taught in 10), the unglossed *appart* and *boutique*, and *trouve* in 09 (taught in 10). | | | | |
| **Masculine forms for Robin** | Learner lines use feminine forms only; masculine forms appear as decoys. Cues say "You're a woman." where the answer hinges on it. | — | `refund s01`, `s03`, `d07` (*remboursée*). | `name d07` and `arrive s03` trap *appelée / réservée* (avoir: no agreement). | `ask d03`, `d06`, `s03`, `d09` (*perdue, trompée*). |

## 10. `modules.json` entries (ready to paste)

Add these before the first assemble; the author agents don't.

```json
{"id": "sit_07", "title": "Boulangerie et marché", "arc": "Le quartier", "goal": "Order bread and market food, ask quantities and prices, and say « c'est tout ».", "file": "07_boulangerie_et_marche.json", "moves": ["bread", "pastry", "quantity", "price", "taste", "anything", "hours", "errand"]},
{"id": "sit_08", "title": "En boutique", "arc": "Le quartier", "goal": "Ask for an item, a size or a colour; try it on; pay; exchange or return it.", "file": "08_en_boutique.json", "moves": ["browse", "size", "fitting", "colour", "gift", "checkout", "exchange", "refund"]},
{"id": "sit_09", "title": "Réserver", "arc": "Le quartier", "goal": "Book a table by phone, give your name, leave a message, confirm or change the booking.", "file": "09_reserver.json", "moves": ["book", "slot", "name", "options", "voicemail", "confirm", "change", "arrive"]},
{"id": "sit_10", "title": "Se repérer", "arc": "Le quartier", "goal": "Give your address, guide a lost delivery driver by phone, and ask for and follow directions.", "file": "10_se_reperer.json", "moves": ["address", "lost", "landmark", "turn", "straight", "door", "ask", "transit"]}
```

Drafts: `07_boulangerie_et_marche_{first,second}_half{,_words}.json`, `08_en_boutique_…`, `09_reserver_…`, `10_se_reperer_…`.

## 11. Batch procedure (unchanged from the next-session handoff §4)

1. Ask the user whether review set v5 is approved; memory says authoring waits for it.
2. The coordinator adds the four `modules.json` entries (§10).
3. Two author agents per module. Give each this file (§1–2, §8, §9), its matrix and `agents/author.md`.
4. Gloss conflict scan over all drafts and `words.json` (§8 should leave few), then `assemble.py 07 08 09 10`, lint, tests, `deep_lint.py`, the Swift model test.
5. Four judges per module (two moves each), with §1–2 and §9 of this file.
6. Fixes, then the *Fondations* audit of every new `firstSeen: null` entry.
7. One 9-card review set per module, D D S order. Suggested: 07 `bread d01, price d01, hours s02, anything d01, errand d02, taste s03, quantity d03, hours d03, bread s05`; 10 `lost d01, lost d02, address s02, door d03, turn d04, ask s03, landmark d07, transit d02, straight s05`.

## 12. Open questions for the user

1. **Robin's street.** OK to fix « huit, rue Pasteur », third floor, door code « deux, cinq, huit », a blue front door, next to the bakery and opposite the corner pharmacy? (Rue Pasteur is a real street in Lyon 7e; any street works.)
2. ***C'est tout*** as a glossed base phrase rather than a taught word, because 01 already prints « Ferrand, c'est tout ! »? The taught shop phrases are *et avec ceci ?* and *ce sera tout*.
3. **No new spoken form in arc 2.** *Y a* can't be taught without a lint change (it matches inside « il y a » in 01). Accept zero new spoken forms here, or change `lint.py` so the key "y a" doesn't match after *il* / *n'*, and add *y a* to 07 `errand`?
4. **Fondations overlap.** The directions (*tournez à droite, tout droit, prenez la première rue*), *réserver une table*, *combien ça coûte*, *cher*, *kilo*, *étage* stay base because Book 1 teaches them in the same sense. *Perdu* is taught although Book 1 has *j'ai perdu* once. Fine?
5. **Lyon metro letters.** Keep « la ligne A / la ligne B » with phrase glosses (so *A* isn't glossed "has"), or avoid letters and say *le métro* / *le tram* only?
6. **Staff voices.** 07–09 lean on one-off staff, so many lines use the two Neural2 voices (F, G). Keep them anonymous, or make the baker or the waiter a recurring unnamed voice?
7. **New character facts:** Inès is vegetarian (09 `options`); Mme Dumas paints the front door blue (08 `colour`); M. Ferrand's birthday (08 `gift d10`). OK?
8. ***Bonsoir*** is taught in 09 `arrive` (nothing earlier used it). Fine, or should it have come earlier?
9. **Review set v5** has not been confirmed in full (next-session handoff §3). Is it approved, so this batch can be authored?
