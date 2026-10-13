# Book 2, arc 4 *Raconter*: plan for modules 16–20

**Date:** 2026-10-13
**Status:** paper plan only. No French is authored. Nothing is committed. `modules.json` is unchanged (entries in §10).
**Matrices:** [16](2026-10-13-book-2-arc4-module-16-matrix.md) · [17](2026-10-13-book-2-arc4-module-17-matrix.md) · [18](2026-10-13-book-2-arc4-module-18-matrix.md) · [19](2026-10-13-book-2-arc4-module-19-matrix.md) · [20](2026-10-13-book-2-arc4-module-20-matrix.md)
**Rulebook:** [arc 4 handoff](2026-10-13-book-2-arc4-handoff.md); [next-session handoff](2026-10-13-book-2-next-session-handoff.md) §4 (arc 3 lessons, built in here); [content handoff](2026-10-11-book-2-content-handoff.md) §3–§8; [café handoff](2026-10-11-book-2-cafe-handoff.md) §3; [2026-10-11 handoff](2026-10-11-book-2-next-session-handoff.md) §2; `tools/situations/README.md`. Format copied from the [arc 3 plan](2026-10-12-book-2-arc3-plan.md).

Modules 01–15 are taught content: everything they teach (389 taught words in `words.json`, 1,406 entries in all) is known here, including arc 3's *grève, annulé, retard, raté, oublié, à cause de, longtemps, presque, t'inquiète, annuler, on remet ça, rien de grave, prends soin de toi, j'ai mal, malade, ça va mieux, réparer, cassé, en panne, pareil, encore une fois, la dernière fois*.

Each matrix has one row per item (8 moves × 15 items = 120 per module) in the arc 3 format, a new-word table with the exact `en` / `spoken` / `audio` for every new word, and a glossed table of every inflection and distractor form its sketches use. A validator in the planning scratchpad (not in the repo) checked all 600 rows before the matrices were written: item order and standalone labels; 1–2 drills per dialogue, no repeated type, no Répondre + Choisir; no same drill engine back to back across item boundaries; ≥4 dialogue types and Répondre + Compléter ≥ half per move; one *Clarify* dialogue per move, never on a text, the group chat or WhatsApp; ≥2 dialogues off the home channel; ≤2 new words per item, each printed in a server line or a printed learner line of its first-seen item (never only in a model reply or a gap); each new word in ≥2 later dialogues and a later Mot or Mot en retour inside its own move; Mot targets visible in a quoted line; Mot en retour fill = target; ≤10 words per dialogue line and 8–14 in standalone lines; Robin's masculine self-forms (the lint `MASC_SELF` list plus *couché, tombé, épuisé, trempé, convaincu, sûr*) in every learner line with the gap filled and the Corriger fix applied; no « bref » / « ouais » in any Choisir le ton option; every quoted token and every choice segmented with the lint's own longest-phrase-first matcher against `words.json`, this batch's keys and the inflection tables (0 unglossed tokens); book order inside the batch (0 keys used before their item); answer echo in every Fill row; every new key against the exposure lines of all 1,800 items in 01–15 (0 hits); audio-key collisions across `words.json`, the new keys and the inflection tables (0 left, with the `_past` / `_verb` suffixes in §2.7).

## 1. Fixed decisions this plan builds on

- **Robin** is a woman from Eugene, Oregon. Her lines are feminine only. This arc is past-tense heavy, so it leans on it constantly: *je suis allée, sortie, rentrée, restée, tombée* (14), *je me suis couchée* (15), *épuisée* (16), *trempée* (17), *convaincue* (18), *sûre* (20). A cue says "You're a woman." wherever an answer hinges on it; masculine forms appear only as decoys and in Corriger error lines (lint `MASC_SELF` checks the corrected line, so a masculine error word is allowed there).
- **Passé composé with *avoir* never agrees with Robin** (*j'ai rencontré, j'ai pris, j'ai voté*): Corriger targets *rencontrée* (16 `met s03`).
- **Karim** says *tu* everywhere (after café `usual`). **M. Ferrand** and **Mme Dumas**: *vous* always. **Léa, Inès, Théo**: *tu*. In the group chat *vous* is plural; the cue says « vous = you all ».
- **Unnamed speakers carry a `role`.** This arc uses « Serveur / Serveuse » (16's bouchon, 19's restaurant), « Vendeuse » (phone shop), « Vendeur » (bike shop), « Responsable » (Robin's manager, female) and one new role, « Agent immobilier » (male, 18 and 20; open question 1).
- **Home label « À l'appart »** (book-wide). Lines never print *appart*; 18 teaches *appartement* for flats in general.
- **Module 10's map is canon** (huit, rue Pasteur, third floor, the bakery, the pharmacy opposite, Karim's café on the corner). Nothing here contradicts it; 20 `formal` recommends « la boulangerie en face ».
- **Underlines** mean "new here" only. A word taught in 01–15 is never put back in `newWords`.
- **No untaught phrase keys and no phrase key across a comma** (§2.9).
- **Comprendre `correct` indices:** the sketches leave the Comprendre question to the author. Authors and fixers check every `correct` against the true choice (arc 3 shipped 15 inverted keys that lint cannot see).
- **Choisir le ton:** every option is natural French. The wrong options are good French in the wrong register (*tu* to Mme Dumas, *Salut !* to the estate agent, a blunt imperative), never a stray « bref » or « ouais » (the validator rejects both in every option).
- Per move: 10 dialogues + 5 standalones (Construire, Choisir le ton, Corriger, Transformer, Mot en retour).

## 2. Conventions new in this arc

1. **Same drill template in every move** (as arcs 2–3): d01 U R · d02 U C · d03 C U · d04 M R · d05 R M (*Clarify*) · d06 C U · d07 M C · d08 R U · d09 U C · d10 U R. That gives 4 types and Répondre + Compléter = 10 of 20 in each move, and no engine repeats across a boundary. Mot targets: the d01 word at d04, the d02 word at d05, the d03 word at d07; a fourth word gets s05 (16 `met`, 17 `story`, 18 `bike`, 19 `vote`, 20 `reason`).
2. **Places** (plain text, never glossed): `À l'appart`, `Au bureau`, `Au café`, `Sur le palier`, `Dans la rue`, `En boutique`, `Au restaurant` (new: the bouchon in 16 and 19 `share`), `À l'agence` (new: the estate agency, 18 and 20), `Texto · <name>`, `Les copains · groupe`, `WhatsApp · Mme Dumas`, `Appel · <name>`, `Appel · restaurant`, `Appel · agence` (new). Standalone labels add « · phrase seule » and match the cue's setting, not the move's home place.
3. **Two speakers in one group-chat dialogue** (17 `sympathise d01`: Théo writes, Inès answers « Oh, mon pauvre ! », then Robin replies). Both are named, so the follow-up needs `followUpBy`.
4. **Numbers stay small words:** *deux, trois, cinq, six, sept, huit, dix, vingt, midi, minuit* (new in 16). Rents are never given in figures (*moins cher que*, *charges comprises*); plans and shares use *dix / vingt euros par mois*, *cinq euros par personne*.
5. **Feminine keys for Robin:** *sortie* (16), *couchée*, *épuisée* (16), *convaincue* (18), *sûre* (20) are keyed in the feminine because Robin's lines need that form; the masculine is an inflection or base entry (*sorti, couché, convaincu, sûr*). *Tombé* (17) and *trempé* (17) are keyed masculine because Théo tells the disaster story; *tombée* (a *Fondations* form) and *trempée* are Robin's inflections.
6. **Elided and contracted forms are separate keys** (lint splits on spaces, and a phrase key does not match a contracted form):
   - *l'addition* is keyed with its article (it is always *l'addition*);
   - *appartement*, *avantage*, *inconvénient*, *expo* appear as *un / cet appartement*, *un avantage*, *une expo*: *l'appartement*, *l'expo* are inflection entries and do not count as recurrences;
   - *un coup de main*, never *d'un coup de main*; *au bord de* only before *la Saône* / *l'eau*, never *au bord du*; *près* is keyed alone so *près du / près de la* both show it;
   - *bouchon lyonnais* only as the full phrase: a bare *bouchons* shows 13's "traffic jams".
7. **Audio keys for verb / past-participle pairs** (arc 3 lesson). Every past participle whose bare slug equals its verb form gets `_past`; a verb form that meets a taken slug gets `_verb`. Planned: *croisé* `sitw_croise_past`, *rencontré* `sitw_rencontre_past`, *tombé* `sitw_tombe_past` / *tombe* `sitw_tombe_verb`, *trempé* `sitw_trempe_past`, *couché* `sitw_couche_past` / *couche* `sitw_couche_verb`, *mangé* `sitw_mange_past`, *rentré* `sitw_rentre_past`, *resté* `sitw_reste_past`, *acheté* `sitw_achete_past`, *visité* `sitw_visite_past` (*visite*, the noun, keeps `sitw_visite`), *changé* `sitw_change_past`, *décidé* `sitw_decide_past`, *préféré* `sitw_prefere_past`, *regretté* `sitw_regrette_past`, *voté* `sitw_vote_past` / *vote* `sitw_vote_verb`, *rembourses* `sitw_rembourses_verb` (*remboursés* owns `sitw_rembourses`), *sûr* `sitw_sur_sure` (*sur* owns `sitw_sur`). Authors who need a form not in the tables check `words.json` and the matrices for the slug before writing it.
8. **Gloss traps in existing entries** (judge class "glosses wrong in context"). Authors must not write: *ça fait* except for a total (*ça fait vingt euros*), so never *ça fait longtemps*; *plus de* / *moins de* + noun (*plus de* is glossed "no more", so 18 compares adjectives only); *pas plus* ("no more than that"); *pas mal de* ("not bad"); *je te dis* except "I'll let you know"; *crevé(e)* for "exhausted" (15's flat tyre: 16 teaches *épuisée*); bare *bouchon(s)* for a restaurant; *annonce* for a flat listing (11's station announcement); *billets* for concert or cinema tickets (glossed "(train)"); *seul* for "the only" (glossed "alone"); *je n'arrive pas à…* (*arrive* = "is coming"); *ça va* + infinitive (« ça va te changer les idées » shows 01's *ça va*: write *pour te changer les idées*; only the keys *ça va aller* and *ça va s'arranger* are safe); *s'il fait beau* (*fait* would not match *il fait beau*); bare *ligne* outside *en ligne*; *passe* only for "drop by" (« le plombier passe »); *court*, *cours*, *t'attends*, *quai* as in arc 3.
9. **Phrase keys across a comma.** Never split *boire un verre, bouchon lyonnais, par hasard, rien de spécial, pas grand-chose, ça s'est bien passé, qu'est-ce qui s'est passé, tout à coup, oh là là, sans blague, mon pauvre, au moins, pas terrible, ça va aller, ça va s'arranger, bon courage, un coup de main, changer les idées, je t'invite, par mois, charges comprises, rapport qualité-prix, ça vaut le coup, en promo, par contre, ça dépend, ça vous dit, on pourrait, au bord de, je préférerais, ça m'est égal, comme vous voulez, tant pis, c'est décidé, je m'en charge, en ligne, en tout, par personne, qu'est-ce que tu en penses, je te conseille, je te recommande, sans hésiter, n'hésite pas, comme ça, fais attention, le pour et le contre, d'un côté, je vous recommande, à votre place, tu as eu raison* with a comma. *D'un côté, … ; de l'autre, …* keeps the comma after *côté*, not inside the key.
10. **Keys that must not appear before their module or move** (the validator found none, keep it so when rewriting): *en plus* before 17 `galere` (so 16 never says « et en plus »); *pire* before 17 `askback` (its decoy use in 18–20 is fine); *qu'est-ce qui s'est passé* before 17 `what`; *ça vaut le coup* before 18 `better`; *par contre* before 18 `pros`; *sinon* before 19 `propose`; *à votre place* and *je vous recommande* before 20 `formal` (20 `should s02` uses *vous devriez* for that reason); *sûre* before 20 `inplace`. *À ta place* and *si j'étais toi* are *Fondations* sentences (22, 25) and stay base.
11. **Drafts:** `NN_<slug>_first_half.json` / `_second_half.json`, each with its `_words.json`: `16_raconter_sa_soiree_…`, `17_une_galere_…`, `18_comparer_…`, `19_choisir_ensemble_…`, `20_conseiller_…`.

## 3. Move lists

Moves 1–4 go to author agent 1 (first half) and moves 5–8 to author agent 2 (second half). Each new word belongs to the half where it first appears, and its recurrences and Mot drill stay inside its own move, so the halves never depend on each other's drafts. A second-half item that reuses a first-half word copies its entry from the matrix's word table.

### 16 *Raconter sa soirée*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_16_evening` | Alors, ta soirée ? | 1st | 3 (raconte, concert, boire un verre) | The syllabus scene: the morning after, Léa asks *Alors, ta soirée ? Raconte !* Robin went *boire un verre* and then to *un concert* with Inès. Passé composé with *être* (Robin: *je suis allée*) and *c'était* (16) come in at once. |
| `sit_16_order` | D'abord, ensuite | 1st | 3 (d'abord, ensuite, puis) | Sequencing: *d'abord*, *ensuite*, *puis*. Monday at the office, Inès and Robin tell each other their Saturday step by step. Passé composé with *avoir* and *être* side by side (*j'ai fait*, *je suis allée*). |
| `sit_16_out` | Je suis sortie | 1st | 3 (sortie, en boîte, bar) | Going out: *je suis sortie* (Robin's feminine agreement with *être*: Corriger targets *sorti*), *en boîte* (to a club; apart from 12's *boîte aux lettres*), *un bar*. *En ville* is a *Fondations* phrase and stays base. Léa texts late at night; Théo and Inès make plans. |
| `sit_16_dinner` | Au bouchon lyonnais | 1st | 3 (bouchon lyonnais, dessert, l'addition) | Culture move: dinner in *un bouchon lyonnais* (Lyon's traditional bistro), *un dessert* (the pink *tarte aux pralines*) and *l'addition*. Robin tells Léa about it, and two scenes happen at the table. Only the phrase *bouchon lyonnais* is keyed: bare *bouchons* is 13's "traffic jams". |
| `sit_16_met` | Des rencontres | 2nd | 4 (croisé, ancien, par hasard, rencontré) | Who you saw: *j'ai croisé* (bumped into), *par hasard*, *j'ai rencontré* (met), *un ancien collègue*. Passé composé with *avoir*: no agreement with Robin (Corriger targets *rencontrée*). |
| `sit_16_late` | Rentrer tard | 2nd | 3 (minuit, couchée, épuisée) | Coming home late: *à minuit*, *le dernier métro*, *je me suis couchée* (pronominal passé composé with Robin's feminine agreement, *Fondations* 15) and *épuisée*. Corriger targets *couché*. |
| `sit_16_mood` | C'était comment ? | 2nd | 3 (ambiance, plein de, ennuyeux) | Describing in the imparfait (*Fondations* 16): *c'était*, *il y avait plein de monde*, *une bonne ambiance*, *ennuyeux*. Passé composé for events, imparfait for how it was. Agreement *ennuyeux / ennuyeuse* (Corriger). |
| `sit_16_askback` | Et toi ? | 2nd | 3 (rien de spécial, pas grand-chose, ça s'est bien passé) | The social move: ask back. *Et toi, ça s'est bien passé ?*, and the modest answers *rien de spécial* and *pas grand-chose*. Robin's *je suis restée* (Corriger) and *vous* vs *tu* when asking back. |

### 17 *Une galère*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_17_galere` | Quelle galère ! | 1st | 3 (galère, horrible, en plus) | The syllabus word: *galère* (an everyday hassle, a nightmare day) and *Quelle galère !*. Théo, Inès and Léa have *une journée horrible*, *et en plus…*. Robin reacts. Agreement *quelle* (Corriger on *quel galère*). |
| `sit_17_what` | Qu'est-ce qui s'est passé ? | 1st | 3 (qu'est-ce qui s'est passé, tout à coup, tombé) | Asking for the story: *Qu'est-ce qui s'est passé ?* (a new phrase key, apart from 14's *qu'est-ce qui ne va pas*), *tout à coup*, *il est tombé*. Théo tells it at the café; Robin's own fall needs *tombée* (Corriger). |
| `sit_17_react` | Réagir | 1st | 3 (mince, oh là là, sans blague) | Short spoken reactions: *Mince !* (darn, polite), *Oh là là !* and *Sans blague ?* (no kidding?). No slang. With *vous* people (Mme Dumas, M. Ferrand) the reaction comes with *je suis désolée* and a practical question. |
| `sit_17_sympathise` | Compatir | 1st | 3 (mon pauvre, dur, énervant) | Sympathising: *Oh, mon pauvre !* (to a man; *ma pauvre* to a woman), *c'est dur*, *c'est énervant*. Agreement *dur / dure* (Corriger on *ta semaine était dur*) and the switch *mon pauvre → ma pauvre* (Transformer). With *vous*: *je suis désolée*, never *mon pauvre*. |
| `sit_17_story` | Les détails | 2nd | 4 (trempé, parapluie, portable, batterie) | The details of a bad day: rain and no umbrella (*trempé*, *parapluie*), *mon portable n'a plus de batterie*. Imparfait for the background (*il pleuvait*, *je n'avais pas de parapluie*, 16) and passé composé for what happened. Robin is *trempée* (Corriger). |
| `sit_17_askback` | Et ta journée ? | 2nd | 3 (pire, au moins, pas terrible) | Asking back after a story, and comparing days: *c'était pire* (worse; *Fondations* 19 has *plus / moins / meilleur*, *pire* is new), *au moins* (at least), *pas terrible* (not great). Inès at the office is the home scene. |
| `sit_17_cheer` | Remonter le moral | 2nd | 3 (ça va aller, ça va s'arranger, bon courage) | Cheering someone up: *ça va aller* (it'll be OK), *ça va s'arranger* (it'll sort itself out: futur proche of a pronominal verb, 12 and 15), *bon courage*. Both are new keys longer than 01's *ça va*, so the gloss is right. With *vous*: *ne vous inquiétez pas* (20). |
| `sit_17_help` | Proposer son aide | 2nd | 3 (un coup de main, changer les idées, je t'invite) | The social move after sympathy: offer help or a treat. *Je te donne un coup de main* (keep the article: *d'un coup de main* would not match the key), *pour te changer les idées* (never *ça va te changer…*, which would show 01's *ça va*), *je t'invite* (my treat). |

### 18 *Comparer*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_18_flats` | Deux appartements | 1st | 3 (appartement, lumineux, balcon) | Inès is flat-hunting and sends Robin two flats: *un appartement*, *lumineux*, *un balcon*. Comparatives *plus / moins … que* (*Fondations* 19). Lines say *cet appartement* or *un appartement*: *l'appartement* would not show the key. |
| `sit_18_rent` | Le loyer | 1st | 3 (loyer, par mois, charges comprises) | Money talk with the estate agent (*vous*): *le loyer*, *par mois*, *charges comprises* (bills included: a French listing habit). *Moins cher que*; no figures beyond the taught small numbers. |
| `sit_18_area` | Le quartier | 1st | 3 (bruyant, près, centre-ville) | Comparing neighbourhoods on foot with Inès: *bruyant*, *près du métro*, *le centre-ville* against Robin's *quartier calme* (03). *Près* is keyed alone so *près du / près de la* both show it. |
| `sit_18_plan` | Le forfait | 1st | 3 (forfait, illimité, réseau) | Choosing a phone plan in the shop: *un forfait*, *illimité*, *le réseau*. *Meilleur* (adjective) against *mieux* (adverb, *Fondations* 19; Corriger on *meilleure*), and the superlative *le moins cher*. |
| `sit_18_bike` | Les vélos | 2nd | 4 (électrique, d'occasion, léger, lourd) | Robin wants a new bike (hers had a flat tyre in 15): *un vélo électrique* or *d'occasion*, *léger* or *lourd*. *Plus / moins … que* with adjectives and Corriger on the article (*une vélo*). |
| `sit_18_better` | Le meilleur choix | 2nd | 3 (rapport qualité-prix, ça vaut le coup, en promo) | Value judgements: *un bon rapport qualité-prix* and the superlative *le meilleur rapport qualité-prix* (19), *ça vaut le coup* (it's worth it), *en promo* (on offer). Corriger on *meilleure*. |
| `sit_18_pros` | Avantages et inconvénients | 2nd | 3 (avantage, inconvénient, par contre) | Weighing it up: *un avantage*, *un inconvénient*, *par contre* (on the other hand). Keyed with the article *un*: *l'avantage* would not show the key. Inès and Robin at the office, the agent (*vous*) for the formal version. |
| `sit_18_decide` | Se décider | 2nd | 3 (j'hésite, ça dépend, convaincue) | Making up your mind: *j'hésite entre…*, *ça dépend du prix*, and Robin's *je ne suis pas convaincue* (feminine: Corriger targets *convaincu*). Comparatives come back as reasons. |

### 19 *Choisir ensemble*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_19_propose` | Proposer | 1st | 3 (ça vous dit, on pourrait, sinon) | The group chat plans the weekend: *ça vous dit ?* (plural *vous*, after 04's *ça te dit*), *on pourrait…* (conditional, *Fondations* 22) and *sinon* (otherwise). Corriger on *on pourrais*. |
| `sit_19_options` | Les options | 1st | 3 (pique-nique, au bord de, expo) | Laying out the options: *un pique-nique au bord de la Saône* (Lyon's river, a culture move) or *une expo* (everyday short form of *exposition*). Keyed *au bord de* matches only *au bord de la / de l'eau*, so the sketches never write *au bord du*. |
| `sit_19_prefer` | Dire sa préférence | 1st | 3 (je préférerais, ça m'est égal, comme vous voulez) | Saying what you'd rather do, softly: *je préférerais* (conditional of *préférer*, *Fondations* 22), *ça m'est égal* (I don't mind) and *comme vous voulez* (to the group; *comme tu veux* to one friend). Corriger on *je préférerait*. |
| `sit_19_vote` | Voter | 1st | 4 (sondage, voter, majorité, égalité) | Théo runs a poll: *un sondage*, *il faut voter*, *la majorité*, and the tie *égalité !*. Passé composé *j'ai voté*, *la majorité a préféré* (Transformer) and Corriger *il faut voté → voter*. |
| `sit_19_compromise` | Trouver un compromis | 2nd | 3 (compromis, chacun, tant pis) | When the group disagrees: *un compromis*, *chacun choisit* (each one picks), and *tant pis* (never mind, too bad) when a plan falls through. Agreement with *chacun* (singular verb: Corriger on *chacun choisissent*). |
| `sit_19_confirm` | Confirmer | 2nd | 3 (c'est décidé, lieu, rappel) | Closing the deal: *c'est décidé !*, *le lieu* (the place, beside *l'heure*), and *petit rappel* (a quick reminder) the day before. *Confirmer* (09) comes back with the restaurant (*vous*). |
| `sit_19_book` | Réserver pour le groupe | 2nd | 3 (je m'en charge, lien, en ligne) | Someone has to book: *je m'en charge* (I'll handle it; close to 07's *je m'en occupe*), *le lien* (the link) and *réserver en ligne* (*en ligne* is a new phrase key, so *ligne* no longer shows 10's metro gloss there). The restaurant is a call (*vous*). |
| `sit_19_share` | Partager les frais | 2nd | 3 (partager, en tout, par personne) | Splitting the costs: *partager l'addition*, *vingt euros en tout* (*ça fait* = the total comes to, its own gloss) and *cinq euros par personne*. *Rembourser* (08) comes back: *je te rembourse*. |

### 20 *Conseiller*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_20_ask` | Demander conseil | 1st | 3 (conseil, qu'est-ce que tu en penses, choix) | The syllabus scene: Inès can't choose between two flats (18) and asks Robin: *un conseil*, *qu'est-ce que tu en penses ?* (with *en*, *Fondations* 18), *j'ai le choix entre…*. |
| `sit_20_should` | Tu devrais | 1st | 3 (je te conseille, je te recommande, franchement) | Recommending: *tu devrais* (conditional of *devoir*, a *Fondations* 22 example), *je te conseille* (the *tu* form of 14's *je vous conseille*), *je te recommande*, and the frank *franchement*. Transformer softens *tu dois* into *tu devrais*. |
| `sit_20_inplace` | À ta place | 1st | 3 (sans hésiter, n'hésite pas, sûre) | Putting yourself in their shoes: *à ta place, je prendrais…* and *si j'étais toi…* are *Fondations* sentences (22, 25), so they stay base; new are *sans hésiter*, *n'hésite pas* (the *tu* form of 03's *n'hésitez pas*) and Robin's *j'en suis sûre* (feminine: Corriger on *sûr*). |
| `sit_20_reason` | Donner une raison | 1st | 4 (surtout, pratique, économiser, comme ça) | A recommendation needs a reason: *c'est pratique*, *surtout* (above all), *comme ça…* (that way…) and *économiser* (save money). *Parce que* and *pour* + infinitive (06) come back. |
| `sit_20_warn` | Mettre en garde | 2nd | 3 (fais attention, évite, arnaque) | Advice can be a warning: *fais attention*, *évite…*, and *une arnaque* (a scam: paying for a flat before the visit, a fake bank text). *Faites attention / évitez* with *vous* (Transformer), Corriger on *fait attention*. |
| `sit_20_weigh` | Le pour et le contre | 2nd | 3 (le pour et le contre, réfléchir, d'un côté) | Thinking it through before advising: *faire le pour et le contre*, *réfléchir*, *d'un côté… de l'autre…*. Robin also says *je vais réfléchir* to her manager (*vous*) and to Mme Dumas. |
| `sit_20_formal` | Conseiller en vous | 2nd | 3 (je vous recommande, à votre place, renseignez-vous) | The *vous* version: Mme Dumas, M. Ferrand and an estate agent give and ask advice. *Je vous recommande*, *à votre place* (the *vous* form of the *Fondations* *à ta place*) and *renseignez-vous* (ask for details, look into it). |
| `sit_20_after` | Alors, tu as choisi ? | 2nd | 3 (tu as eu raison, regretter, félicitations) | After the advice: *tu as eu raison* (you were right: passé composé of the *Fondations* phrase *avoir raison*), *tu ne vas pas regretter*, *félicitations !*. Corriger on *regretté → regretter*. |

## 4. Totals

| Module | New words (1st / 2nd half) | Spoken forms | Dialogues not face to face (of 80) | Channel mix (dialogues) |
|---|---|---|---|---|
| 16 Raconter sa soirée | 25 (12 / 13) | — | 40 | face to face 40, Texto 29, Les copains 6, Appel 3, WhatsApp 2 |
| 17 Une galère | 25 (12 / 13) | — | 46 | face to face 34, Texto 23, Appel 9, Les copains 9, WhatsApp 5 |
| 18 Comparer | 25 (12 / 13) | — | 37 | face to face 43, Texto 25, WhatsApp 4, Appel 4, Les copains 4 |
| 19 Choisir ensemble | 25 (13 / 12) | — | 68 | Les copains 39, Texto 20, face to face 12, Appel 9 |
| 20 Conseiller | 25 (13 / 12) | — | 48 | Texto 32, face to face 32, WhatsApp 9, Appel 5, Les copains 2 |
| **Arc 4 (16–20)** | **125** | **0** | **239 of 400** | |

The arc is about telling and deciding with people Robin knows, so it leans on texts (Léa, Inès, Théo), the group chat (19 most of all: 39 of its 80 dialogues are in « Les copains ») and calls; the café, the office, the landing, the bouchon (16), the estate agency and the shops (18) keep the face-to-face scenes. Every move has 3–8 of its 10 dialogues off its home channel. No new spoken form: the *tu* exchanges reuse *t'es, t'as, t'inquiète, pas de souci, top* from arcs 1–3, and the informal words this arc teaches (*galère, mince, sans blague, pas terrible, expo, en promo, franchement*) are standard spoken French, glossed plainly (open question 2). Per move, every new word recurs in at least two later dialogues of the same move and gets a later Mot or Mot en retour drill; no item introduces more than two new words.

## 5. Cross-module word progression

Each word is taught once, in the earliest module that needs it. Later modules reuse it freely and never put it back in `newWords`. The right column counts any later use, distractors included.

| Module | Words taught (book-wide first) | Carried into later arc-4 modules |
|---|---|---|
| 16 | *raconte*; *concert*; *boire un verre*; *d'abord*; *ensuite*; *puis*; *sortie*; *en boîte*; *bar*; *bouchon lyonnais*; *dessert*; *l'addition*; *croisé*; *ancien*; *par hasard*; *rencontré*; *minuit*; *couchée*; *épuisée*; *ambiance*; *plein de*; *ennuyeux*; *rien de spécial*; *pas grand-chose*; *ça s'est bien passé* | *raconte* (17); *boire un verre* (17); *d'abord* (19); *puis* (19); *bar* (20); *bouchon lyonnais* (19, 20); *dessert* (19); *l'addition* (19); *par hasard* (18); *ennuyeux* (18) |
| 17 | *galère*; *horrible*; *en plus*; *qu'est-ce qui s'est passé*; *tout à coup*; *tombé*; *mince*; *oh là là*; *sans blague*; *mon pauvre*; *dur*; *énervant*; *trempé*; *parapluie*; *portable*; *batterie*; *pire*; *au moins*; *pas terrible*; *ça va aller*; *ça va s'arranger*; *bon courage*; *un coup de main*; *changer les idées*; *je t'invite* | *horrible* (18); *sans blague* (20); *énervant* (18); *parapluie* (20); *pire* (18, 19, 20) |
| 18 | *appartement*; *lumineux*; *balcon*; *loyer*; *par mois*; *charges comprises*; *bruyant*; *près*; *centre-ville*; *forfait*; *illimité*; *réseau*; *électrique*; *d'occasion*; *léger*; *lourd*; *rapport qualité-prix*; *ça vaut le coup*; *en promo*; *avantage*; *inconvénient*; *par contre*; *j'hésite*; *ça dépend*; *convaincue* | *appartement* (20); *lumineux* (20); *par mois* (20); *bruyant* (20); *près* (20); *centre-ville* (20); *forfait* (20); *illimité* (20); *électrique* (20); *d'occasion* (20); *léger* (20); *en promo* (20); *ça dépend* (19) |
| 19 | *ça vous dit*; *on pourrait*; *sinon*; *pique-nique*; *au bord de*; *expo*; *je préférerais*; *ça m'est égal*; *comme vous voulez*; *sondage*; *voter*; *majorité*; *égalité*; *compromis*; *chacun*; *tant pis*; *c'est décidé*; *lieu*; *rappel*; *je m'en charge*; *lien*; *en ligne*; *partager*; *en tout*; *par personne* | *pique-nique* (20); *ça m'est égal* (20); *en ligne* (20) |
| 20 | *conseil*; *qu'est-ce que tu en penses*; *choix*; *je te conseille*; *je te recommande*; *franchement*; *sans hésiter*; *n'hésite pas*; *sûre*; *surtout*; *pratique*; *économiser*; *comme ça*; *fais attention*; *évite*; *arnaque*; *le pour et le contre*; *réfléchir*; *d'un côté*; *je vous recommande*; *à votre place*; *renseignez-vous*; *tu as eu raison*; *regretter*; *félicitations* | — |

**Vocabulary audit** (each new key grepped against the answer sentences in `Resources/Topics/*.json` and against the exposure lines of every item in 01–15): none of the 125 keys is printed earlier, and none is a *Fondations* answer phrase. *Fondations* words the arc builds on stay **base** (glossed, never underlined), listed in §8.2: *à ta place, si j'étais toi, tu as raison, la tienne* (19's « moins grande que la tienne »), *tu devrais, je prendrais, je ferais, rentré, resté, tombée, mangé, sorti, choisir, musée, courage, triste, difficile…*. *Soirée*, *hier soir*, *quelle journée*, *pas de chance*, *bonne chance* and *moins cher* are already printed in 01–15 (inside *bonne soirée* and others), so they cannot be new keys; they stay base or compositional.

## 6. Words moved between modules, avoided or deferred

- **From café, arcs 1–3: none moved.** No earlier entry changes. Two existing entries get reused in a new sense only where their gloss already fits: *carte* gets its own base entry "card" (it was only inside *par carte* / *carte vitale*), and *plein* gets "full (plein de = lots of)".
- **Within the batch** (taught once, reused later; see §5): *raconte*, *boire un verre* (16 → 17); *d'abord, puis, bar, dessert, l'addition, bouchon lyonnais* (16 → 19, 20); *pire, horrible, énervant, parapluie, sans blague* (17 → 18–20); 18's flats, plans and bikes vocabulary (*appartement, lumineux, par mois, bruyant, près, centre-ville, forfait, illimité, électrique, d'occasion, léger, en promo*) → 20's advice; *ça dépend* (18 → 19); *pique-nique, ça m'est égal, en ligne* (19 → 20).
- **Kept base because *Fondations* has it:** *en ville* (« il habite en ville »); 16 `out` teaches *en boîte* instead.
- **Kept out because 01–15 already print them** (a taught key would fail the book-order lint): *soirée* (inside *bonne soirée*: a base entry "evening, party" in 16's table), *hier soir*, *quelle journée*, *pas de chance*, *bonne chance*, *va pour*, *moins cher*, *plus grand*.
- **Avoided:** *resto* (spoken short form; 16 says *restaurant* and *bouchon lyonnais*), *nul, truc, crevée* ("exhausted": clashes with 15's tyre), *sérieux ?* (would need a spoken entry), *nuit, ascenseur, escalier, salle, chef, mienne / mien / tien* (untaught), *annonce* for a listing, *billets* for a concert, *seul* for "only", quantity comparisons *plus de / moins de* + noun, *pas plus*, numbers above *vingt*, *je n'arrive pas à*, *ça va te* + infinitive, *s'il fait beau*.
- **Deferred to arc 5:** *à mon avis*, *un avis* (21 *Donner son avis*), *d'accord / pas d'accord* as a topic (22), *parce que / donc* chains as a topic (23), *et si…* (24).

## 7. Grammar recycled from *Fondations*

Book 1 module numbers are in brackets. **What *Fondations* actually teaches** (checked in `Resources/Topics/*.json`): passé composé with *avoir* including negatives and questions (13); with *être* including every agreement, *je suis allée / partie / venue / tombée*, negatives and questions (14); pronominal passé composé *je me suis reposé, elle s'est lavée* (15); imparfait for description, habit and background, *c'était*-type *était*, *il y avait*-type *avait*, *il pleuvait dehors* (16); object pronouns including with the passé composé (17); *y / en* including *j'en ai*, *il en parle* (18); comparatives *plus / moins / aussi … que*, *meilleur / mieux*, superlatives *le plus*, *le moins cher*, *le meilleur restaurant*, and one example with *la tienne* (19); imperatives (20); futur simple (21); conditional *je voudrais, tu devrais, pourriez-vous, j'aimerais, ce serait, à ta place je partirais* (22); subjunctive after *il faut que / je veux que* (24); *si* clauses including *si j'étais toi*, *si on allait au cinéma* (25). **Not taught there, so the sketches avoid it:** passé récent *venir de* + infinitive, *être en train de*, plus-que-parfait, gérondif, *le mien / le tien*, *ce qui / ce que* (open question 4). *Pire* is not in 19's examples: 17 teaches it as a word.

- **16:** passé composé with *avoir* for events, no agreement with Robin (*j'ai pris*, *j'ai croisé*, *j'ai rencontré*; Corriger on *rencontrée*, 13); passé composé with *être* and Robin's feminine agreement (*je suis allée, sortie, rentrée, restée*; Corriger on *allé, sorti, rentré, resté*, 14); pronominal passé composé *je me suis couchée*, *ça s'est bien passé* (15); imparfait for description *c'était, il y avait, la musique était* (16); sequencing *d'abord, ensuite, puis, après*; *tu* and *vous* questions about the past (*Qu'est-ce que vous avez fait ?*, 06, 13); adjective agreement *ennuyeux / ennuyeuse*, *délicieux* (07); *à + le = au* (*au bar, au concert*, 10).
- **17:** passé composé with *être* in a story (*il est tombé*, Robin *je suis tombée*: Corriger on *tombé*, 14) and *avoir* (*j'ai raté*, *j'ai oublié*, 13); imparfait for the background and passé composé for the event (*il pleuvait et j'ai oublié mon parapluie*; *tout à coup, mon vélo ne marchait plus*, 16); pronominal passé composé *qu'est-ce qui s'est passé ?* (15); futur proche *ça va aller*, *ça va s'arranger* (12); comparison *pire que la tienne* (19, with *la tienne* from its examples); adjective agreement *dur / dure*, *énervant*, *trempé / trempée*, *mon pauvre / ma pauvre* (07); *quel / quelle* (06); *tu* and *vous* imperatives *repose-toi / reposez-vous*, *ne t'inquiète pas / ne vous inquiétez pas* (20); *ne… plus* (*plus de batterie*, 05); object pronouns *je te prête*, *je te donne un coup de main*, *je t'invite* (17).
- **18:** comparatives *plus / moins / aussi + adjective + que* with agreement (*plus lumineux*, *moins chère*; Corriger on *lumineuse*, *bruyante*, *chère*, 19); superlatives *le plus léger*, *le moins cher*, *le meilleur rapport qualité-prix* (19); *meilleur* (adjective) against *mieux* (adverb), Corriger on *meilleure* (19); *de + le = du* (*près du métro*, *loin du centre-ville*, *ça dépend du prix*, 10); demonstratives *ce / cet / cette* (*cet appartement*, 07); *quel* + noun (06); object pronoun *je le prends* (17); Robin's feminine *convaincue* (07); *tu / vous* questions to the estate agent and the shop (03, 06). Quantity comparisons (*plus de / moins de* + noun) are left out on purpose: *plus de* is glossed "no more" (06).
- **19:** conditional for soft proposals and preferences *on pourrait*, *je préférerais*, *ça vous dirait* (22; Corriger on *on pourrais*, *je préférerait*); *vous* plural to the group against *tu* to one friend (*ça vous dit / ça te dit*, *comme vous voulez / comme tu veux*, 03); *il faut* + infinitive (*il faut voter*); passé composé *j'ai voté*, *la majorité a préféré*, *j'ai réservé* (13); *chacun* + singular verb (Corriger on *choisissent*); futur simple *je serai là* (21); object pronouns *je te rembourse*, *je te l'envoie*, *on le prend* (17); *y* in *on y va* (18); *de + le = du* (*à côté du pont*, 10); numbers stay small words (*cinq, huit, dix, vingt*).
- **20:** conditional for advice *tu devrais*, *je prendrais*, *je ferais*, *ce serait* (22: *tu devrais te reposer*, *à ta place je partirais* are its examples; Transformer *tu dois → tu devrais*); *si j'étais toi / vous, je…* (25); *tu / vous* imperatives *fais attention / faites attention*, *évite / évitez*, *renseignez-vous*, *n'hésite pas* (20); *en* in *qu'est-ce que tu en penses ?*, *j'en suis sûre* (18); object pronouns *je le prendrais*, *je l'appelle*, *je lui dis* (17); passé composé *tu as eu raison*, *j'ai pris*, *j'ai acheté* (13); futur proche negative *tu ne vas pas regretter* (12); Robin's feminine *sûre* (Corriger on *sûr*, 07); *pour* + infinitive and *comme ça* for reasons (06).

## 8. Shared base glosses (copy byte for byte)

Arc 1 had 33 gloss conflicts at assembly; arcs 2–3 cut them by giving authors this section. Give it to every author. It has three parts.

### 8.1 Existing `words.json` entries the sketches use in two or more halves

Copied from `words.json`. The last column is the halves whose sketches use the entry (16a = module 16 first half), counting every quoted line, filled gap and choice. Copy the entry exactly; never edit it in a draft. Entries used by only one half are not listed: look them up in `words.json`.

| fr | en | spoken | audio | Used by |
|---|---|---|---|---|
| a | has |  | `sitw_a` | 16a, 17a, 18a, 18b, 19a, 19b, 20a, 20b |
| ah bon | oh really? |  | `sitw_ah_bon` | 16b, 18b, 19b, 20a, 20b |
| aller | to go |  | `sitw_aller` | 19a, 20a |
| alors | so / then |  | `sitw_alors` | 16a, 18b, 19a, 19b, 20a, 20b |
| amie | friend (female) |  | `sitw_amie` | 16b, 18a, 18b, 20b |
| appelle | call / calls |  | `sitw_appelle` | 17b, 19b |
| apporte | bring / am bringing |  | `sitw_apporte` | 19a, 19b |
| après | after |  | `sitw_apres` | 16a, 16b, 17b, 19b |
| apéro | pre-dinner drinks (with friends) |  | `sitw_apero` | 16b, 19a, 19b |
| arrivé | arrived |  | `sitw_arrive_past` | 17a, 17b |
| as | have |  | `sitw_as` | 16a, 16b, 17a, 17b, 19a, 19b, 20a, 20b |
| au | at the / to the |  | `sitw_au` | 16a, 16b, 17a, 17b, 18a, 19a, 19b, 20a, 20b |
| aussi | also / too |  | `sitw_aussi` | 17a, 19a, 19b |
| aux | to the / at the / with (à + les) |  | `sitw_aux` | 16a, 20a |
| avait | had (il y avait = there was) |  | `sitw_avait` | 16b, 17a |
| avant | before |  | `sitw_avant` | 16b, 19a, 20b |
| avec | with |  | `sitw_avec` | 16a, 16b, 17b, 18a, 20a |
| avez | have |  | `sitw_avez` | 16a, 16b, 17a, 20a, 20b |
| avons | have (nous) |  | `sitw_avons` | 19a, 20b |
| beau | beautiful, nice |  | `sitw_beau` | 17b, 18b, 19b |
| beaucoup | a lot / very much |  | `sitw_beaucoup` | 17b, 18a, 18b, 19b, 20a |
| bien | well / good / indeed |  | `sitw_bien` | 16a, 16b, 17a, 19b, 20b |
| bien sûr | of course |  | `sitw_bien_sur` | 17b, 19b, 20a, 20b |
| bon | well / OK (also: good, happy) |  | `sitw_bon` | 16a, 16b, 17b, 18b, 19b, 20a, 20b |
| bon rétablissement | get well soon |  | `sitw_bon_retablissement` | 17a, 20b |
| bonjour | hello |  | `sitw_bonjour` | 18a, 19b |
| bonne | good (feminine) |  | `sitw_bonne` | 16b, 17b, 18b, 19a, 19b, 20a, 20b |
| bons | good (plural) |  | `sitw_bons` | 20a, 20b |
| boulangerie | bakery |  | `sitw_boulangerie` | 17a, 20b |
| bruit | noise |  | `sitw_bruit` | 16b, 17a, 18a |
| bus | bus |  | `sitw_bus` | 17a, 17b, 20b |
| c'est | it is |  | `sitw_c_est` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| c'est combien | how much is it? |  | `sitw_c_est_combien` | 18a, 19b |
| c'est noté | noted |  | `sitw_c_est_note` | 19b, 20b |
| c'était | it was |  | `sitw_c_etait` | 16a, 16b, 17b |
| café | coffee / café |  | `sitw_cafe` | 16a, 16b, 17a, 17b, 18b, 19a, 19b, 20a, 20b |
| calme | quiet, calm |  | `sitw_calme` | 18a, 18b |
| ce | this / that |  | `sitw_ce` | 16a, 16b, 17a, 18a, 18b, 19a, 19b, 20a, 20b |
| ce matin | this morning |  | `sitw_ce_matin` | 16a, 16b, 18a |
| ce soir | this evening |  | `sitw_ce_soir` | 16a, 16b, 17a, 17b, 19a, 19b, 20a |
| cet | this (before a vowel) |  | `sitw_cet` | 16b, 17a, 18a, 18b, 20a, 20b |
| cette | this (feminine) |  | `sitw_cette` | 16b, 17a, 18b |
| chance | luck |  | `sitw_chance` | 17b, 20a |
| cher | expensive, dear |  | `sitw_cher` | 16a, 18a, 18b, 19b, 20a, 20b |
| cherche | look for / looks for |  | `sitw_cherche` | 17b, 18a |
| chers | expensive (plural) |  | `sitw_chers` | 16a, 18a, 18b, 19b, 20a |
| chez | at (someone's place) |  | `sitw_chez` | 16a, 16b, 17b, 18a, 19a, 19b |
| choisis | choose (je, tu) |  | `sitw_choisis` | 19a, 19b |
| chère | expensive (feminine) |  | `sitw_chere` | 16a, 18a, 18b, 19b, 20a |
| cinq | five |  | `sitw_cinq` | 18a, 19b |
| cinéma | cinema, the movies |  | `sitw_cinema` | 16a, 17b, 18b, 19a, 19b, 20b |
| combien | how much / how many |  | `sitw_combien` | 18a, 18b, 20b |
| commence | start(s) |  | `sitw_commence` | 16a, 19b |
| comment | how |  | `sitw_comment` | 16a, 16b, 17a, 19a, 20b |
| complet | full, fully booked |  | `sitw_complet` | 19a, 19b |
| coûte | costs |  | `sitw_coute` | 18a, 18b, 20b |
| croissants | croissants |  | `sitw_croissants` | 17a, 19a |
| cuisine | kitchen / cook(s) |  | `sitw_cuisine` | 16a, 18a |
| d'accord | OK, agreed |  | `sitw_d_accord` | 16a, 17b, 18b, 19a, 19b, 20a, 20b |
| dans | in |  | `sitw_dans` | 16a, 17a, 18a, 19a |
| de | of / from |  | `sitw_de` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| demain | tomorrow |  | `sitw_demain` | 17b, 19a, 19b, 20b |
| des | some |  | `sitw_des` | 16a, 16b, 17a, 18b, 19a, 19b, 20a, 20b |
| deux | two |  | `sitw_deux` | 17a, 18b, 19a, 19b, 20a, 20b |
| deuxième | second |  | `sitw_deuxieme` | 18a, 20a |
| devant | in front of, outside |  | `sitw_devant` | 17a, 17b, 19b |
| dimanche | Sunday |  | `sitw_dimanche` | 16a, 19a, 19b |
| dit | says / said |  | `sitw_dit` | 19a, 20b |
| dix | ten |  | `sitw_dix` | 16a, 18a, 19b |
| dois | have to, must (je, tu) |  | `sitw_dois` | 20a, 20b |
| dommage | what a shame |  | `sitw_dommage` | 16b, 19b |
| donner | to give |  | `sitw_donner` | 17b, 20a |
| du | some / of the |  | `sitw_du` | 16a, 16b, 17a, 18a, 18b, 19a, 19b, 20a, 20b |
| délicieux | delicious |  | `sitw_delicieux` | 16a, 18a, 20b |
| désolée | sorry (feminine) |  | `sitw_desolee` | 16b, 17a |
| dîner | dinner |  | `sitw_diner` | 16a, 16b, 19b |
| elle | she / it |  | `sitw_elle` | 16b, 17a, 18b, 20b |
| en | in, by / some, of it (pronoun) |  | `sitw_en` | 16a, 16b, 17b, 19a, 19b, 20a, 20b |
| en ce moment | at the moment, these days |  | `sitw_en_ce_moment` | 17a, 18b |
| en face | opposite, across the street |  | `sitw_en_face` | 16a, 20b |
| en panne | broken / out of order |  | `sitw_en_panne` | 17a, 17b, 19b |
| en retard | late |  | `sitw_en_retard` | 17a, 20b |
| encore | still / again / more |  | `sitw_encore` | 16a, 17a, 17b, 18b, 19a, 20b |
| ensemble | together |  | `sitw_ensemble` | 16a, 20b |
| entre | between, among / come in |  | `sitw_entre` | 16a, 18b, 20a |
| es | are (tu) |  | `sitw_es` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| essayer | to try (on) |  | `sitw_essayer` | 20a, 20b |
| est | is |  | `sitw_est` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| et | and |  | `sitw_et` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| euros | euros |  | `sitw_euros` | 18a, 18b, 19b, 20b |
| excusez-moi | sorry / excuse me (vous) |  | `sitw_excusez_moi` | 17b, 18a, 18b, 19b |
| faire | do / make |  | `sitw_faire` | 16b, 19a, 20b |
| fais | do / make (je, tu) |  | `sitw_fais` | 16a, 16b, 19a, 19b, 20a, 20b |
| fait | does / makes / done, made / comes to |  | `sitw_fait` | 16a, 16b, 17a, 17b, 19a, 19b, 20b |
| fatiguée | tired (feminine) |  | `sitw_fatiguee` | 16b, 17a, 17b, 20b |
| fermée | closed (feminine) |  | `sitw_fermee` | 16a, 17a |
| ferrand | Ferrand (surname) |  | `sitw_ferrand` | 16b, 17a, 17b, 20a |
| film | film, movie |  | `sitw_film` | 16b, 17b, 19a, 19b, 20a |
| fini | finished, over |  | `sitw_fini` | 17b, 19a |
| fois | time (one time, twice…) |  | `sitw_fois` | 16a, 17a, 18a |
| gare | station |  | `sitw_gare` | 16a, 17a, 18a, 20a |
| gentil | kind |  | `sitw_gentil` | 16b, 17b, 20a |
| gentille | kind (feminine) |  | `sitw_gentille` | 16b, 17b, 20a, 20b |
| gentils | kind (plural) |  | `sitw_gentils` | 16b, 17b, 20a |
| grand | large |  | `sitw_grand` | 17b, 18a, 18b, 20a, 20b |
| génial | great |  | `sitw_genial` | 16a, 16b |
| heure | hour / o'clock |  | `sitw_heure` | 16a, 17b, 19a, 19b |
| heures | o'clock / hours |  | `sitw_heures` | 16a, 17a, 17b, 18a, 19a, 19b |
| hier | yesterday |  | `sitw_hier` | 16a, 16b |
| huit | eight |  | `sitw_huit` | 17a, 19b, 20b |
| ici | here (on the phone: this is) |  | `sitw_ici` | 16b, 18a |
| idée | idea |  | `sitw_idee` | 17b, 18b, 19a, 19b, 20a, 20b |
| il | he / it |  | `sitw_il` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 20a, 20b |
| il fait beau | the weather's nice |  | `sitw_il_fait_beau` | 17b, 19a |
| il n'y a | there isn't / there aren't |  | `sitw_il_n_y_a` | 17a, 18a |
| il pleut | it's raining |  | `sitw_il_pleut` | 17a, 17b, 19b, 20a |
| il y a | there is / there are |  | `sitw_il_y_a` | 16b, 17a, 18a, 18b, 19a, 20b |
| ils | they |  | `sitw_ils` | 18b, 20a |
| inès | Inès |  | `sitw_ines` | 16a, 16b, 18a, 18b, 20a, 20b |
| j'ai | I have |  | `sitw_j_ai` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| j'ai pris | I had / I took (prendre) |  | `sitw_j_ai_pris` | 16a, 20b |
| j'appelle | I call, I'm calling |  | `sitw_j_appelle` | 17a, 19b, 20a |
| j'apporte | I'm bringing / shall I bring |  | `sitw_j_apporte` | 19a, 19b |
| j'arrive | I'm coming, I'm on my way / I arrive |  | `sitw_j_arrive` | 16a, 17a, 18b |
| je | I |  | `sitw_je` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| je crois | I think |  | `sitw_je_crois` | 17b, 18b |
| je peux | I can |  | `sitw_je_peux` | 16a, 17b, 19a, 20a, 20b |
| je prends | I'll have / I take |  | `sitw_je_prends` | 16a, 16b, 20a, 20b |
| je te dis | I'll let you know (tu) |  | `sitw_je_te_dis` | 20a, 20b |
| je voudrais | I would like |  | `sitw_je_voudrais` | 18a, 19b |
| je vous remercie | thank you (formal) |  | `sitw_je_vous_remercie` | 19b, 20b |
| jeudi | Thursday |  | `sitw_jeudi` | 19a, 19b, 20a |
| jour | day |  | `sitw_jour` | 16b, 19b |
| journée | day |  | `sitw_journee` | 16b, 17a, 17b |
| jours | days |  | `sitw_jours` | 16b, 19a |
| karim | Karim |  | `sitw_karim` | 16a, 18a, 19a |
| l'apéro | the apéro |  | `sitw_l_apero` | 19a, 19b |
| la | the (feminine) / it, her |  | `sitw_la` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| le | the (masculine) / it, him |  | `sitw_le` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| les | the (plural) / them |  | `sitw_les` | 17a, 17b, 18b, 19a, 19b, 20a, 20b |
| libre | free (not busy) |  | `sitw_libre` | 18a, 19a |
| lit | bed |  | `sitw_lit` | 16b, 17a |
| lundi | Monday |  | `sitw_lundi` | 17b, 20a |
| là | there / here |  | `sitw_la_there` | 16a, 16b, 17a, 19b |
| léa | Léa |  | `sitw_lea` | 16a, 16b, 17a, 17b |
| M. | Mr |  | `sitw_m` | 16b, 17a, 17b, 20a |
| m'envoyer | send me |  | `sitw_m_envoyer` | 18b, 19b |
| ma | my (feminine) |  | `sitw_ma` | 16b, 17a, 17b |
| madame | madam / Mrs |  | `sitw_madame` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| maintenant | now |  | `sitw_maintenant` | 18a, 19b |
| mais | but |  | `sitw_mais` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20b |
| malade | ill, sick |  | `sitw_malade` | 17a, 17b |
| mange | eat / eats |  | `sitw_mange` | 16a, 19b |
| marche | works (ça marche = that works) |  | `sitw_marche` | 19a, 19b |
| marché | market |  | `sitw_marche_market` | 16a, 16b |
| matin | morning |  | `sitw_matin` | 16a, 16b, 19b, 20a |
| me | me |  | `sitw_me` | 16b, 17b, 19b, 20a, 20b |
| meilleur | better, best |  | `sitw_meilleur` | 17b, 18a, 18b, 20a |
| meilleure | better, best (feminine) |  | `sitw_meilleure` | 18a, 18b, 20a |
| merci | thank you |  | `sitw_merci` | 16a, 16b, 17a, 17b, 18a, 19a, 19b, 20a, 20b |
| mes | my (plural) |  | `sitw_mes` | 17a, 20a |
| midi | noon, lunchtime |  | `sitw_midi` | 16a, 19a, 19b, 20b |
| mieux | better |  | `sitw_mieux` | 17a, 17b, 18a, 18b, 19b |
| minutes | minutes |  | `sitw_minutes` | 16a, 18a |
| moi | me |  | `sitw_moi` | 16a, 16b, 17a, 17b, 18a, 19a, 19b, 20a, 20b |
| moi aussi | me too |  | `sitw_moi_aussi` | 17b, 18a, 19a |
| moi non plus | me neither |  | `sitw_moi_non_plus` | 18a, 19a |
| moins | less |  | `sitw_moins` | 17b, 18a, 18b, 19b, 20a, 20b |
| mon | my (masculine, or before a vowel) |  | `sitw_mon` | 16b, 17a, 17b, 18a, 18b, 20a, 20b |
| monsieur | sir / Mr |  | `sitw_monsieur` | 16a, 16b, 17a, 17b, 18a, 18b, 19b, 20a, 20b |
| métro | underground, subway |  | `sitw_metro` | 16a, 16b, 17a, 17b, 18a, 18b, 20a, 20b |
| n'a | has (not) |  | `sitw_n_a` | 17b, 18a |
| n'est | is (not) |  | `sitw_n_est` | 17a, 17b, 18a, 19b |
| ne | not (with pas) |  | `sitw_ne` | 16a, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| non | no / right? |  | `sitw_non` | 16a, 16b, 17a, 17b, 18a, 18b, 20b |
| noter | to note (down) |  | `sitw_noter` | 19b, 20b |
| notée | noted (feminine) |  | `sitw_notee` | 19b, 20b |
| nous | we / us |  | `sitw_nous` | 18a, 19a, 19b, 20b |
| nouveau | new |  | `sitw_nouveau` | 16b, 17b, 18b, 20b |
| oh | oh |  | `sitw_oh` | 17a, 17b |
| on | we / one | yes | `sitw_on` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| on se retrouve | we meet up |  | `sitw_on_se_retrouve` | 16a, 17b, 19a |
| on se voit | shall we meet? / we'll see each other |  | `sitw_on_se_voit` | 19a, 19b |
| on va | let's go / we're going |  | `sitw_on_va` | 16a, 16b, 17b, 19a, 19b |
| ou | or |  | `sitw_ou` | 17a, 18a, 18b, 19a, 19b, 20a |
| oublié | forgotten, forgot |  | `sitw_oublie` | 17a, 17b |
| oui | yes |  | `sitw_oui` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| où | where |  | `sitw_ou_where` | 16a, 16b, 17a, 17b, 18b, 19b, 20a |
| paie | pay / pays |  | `sitw_paie` | 16a, 19b, 20b |
| panneau | board, sign (departures board) |  | `sitw_panneau` | 17b, 20a |
| par | by / per |  | `sitw_par` | 16a, 18b, 19a, 19b |
| par carte | by card |  | `sitw_par_carte` | 16a, 19b |
| parfait | perfect |  | `sitw_parfait` | 18a, 18b, 19b, 20a |
| pas | not |  | `sitw_pas` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| pas de problème | no problem |  | `sitw_pas_de_probleme` | 16b, 17a, 19a, 20b |
| pas de souci | no worries | yes | `sitw_pas_de_souci` | 17b, 20b |
| pas grave | no big deal, never mind |  | `sitw_pas_grave` | 16b, 17a, 18a |
| pas trop | not really, not too (much) |  | `sitw_pas_trop` | 18b, 19a |
| payer | to pay |  | `sitw_payer` | 16a, 20b |
| petit | small (masculine) |  | `sitw_petit` | 18a, 18b, 19b, 20b |
| peut | can |  | `sitw_peut` | 17a, 18a, 19a, 19b |
| peux | can (je / tu) |  | `sitw_peux` | 17b, 19a |
| photos | photos |  | `sitw_photos` | 18b, 20a |
| piscine | swimming pool |  | `sitw_piscine` | 16a, 16b, 18b, 19a |
| pizza | pizza |  | `sitw_pizza` | 19a, 19b |
| place | place, seat, room (à la place = instead) |  | `sitw_place` | 20a, 20b |
| plombier | plumber |  | `sitw_plombier` | 16a, 16b, 17a, 20a, 20b |
| plus | more / most / no more |  | `sitw_plus` | 17a, 18a, 18b, 19a, 19b, 20a |
| plus de | no more |  | `sitw_plus_de` | 17a, 17b |
| pour | for |  | `sitw_pour` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| premier | first |  | `sitw_premier` | 18a, 20a, 20b |
| prend | takes |  | `sitw_prend` | 17b, 18b, 19b, 20b |
| prendre | to have / to take |  | `sitw_prendre` | 16a, 17b, 20a, 20b |
| prends | take |  | `sitw_prends` | 17a, 17b, 18a, 18b, 20a, 20b |
| prends soin de toi | take care of yourself |  | `sitw_prends_soin_de_toi` | 17a, 20b |
| pris | taken |  | `sitw_pris` | 16a, 20b |
| prix | price, prices |  | `sitw_prix` | 18b, 20a |
| problème | problem |  | `sitw_probleme` | 17a, 18b |
| préfère | prefer / prefers |  | `sitw_prefere` | 18a, 19a, 20b |
| préfères | prefer (tu) |  | `sitw_preferes` | 19a, 20b |
| pull | jumper, sweater |  | `sitw_pull` | 17b, 20a |
| qu'est-ce que | what |  | `sitw_qu_est_ce_que` | 16b, 17a, 20a |
| quand | when |  | `sitw_quand` | 16a, 17a, 18a, 20b |
| quartier | neighbourhood |  | `sitw_quartier` | 18a, 18b, 20b |
| que | that / which |  | `sitw_que` | 17b, 18a, 18b, 20a |
| quel | which / what |  | `sitw_quel` | 16a, 17a, 18b, 19a, 20a, 20b |
| quelle | which / what (feminine) |  | `sitw_quelle` | 16a, 17a, 17b, 18b, 19a, 19b, 20a |
| quelque chose | something |  | `sitw_quelque_chose` | 17b, 19b |
| quels | which / what (plural) |  | `sitw_quels` | 16a, 18b, 19a, 20a |
| qui | who |  | `sitw_qui` | 16a, 16b, 18a, 18b, 19b, 20a |
| quoi | what (informal) |  | `sitw_quoi` | 16a, 16b, 17a, 17b, 18a, 19a, 19b, 20a, 20b |
| rapide | quick, fast |  | `sitw_rapide` | 18b, 20a |
| raté | missed (a bus, a train) |  | `sitw_rate` | 17a, 17b |
| rendez-vous | appointment, meeting / let's meet |  | `sitw_rendez_vous` | 17b, 19b |
| rentre | come home / comes home |  | `sitw_rentre` | 16a, 16b |
| rentres | come home (tu) |  | `sitw_rentres` | 16a, 16b |
| rentrée | come home, got back (feminine) |  | `sitw_rentree` | 16a, 16b |
| repose-toi | rest (tu) |  | `sitw_repose_toi` | 17a, 20b |
| restaurant | restaurant |  | `sitw_restaurant` | 16a, 17b, 19a, 19b, 20a |
| reste | stay(s) / remains |  | `sitw_reste` | 16a, 16b, 17a, 20b |
| rester | to stay |  | `sitw_rester` | 17a, 19a, 20a |
| robin | Robin |  | `sitw_robin` | 19a, 20a |
| réserve | book / books (reserve) |  | `sitw_reserve` | 19b, 20b |
| réunion | meeting |  | `sitw_reunion` | 17a, 17b, 19b |
| s'il te plaît | please (to a friend) |  | `sitw_s_il_te_plait` | 16a, 20a |
| s'il vous plaît | please (vous) |  | `sitw_s_il_vous_plait` | 16a, 18a, 18b, 19b |
| sa | his / her |  | `sitw_sa` | 19a, 19b |
| sais | know (je, tu) |  | `sitw_sais` | 16b, 17a, 18a, 18b, 19a, 20a |
| salut | hi / bye (informal, tu) |  | `sitw_salut` | 18a, 19b |
| samedi | Saturday |  | `sitw_samedi` | 16a, 16b, 17b, 18b, 19a, 19b, 20a, 20b |
| sans | without |  | `sitw_sans` | 17a, 18a |
| se | oneself / each other |  | `sitw_se` | 16b, 17b, 19a |
| semaine | week |  | `sitw_semaine` | 17a, 17b, 18b, 19b |
| sept | seven |  | `sitw_sept` | 19a, 19b |
| serai | will be (je) |  | `sitw_serai` | 16a, 19b |
| si | if / yes (to a negative) |  | `sitw_si` | 18a, 20a |
| six | six |  | `sitw_six` | 16a, 19b |
| soir | evening |  | `sitw_soir` | 16a, 17a, 17b, 18b, 19a, 19b |
| son | his / her / its |  | `sitw_son` | 17a, 18a, 19b, 20a |
| sont | are (plural) |  | `sitw_sont` | 18b, 20a |
| sors | go out (je, tu) |  | `sitw_sors` | 16a, 17a |
| sort | goes out |  | `sitw_sort` | 16a, 17b |
| suis | am |  | `sitw_suis` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 20a, 20b |
| super | great |  | `sitw_super` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| sur | on / about |  | `sitw_sur` | 16a, 17a, 20b |
| sympa | nice, friendly |  | `sitw_sympa` | 16b, 18a, 18b, 19a, 20b |
| t'es | you are (tu es) | yes | `sitw_t_es` | 16b, 17b |
| ta | your (informal, feminine) |  | `sitw_ta` | 16a, 16b, 17a, 17b, 18a, 19a, 20a, 20b |
| tard | late |  | `sitw_tard` | 16a, 16b, 19a |
| tarte | tart, pie |  | `sitw_tarte` | 16a, 19b, 20a |
| taxi | taxi |  | `sitw_taxi` | 17b, 19b |
| te | you (informal) |  | `sitw_te` | 16a, 16b, 17b, 19a, 19b, 20a, 20b |
| temps | time / weather |  | `sitw_temps` | 18b, 20b |
| thé | tea |  | `sitw_the` | 17a, 18b, 20a |
| théo | Théo |  | `sitw_theo` | 16a, 16b, 17a, 17b, 18a, 19a, 20a |
| toi | you (informal) |  | `sitw_toi` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| ton | your (informal) |  | `sitw_ton` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 20b |
| top | great | yes | `sitw_top` | 18a, 20a, 20b |
| tout de suite | right away |  | `sitw_tout_de_suite` | 16b, 17b |
| train | train |  | `sitw_train` | 17a, 17b, 20a |
| tram | tram |  | `sitw_tram` | 20a, 20b |
| travail | work |  | `sitw_travail` | 16a, 17a, 17b, 20a, 20b |
| trop | too / too much |  | `sitw_trop` | 16b, 17a, 18a, 18b, 20a, 20b |
| très | very |  | `sitw_tres` | 16b, 18a, 18b, 20b |
| très bien | very well / very good |  | `sitw_tres_bien` | 16a, 16b, 20a |
| tu | you (friend) |  | `sitw_tu` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| tu me dis | let me know (tu) |  | `sitw_tu_me_dis` | 18a, 20b |
| tu peux | can you (tu) |  | `sitw_tu_peux` | 17b, 18b, 19b, 20a |
| un | a / one |  | `sitw_un` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| un peu | a little |  | `sitw_un_peu` | 18b, 20b |
| une | a / one |  | `sitw_une` | 16a, 16b, 17a, 17b, 18b, 19a, 19b, 20a, 20b |
| va | goes / go! (tu) / is going to / is doing / suits |  | `sitw_va` | 16b, 17a, 20a, 20b |
| vais | go / am going |  | `sitw_vais` | 16a, 16b, 17a, 20a, 20b |
| vas | go / are doing (tu) |  | `sitw_vas` | 16a, 16b, 17a, 18b, 19a, 20a, 20b |
| vendredi | Friday |  | `sitw_vendredi` | 17b, 19a |
| venir | to come |  | `sitw_venir` | 17a, 17b, 20a, 20b |
| verre | glass / a drink |  | `sitw_verre` | 16a, 19a |
| vers | around (a time) |  | `sitw_vers` | 16a, 19a |
| veut | wants |  | `sitw_veut` | 17a, 18a |
| veux | want |  | `sitw_veux` | 17a, 17b, 19a, 19b, 20a |
| viens | come (je / tu) |  | `sitw_viens` | 16a, 16b, 17a, 17b, 18a, 18b, 19a, 19b, 20a, 20b |
| vient | comes / is coming |  | `sitw_vient` | 16a, 17a, 20a, 20b |
| ville | city |  | `sitw_ville` | 16a, 16b, 19b |
| vingt | twenty |  | `sitw_vingt` | 19b, 20b |
| vite | quick / quickly |  | `sitw_vite` | 18b, 20b |
| voir | to see |  | `sitw_voir` | 18b, 19a, 20b |
| voiture | car |  | `sitw_voiture` | 17b, 20a |
| vont | go (ils, elles) |  | `sitw_vont` | 18b, 19a |
| vos | your (plural, or polite) |  | `sitw_vos` | 16b, 17a |
| votre | your (polite) |  | `sitw_votre` | 16b, 17b, 18a, 18b, 20b |
| voulez | want (polite) |  | `sitw_voulez` | 17a, 17b, 19b |
| vous | you (polite / plural) |  | `sitw_vous` | 16a, 16b, 17a, 17b, 18b, 19a, 19b, 20a, 20b |
| vous pouvez | can you (polite) |  | `sitw_vous_pouvez` | 17b, 18b, 19b |
| vu | seen |  | `sitw_vu` | 16b, 19a |
| vélo | bike |  | `sitw_velo` | 17a, 17b, 18b, 20a, 20b |
| week-end | weekend |  | `sitw_week_end` | 16a, 16b, 17a, 18b |
| y | there |  | `sitw_y` | 16b, 17a, 18b |
| à | to / at |  | `sitw_a_prep` | 16a, 16b, 17a, 17b, 18a, 19a, 19b, 20a, 20b |
| à cause de | because of |  | `sitw_a_cause_de` | 16b, 19a |
| à côté | nearby / next door / next to |  | `sitw_a_cote` | 16a, 16b, 19b |
| à la maison | at home |  | `sitw_a_la_maison` | 16a, 16b, 17a, 17b, 19a, 19b, 20b |
| à pied | on foot |  | `sitw_a_pied` | 18a, 20a, 20b |
| à quelle heure | at what time |  | `sitw_a_quelle_heure` | 16a, 16b, 17b, 19a, 19b |
| à vélo | by bike |  | `sitw_a_velo` | 17a, 20a |
| ça | that / it |  | `sitw_ca` | 16b, 17a, 18a, 18b, 19a |
| ça fait | the total comes to |  | `sitw_ca_fait` | 17b, 18b, 19a, 19b |
| ça marche | OK, that works / does that work? | yes | `sitw_ca_marche` | 18b, 19a |
| ça va | how are you? / I'm fine / it's fine |  | `sitw_ca_va` | 17a, 17b |
| étais | was (je, tu) |  | `sitw_etais` | 16a, 16b, 17b |
| était | was |  | `sitw_etait` | 16a, 16b, 17a, 17b |
| été | been |  | `sitw_ete` | 16a, 16b, 17b |
| êtes | are (vous) |  | `sitw_etes` | 16a, 16b, 17a, 17b, 19b, 20a, 20b |

### 8.2 New base entries this batch needs (not in `words.json` yet)

These are *Fondations* words (every token is in a *Fondations* answer) that the sketches use and `words.json` does not have yet. All have `firstSeen: null` and `spoken: false`. Use exactly these values in every half that needs them; the coordinator's conflict scan should then find nothing for them. The suffixed keys follow §2.7.

| fr | en | audio | Needed in |
|---|---|---|---|
| acheté | bought | `sitw_achete_past` | 18, 20 |
| allées | gone (feminine plural) | `sitw_allees` | 16 |
| appelle-moi | call me | `sitw_appelle_moi` | 20 |
| assez | quite, enough | `sitw_assez` | 18 |
| bois | drink (je, tu) | `sitw_bois` | 16 |
| choisir | to choose | `sitw_choisir` | 19, 20 |
| choisissent | choose (ils, elles) | `sitw_choisissent` | 19 |
| choisit | chooses | `sitw_choisit` | 19 |
| contente | happy (feminine) | `sitw_contente` | 20 |
| couche | go(es) to bed (se coucher) | `sitw_couche_verb` | 16 |
| couché | gone to bed | `sitw_couche_past` | 16 |
| courage | courage | `sitw_courage` | 17 |
| devrais | should (je, tu) | `sitw_devrais` | 20 |
| devriez | should (vous) | `sitw_devriez` | 20 |
| difficile | difficult | `sitw_difficile` | 17, 20 |
| envie | wish (j'ai envie = I feel like it) | `sitw_envie` | 20 |
| ferais | would do (je, tu) | `sitw_ferais` | 20 |
| finir | to finish | `sitw_finir` | 17 |
| habiter | to live | `sitw_habiter` | 18 |
| inquiétez | worry (vous; ne vous inquiétez pas = don't worry) | `sitw_inquietez` | 17 |
| manger | to eat | `sitw_manger` | 19 |
| mangé | eaten, ate | `sitw_mange_past` | 16 |
| meilleurs | better, best (plural) | `sitw_meilleurs` | 18 |
| musée | museum | `sitw_musee` | 19 |
| n'avais | had (not) (je, tu) | `sitw_n_avais` | 17 |
| nouvel | new (before a vowel) | `sitw_nouvel` | 20 |
| penses | think (tu) | `sitw_penses` | 17, 20 |
| pleuvait | was raining | `sitw_pleuvait` | 17 |
| pourrais | could (je, tu) | `sitw_pourrais` | 19 |
| prendrais | would take (je, tu) | `sitw_prendrais` | 20 |
| préférerait | would prefer (il, on) | `sitw_prefererait` | 19 |
| raison | reason (avoir raison = to be right) | `sitw_raison` | 20 |
| rapides | quick, fast (plural) | `sitw_rapides` | 18 |
| rentrer | to go home, to get back | `sitw_rentrer` | 16 |
| rentré | come home, got back | `sitw_rentre_past` | 16 |
| repas | meal | `sitw_repas` | 19 |
| resté | stayed | `sitw_reste_past` | 16 |
| restée | stayed (feminine) | `sitw_restee` | 16 |
| réponds | answer, reply (je, tu) | `sitw_reponds` | 20 |
| sorti | gone out | `sitw_sorti` | 16 |
| sous | under | `sitw_sous` | 17 |
| tienne | yours (la tienne = yours, tu) | `sitw_tienne` | 17 |
| tombée | fell, fallen (feminine) | `sitw_tombee` | 17 |
| triste | sad | `sitw_triste` | 17 |
| visiter | to visit, to view | `sitw_visiter` | 18 |
| visité | visited, viewed | `sitw_visite_past` | 18 |

### 8.3 Inflections

Each matrix ends with a glossed table of the inflections and distractor forms its sketches use that are neither in `words.json` nor *Fondations* answers (*sorti* is base, *soirée, rencontrée, trempée, lumineuse, préférerais, devrais…* are in the tables), with audio keys. They follow the `words.json` habit (*désolée* = "sorry (feminine)", *libres* = "free (plural)"), and a wrong form a Corriger or Fill decoy needs is glossed "(wrong form of …)" (*courages, t'invites, attentions*). A form is listed once, in the earliest module that uses it; a later module's half copies it. Totals: 16: 23, 17: 28, 18: 23, 19: 25, 20: 29.

## 9. How each matrix blocks the judges' recurring errors

| Error class | Whole batch | 16 | 17 | 18 | 19 | 20 |
|---|---|---|---|---|---|---|
| **Hidden valid replies** | Every *Clarify* row asks the author to accept the reply with and without « Pardon, ». Two-clause model replies need both orders in `accepted` or a bank that fixes the order. Fill distractors were picked so that only one is valid French in context; candidates that were valid were swapped (*normalement* → *malheureusement*, *ensemble* → *entre*, *très cher*, *du thé*, *Moi pareil*, *c'est bien*, *il est mieux*, *dans sept heures*). | *Oui, ___ ! Vers six heures ?* (volontiers / délicieux / malheureusement); *Le concert ___ super* (était / étais / été), never *est*. | *Tu veux ___ thé ?* (un / une / des), never *du*; *Oh, c'est ___ !* (énervant / énervante / énervants). | *Meilleur* and *mieux* never both fit: *c'est ___ dans la cuisine* takes *mieux*, *il est ___ que l'autre* offers *meilleur / meilleure / meilleurs* only (colloquial *il est mieux* is left out); *très* is never a choice beside *trop*. | *Moi ___ !* (aussi / non plus / plus); *D'accord, ___ sept heures ?* (vers / verre / vert). | *Il est ___ cher !* (trop / plein / pire); *Tu ___ prendre le premier !* (devrais / devrait / devriez). |
| **Standalone place labels** | Every standalone row carries its own place (§2.2). | `evening s02` WhatsApp · Mme Dumas; `dinner s02` Au restaurant; `out s02` Au bureau. | `react s02` WhatsApp · Mme Dumas; `story s02` Au bureau; `sympathise s04` Appel · Inès. | `flats s02`, `area s02` À l'agence; `plan s02` En boutique. | `propose s02` WhatsApp · Mme Dumas; `confirm s02`, `book s02` Appel · restaurant. | `should s02`, `inplace s02` Sur le palier; `formal s02` WhatsApp · Mme Dumas. |
| **Cue leaks and answer echo** | The validator rejected any Fill whose correct choice is printed in another quoted line of the item (fixed: 16 `dinner d09`, `late d03`; 17 `galere d06`, `react d09`, `cheer d07`; 18 `plan d06`, `bike d09`, `pros d07`; 19 `share d07`; 20 `weigh d06`). Quoted French is never cue text, and the cue must not state the fact a Comprendre asks. | The cue never says where Robin went or what she ate. | The cue never names what went wrong in Théo's day. | The cue never gives the rent, the price or which flat is brighter. | The cue never gives the vote result or the place decided. | The cue never names the option Inès chose. |
| **A speaker answering their own question** | Where a question must be followed by its answer, Robin's line is a printed learner line and the other speaker answers. Group-chat rows with two named speakers (17 `sympathise d01`) set `followUpBy`. | | | The estate agent answers Robin's question in `rent d03`, never his own. | | |
| **« Repeat » asked of a text** | *Clarify* rows are face to face or live calls only; the validator rejected any *Clarify* on Texto, Les copains or WhatsApp. Group-chat moves put their *Clarify* row on `Appel · Théo` / `Appel · Inès`. | `out d05`, `mood d05` Appel · Inès (a loud club, a loud bar); `met d05` Appel · Théo. | `galere d05`, `sympathise d05`… Appel. | `rent d05` Appel · agence; `area d05` Appel · Inès. | Every *Clarify* row is a call except `vote d05` (Karim, face to face). | `ask d05`, `reason d05`, `warn d05`, `weigh d05`, `after d05` Appel · Inès. |
| **Glosses wrong in context** | §2.8 lists the traps; §8 fixes every shared gloss; each matrix glosses its inflections. | *épuisée*, never *crevée*; *bouchon lyonnais* as a phrase; *en boîte* apart from *boîte aux lettres*. | *pour te changer les idées*, never *ça va te…*; *plus de batterie* ("no more" is right). | No *plus de* + noun; *près* keyed alone; *billets* never for tickets to an event. | *ça fait vingt euros en tout* (the total: right); *en ligne* keyed. | *je te dis* only as "I'll let you know"; *à ta place* base. |
| **Phrase key across a comma** | §2.9. | *boire un verre*, *ça s'est bien passé*, *rien de spécial* never split. | *ça va aller*, *ça va s'arranger*, *un coup de main* never split. | *rapport qualité-prix*, *ça vaut le coup*, *par contre* never split. | *ça m'est égal*, *comme vous voulez*, *je m'en charge* never split. | *le pour et le contre*, *à votre place*, *tu as eu raison* never split. |
| **Follow-ups that ignore the learner** | A Répondre follow-up must fit every accepted reply. Where Robin chooses (a day, a flat, an option), the author writes a follow-up that accepts the choice without naming it. | `askback d01`: Karim's follow-up must fit any evening. | `help d01`: Théo's follow-up must fit any time Robin gives. | `decide d01`, `d10`: Inès's follow-up must fit *le plus lumineux* or *le moins cher*. | `vote d10`, `options d08`: the group accepts Robin's pick. | `ask d10`, `inplace d01`: the follow-up must fit either option. |
| **False errors** | Corriger never targets an accepted spoken form or a common variant; *en carte* is common spoken French, so 16 `dinner d07` offers *par / à / de carte*. | *allé → allée*, *rentré → rentrée*, *sorti → sortie*, *une bouchon*, *rencontrée → rencontré* (avoir), *couché → couchée*, *ennuyeux → ennuyeuse*, *resté → restée*. | *Quel galère*, *tombé → tombée*, *mon clés*, *dur → dure*, *trempé → trempée*, *le tienne*, *bonne courage*, *t'invites*. | *lumineuse → lumineux*, *chère → cher*, *bruyante → bruyant*, *meilleure → meilleur* (×2), *une vélo*, *une avantage*, *convaincu → convaincue*. | *on pourrais*, *au bord du la*, *je préférerait*, *il faut voté*, *chacun choisissent*, *C'est décidée*, *la lien*, *par personnes*. | *deux appartement*, *meilleure → meilleur*, *sûr → sûre*, *chère → cher*, *Fait attention*, *réfléchi → réfléchir*, *pratiques → pratique*, *regretté → regretter*. |
| **Logic puzzles** | No gap depends on reasoning about who owns what or on arithmetic; totals and shares are printed (*vingt euros en tout*, *cinq euros par personne*), never computed. | Times are printed. | | Rents are compared in words, never in figures. | Shares are printed. | |
| **Untaught words used early** | Every quoted token and choice was segmented with the lint's matcher against `words.json`, this batch's keys in book order and the inflection tables (0 unknown, 0 early). Caught or avoided: *en ville* (a *Fondations* phrase: base, 16 teaches *en boîte*), *je vous recommande* in 20 `should s02` (taught in `formal`), *ça va te changer les idées*, *l'appartement* as a key form, *le mien / le tien*, *genou*, *escalier*, *ascenseur*, *chef*, *salle*, numbers above *vingt*. | | | | | |
| **Masculine forms for Robin** | Learner lines use feminine forms only; masculine forms appear as decoys and Corriger errors. Cues say "You're a woman." where the answer hinges on it. The validator extended `MASC_SELF` with *couché, tombé, épuisé, trempé, convaincu, sûr* (open question 3). | `evening s01`, `s03`, `s04`; `out s01`, `s03`, `s05`; `late s01`, `s03`, `s04`; `askback s03`. | `what d06`, `s03`; `story s01`, `s03`. | `decide s03` (*convaincue*). | — (the group decides; Robin's lines carry no participle). | `inplace s03` (*sûr → sûre*); `inplace d03`, `d08` (*Tu es sûre ?* addressed to Robin). |

## 10. `modules.json` entries (ready to paste)

Add these before the first assemble; the author agents don't.

```json
{"id": "sit_16", "title": "Raconter sa soirée", "arc": "Raconter", "goal": "Tell what you did last night, in order, and say how it was.", "file": "16_raconter_sa_soiree.json", "moves": ["evening", "order", "out", "dinner", "met", "late", "mood", "askback"]},
{"id": "sit_17", "title": "Une galère", "arc": "Raconter", "goal": "React to a friend's bad-day story, sympathise, ask what happened and ask back.", "file": "17_une_galere.json", "moves": ["galere", "what", "react", "sympathise", "story", "askback", "cheer", "help"]},
{"id": "sit_18", "title": "Comparer", "arc": "Raconter", "goal": "Compare flats, phone plans and bikes: advantages, drawbacks and value for money.", "file": "18_comparer.json", "moves": ["flats", "rent", "area", "plan", "bike", "better", "pros", "decide"]},
{"id": "sit_19", "title": "Choisir ensemble", "arc": "Raconter", "goal": "Propose, compare options and negotiate a plan in the group chat, then confirm it and share the costs.", "file": "19_choisir_ensemble.json", "moves": ["propose", "options", "prefer", "vote", "compromise", "confirm", "book", "share"]},
{"id": "sit_20", "title": "Conseiller", "arc": "Raconter", "goal": "Ask for and give advice: recommend an option with a reason, warn, and react to the choice.", "file": "20_conseiller.json", "moves": ["ask", "should", "inplace", "reason", "warn", "weigh", "formal", "after"]}
```

Drafts: `16_raconter_sa_soiree_{first,second}_half{,_words}.json`, `17_une_galere_{first,second}_half{,_words}.json`, `18_comparer_{first,second}_half{,_words}.json`, `19_choisir_ensemble_{first,second}_half{,_words}.json`, `20_conseiller_{first,second}_half{,_words}.json`.

## 11. Batch procedure (unchanged from the next-session handoff §4)

1. The coordinator settles the open questions (or takes the defaults below), then:
   - adds the five `modules.json` entries (§10);
   - (default for question 1) adds « Agent immobilier » / « Agente immobilière » to `MASCULINE_ROLES` / `FEMININE_ROLES` in `tools/situations/lint.py`, with a test;
   - (default for question 3) adds *couché, tombé, épuisé, trempé, convaincu, sûr* to `MASC_SELF`, with a test (the Corriger exemption via `corrected()` already covers error lines).
2. Two author agents per module (10 in all), **about 7 at a time** (arc 3 hit the usage limit twice with 10 + 20 in parallel; resume with SendMessage). Give each this file (§1–2, §8, §9), its matrix and `agents/author.md`, plus the arc 3 lessons in the prompt: check every Comprendre `correct`; every Choisir le ton option natural French; use the planned `_past` / `_verb` audio keys and check `words.json` before adding any participle; Corriger may target Robin's feminine agreement.
3. Gloss conflict scan over all drafts and `words.json` (§8 and the matrices' inflection tables should leave few), then `assemble.py 16 17 18 19 20`, lint, tests, `deep_lint.py` and the Swift model test. Reword Grammalecte false positives (no suppression list).
4. Four judges per module (two moves each), about 7 at a time, with §1–2 and §9 of this file. Judge pairs: 16 evening/order, out/dinner, met/late, mood/askback; 17 galere/what, react/sympathise, story/askback, cheer/help; 18 flats/rent, area/plan, bike/better, pros/decide; 19 propose/options, prefer/vote, compromise/confirm, book/share; 20 ask/should, inplace/reason, warn/weigh, formal/after.
5. Fixers (they re-check every Comprendre `correct` too), book-wide gloss widenings, then the *Fondations* audit of every new `firstSeen: null` entry.
6. One 9-card review set (v9), D D S order, drill types differing across item boundaries and adjacent dialogues with different drill pairs. Suggested: `sit_16_dinner_d01 sit_17_what_d03 sit_16_late_s03 sit_18_bike_d04 sit_19_vote_d03 sit_20_should_s02 sit_17_story_d05 sit_19_options_d02 sit_16_order_s04` (the bouchon lyonnais culture card, Théo's fall, Robin's *couchée* Corriger, the bikes, the group poll's tie, advising M. Ferrand in *vous*, a *Clarify* call about the umbrella, the picnic by the Saône, sequencing in the past).

## 12. Open questions for the user (with the default authoring will use)

1. **New role « Agent immobilier »** (male voice) for the estate agent in 18 and 20. Add « Agent immobilier / Agente immobilière » to the role gender lists in `lint.py`? **Default: yes, a small lint change.**
2. **Informal words without a spoken flag.** *Galère, mince, sans blague, oh là là, pas terrible, expo, en promo, franchement* are everyday spoken French but standard words, not contractions, so they are glossed plainly (`spoken: false`) like 02's *tranquille*. No new `SPOKEN` entry this arc; *resto* and *sérieux ?* are avoided. **Default: yes, no new spoken forms.** (Alternative: mark *galère, expo, promo* spoken, which needs `SPOKEN` additions.)
3. **Extend `MASC_SELF`** with *couché, tombé, épuisé, trempé, convaincu, sûr*, Robin's new participles and adjectives. **Default: yes, with a test.**
4. **Grammar beyond *Fondations*.** Passé récent (*je viens de rentrer*), *être en train de*, the plus-que-parfait, the gérondif, *le mien / le tien* and *ce qui / ce que* are not taught in *Fondations*, so the sketches avoid them; narration uses passé composé + imparfait only. *Pire* is not in *Fondations* 19's examples: 17 teaches it as a new word. **Default: keep these out; teach *pire*.**
5. **No quantity comparisons.** *Plus de* is glossed "no more" (06), so 18 compares with adjectives only (*plus grand, moins cher, plus lumineux*), never *plus de place / moins de bruit*. **Default: keep the gloss and the avoidance.** (Alternative: widen *plus de* to "more (of) / no more" book-wide, then 18 can add a few quantity rows.)
6. **Culture items:** *le bouchon lyonnais* and the pink *tarte aux pralines* (16), *la Saône* picnic (19), *charges comprises* and rental scams (*payer avant la visite*, 18, 20), splitting the bill (*partager l'addition*, 19). **Default: keep all.**
7. **New one-off facts:** Robin meets an old colleague by chance (16); Théo's disaster day, then a new job (17, 20); Inès hunts for a flat (18) and takes the first one (20); Robin buys an electric bike (18, 20: M. Ferrand and Mme Dumas mention it); Mme Dumas has another flat free (18) and a new plumber (20); the group chat runs a poll and a picnic by the Saône (19). **Default: all fine.**
8. **Feminine keys for Robin** (*sortie, couchée, épuisée, convaincue, sûre*), with the masculine as inflection or base (§2.5), and *en boîte* taught instead of the *Fondations* phrase *en ville*. **Default: yes.**
9. **Review before authoring.** Memory says to author in bulk only after the user approves a sample. **Default: author all five modules, then show the 9-card set in §11 as review set v9** (as arcs 2 and 3 did with v7 and v8).
