# Book 2, arc 3 *Les imprévus*: plan for modules 11–15

**Date:** 2026-10-12
**Status:** paper plan only. No French is authored. Nothing is committed. `modules.json` is unchanged (entries in §10).
**Matrices:** [11](2026-10-12-book-2-arc3-module-11-matrix.md) · [12](2026-10-12-book-2-arc3-module-12-matrix.md) · [13](2026-10-12-book-2-arc3-module-13-matrix.md) · [14](2026-10-12-book-2-arc3-module-14-matrix.md) · [15](2026-10-12-book-2-arc3-module-15-matrix.md)
**Rulebook:** [content handoff](2026-10-11-book-2-content-handoff.md) §3–§8; [café handoff](2026-10-11-book-2-cafe-handoff.md) §3; [next-session handoff](2026-10-11-book-2-next-session-handoff.md) §2 (binding user decisions), §4 (pipeline and judge finds) and §7; [2026-10-12 handoff](2026-10-12-book-2-handoff.md); `tools/situations/README.md`. Format copied from the [arc 2 plan](2026-10-11-book-2-arc2-plan.md).

Modules 01–10 are taught content: everything they teach (263 taught words in `words.json`, 1,052 entries in all) is known here, including arc 2's *pharmacie, colis, livreur, perdu, immeuble, ticket, rembourser, échanger, abîmé, réservation, laisser, message, ligne, arrêt, tram, jusqu'à, fermé, ouvert, en panne* and the café phrases.

Each matrix has one row per item (8 moves × 15 items = 120 per module) in the arc 2 format, a new-word table with the exact `en` / `spoken` / `audio` for every new word, and (new in this arc) a glossed table of every inflection and distractor form its sketches use. A validator in the planning scratchpad (not in the repo) checked all 600 rows before the matrices were written: item order and standalone labels; 1–2 drills per dialogue, no repeated type, no Répondre + Choisir; no same drill engine back to back across item boundaries; ≥4 dialogue types and Répondre + Compléter ≥ half per move; one *Clarify* dialogue per move, never on a text, group chat, WhatsApp or voicemail; ≥2 dialogues off the home channel; ≤2 new words per item, each printed in a quoted line of its first-seen item; each new word in ≥2 later dialogues and a later Mot or Mot en retour inside its own move; Mot targets visible in a quoted line; Mot en retour fill = target; ≤10 words per dialogue line and 8–14 in standalone lines; book order for every quoted token and every choice against *Fondations* answers, `words.json` and this batch's own order (0 unknown tokens left); answer echo in every Fill row; every new phrase key against all text printed in 01–10; audio-key collisions against `words.json` and inside the batch.

## 1. Fixed decisions this plan builds on

- **Robin** is a woman from Eugene, Oregon. Her lines are feminine only. This arc leans on it: *bloquée* (11), *absente* (12), *obligée*, *désolée*, *arrivée* (11, 13), *guérie* (14), *satisfaite* (15). A cue says "You're a woman." wherever an answer hinges on it; masculine forms appear only as decoys (gender decoys stay, user decision 2026-10-12) and in Corriger error lines.
- **Karim** says *tu* everywhere (after café `usual`), and Robin says *tu* to him.
- **M. Ferrand** and **Mme Dumas**: *vous* always. **Léa, Inès, Théo**: *tu*. In the group chat Théo's *vous* is plural; the cue says « vous = you all ».
- **Unnamed speakers carry a `role`** (lint requires it; no « Serveur » fallback). The Cast column gives the role and its voice: « Annonce » (station announcement, female), « Employé / Employée », « Voyageur / Voyageuse », « Chauffeur », « Responsable » (Robin's manager, female; a word taught in 08), « Voisine » (the neighbour downstairs), « Plombier », « Serrurier », « Gardienne », « Serveuse » (the 09 restaurant), « Pharmacienne », « Secrétaire », « Médecin », « Conseillère » (customer service), « Vendeuse », « Coiffeuse », « Réparateur ». A role is display only and never glossed, so it may be a word no line uses (*Pharmacienne*, *Réparateur*).
- **Home label « À l'appart »** (book-wide since 01). Lines never print *appart*; they say *à la maison* or *chez moi / chez nous*.
- **Module 10's map is canon.** Robin and Léa live at « huit, rue Pasteur », third floor, door code « deux, cinq, huit », blue front door, next to the bakery, opposite the corner pharmacy, with Karim's café on the corner. 14's pharmacy is « la pharmacie en face » (14 `pharmacy d08`); 12's caretaker, letterbox and landing are in that building. Nothing here contradicts it.
- **Underlines** mean "new here" only. A word taught in 01–10 is never put back in `newWords`.
- **Glossed base words** that stay untaught: *tout le monde, ah, oh, pas de problème, bonne journée, ça me va, c'est tout*, plus the *Fondations* phrases in §8.2.
- **No untaught phrase keys** (*je veux bien* stays out) and **no phrase key across a comma** (§2.9).
- Per move: 10 dialogues + 5 standalones (Construire, Choisir le ton, Corriger, Transformer, Mot en retour).

## 2. Conventions new in this arc

1. **Same drill template in every move** (as arc 2): d01 U R · d02 U C · d03 C U · d04 M R · d05 R M (*Clarify*) · d06 C U · d07 M C · d08 R U · d09 U C · d10 U R. That gives 4 types and Répondre + Compléter = 10 of 20 in each move, and no engine repeats across a boundary. Mot targets: the d01 word at d04, the d02 word at d05, the d03 word at d07; a fourth word gets s05.
2. **Places** (plain text, never glossed): `À la gare`, `Au guichet`, `Au métro`, `Dans la rue`, `À l'appart`, `Sur le palier`, `Au bureau`, `Au café`, `En boutique`, `À la pharmacie`, `Chez le médecin`, `Au cabinet médical`, `Chez le coiffeur`, `À l'atelier`, `Texto · <name>`, `Les copains · groupe`, `WhatsApp · Mme Dumas`, `Appel · <name>`, and for staff `Appel · restaurant`, `Appel · plombier`, `Appel · serrurier`, `Appel · cabinet médical`, `Appel · service client`, `Appel · coiffeur`, `Appel · responsable`, `Texto · responsable`. Standalone labels add « · phrase seule » and match the cue's setting, not the move's home place.
3. **Announcements** are an unnamed server turn with `role: "Annonce"` and `voice: "female"`. A dialogue may then have a second unnamed speaker (the employee) who answers; set `followUpRole` when the follow-up is the employee's.
4. **Numbers stay words** and stay small: *dix, vingt, cinq, huit, deux, trois, midi*. *Neuf, onze, quinze, trente, quarante* are not in `words.json` or *Fondations* answers, so the sketches avoid them.
5. **Feminine keys for Robin.** *Bloquée, absente, obligée, guérie, satisfaite* are keyed in the feminine because Robin's lines need that form; the masculine is an inflection entry (*bloqué* = "stuck", *guéri* = "better, recovered (masculine)"). *Je suis désolée*, *arrivée*, *rentrée* stay base.
6. **Elided forms are separate keys** (lint splits on spaces). So *annuler* is planned bare (*je dois annuler*), never only as *d'annuler*; *eau chaude* is not a key because the lines say *d'eau chaude / l'eau chaude* (*chaude* is a base inflection of *chaud*); *escalier* was dropped for *palier* (*l'escalier* would never show the key); *quart d'heure* is keyed with its elided *d'heure* token; *à cause de* does not match *à cause des / du*, so the sketches use *à cause de la grève* only.
7. **Two keys for one verb on purpose:** *annulé* (11, "cancelled") and *annuler* (13, "to cancel"); *réparer* (12) and *réparation* (15); *prévenir* (11) with *préviens, prévenu* as inflections.
8. **Gloss traps in existing entries** (judge class "glosses wrong in context"). Authors must not write: *ça fait* for "it's been" (glossed "the total comes to"); bare *court* (glossed "runs": 15 uses only the phrase *trop court*, open question 3); bare *carte* (*carte Vitale* is a phrase key); *t'attends* for *tu attends* (glossed "am waiting for you"); *cours* for a class (glossed "run (je, tu)"); *en ligne* for "online" (*ligne* = metro, tram, phone line); *une place* is fine for a seat in a car-share (gloss "place (à la place = instead)"); *mal* outside *j'ai mal* until the base gloss is widened (open question 1); *ouvert* for "opened" (glossed "open").
9. **Phrase keys across a comma.** Never split *tiens au courant, en attendant, dès que possible, commencez sans moi, on remet ça, rien de grave, prends soin de toi, je ne pourrai pas, qu'est-ce qui ne va pas, ça va mieux, il manque, encore une fois, la dernière fois, service client, trop court* with a comma, and don't write « Ça va, mieux… » or « Rien, de grave ».
10. **Keys that must not appear before their module.** Avoid *ne t'inquiète pas* (contains the 13 key *t'inquiète*) in 11–12 and 13 before `wait`; *ça va mieux* before 14 `better`; *annuler* before 13 `cancel` (11 uses *annulé* only, and its distractors are *annulée / annulés*, not *annuler*); *réparer* before 12 `plumber`.
11. **Drafts:** `NN_<slug>_first_half.json` / `_second_half.json`, each with its `_words.json`: `11_greve_et_retards_…, 12_le_logement_…, 13_en_retard_annuler_…, 14_sante_…, 15_ca_ne_marche_pas_…`.

## 3. Move lists

Moves 1–4 go to author agent 1 (first half) and moves 5–8 to author agent 2 (second half). Each new word belongs to the half where it first appears, and its recurrences and Mot drill stay inside its own move, so the halves never depend on each other's drafts. A second-half item that reuses a first-half word copies its entry from the matrix's word table.

### 11 *Grève et retards*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_11_strike` | Il y a grève | 1st | 4 (grève, trafic, perturbé, aucun) | Culture move: *la grève* is part of French life. *Il y a grève* (no article), *le trafic est perturbé*, *aucun métro*. News comes from Léa's texts, the station and the landing. |
| `sit_11_cancelled` | Un train annulé | 1st | 4 (annulé, départ, quai, annonce) | At the station: the announcement, *annulé*, *le prochain départ*, *le quai*. Robin asks staff what happens next. Announcements are an unnamed server turn with role « Annonce ». |
| `sit_11_delay` | Le retard | 1st | 3 (environ, prévu, panneau) | How late? *environ vingt minutes de retard*, *le train est prévu à…*, and *le panneau* (the departures board). *Retard* and *en retard* are base words already glossed. |
| `sit_11_desk` | Au guichet | 1st | 3 (guichet, billet, valable) | At the ticket office: *le guichet*, *mon billet*, *valable*. *Billet* is a train ticket; 08's *ticket* is a receipt or a metro ticket (open question 4). |
| `sit_11_group` | Bloquée ! | 2nd | 3 (bloquée, tiens au courant, covoiturage) | Social move in the group chat: who is stuck where, *je vous tiens au courant*, and Théo's *covoiturage* (car-share: very French, BlaBlaCar culture). Robin is *bloquée* (feminine: Compléter and Corriger target it). |
| `sit_11_another` | Une autre solution | 2nd | 3 (taxi, navette, en attendant) | The metro is on strike: find another way. *Un taxi* (too expensive), *la navette* (replacement shuttle bus), and *en attendant* (in the meantime, a coffee). *À pied* and *à vélo* come back from 02. |
| `sit_11_work` | Prévenir le bureau | 2nd | 3 (prévenir, réunion, en télétravail) | Social move at work: *prévenir* (to let someone know), *la réunion*, and *en télétravail* (working from home, the strike-day reflex). Robin's manager is an unnamed « Responsable » (taught in 08), *vous*. |
| `sit_11_arrive` | Enfin arrivée | 2nd | 3 (enfin, heureusement, ouf) | The end of the day: *enfin*, *heureusement*, and the sigh *ouf*. Robin is *arrivée* (feminine: Corriger targets it). Reacting and sharing relief is the social move. |

### 12 *Le logement*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_12_boiler` | Plus d'eau chaude | 1st | 3 (chaudière, chauffage, radiateur) | The syllabus scene: *la chaudière* is broken, no hot water, *le chauffage* and *le radiateur* are cold. *En panne* (06) and *il fait froid* (03) come back. *Chaude* is a base inflection of *chaud*. |
| `sit_12_leak` | Une fuite | 1st | 3 (fuite, plafond, coule) | *Une fuite*: water *coule* from *le plafond*. The neighbour downstairs (an unnamed « Voisine ») comes up; Robin apologises and tells Mme Dumas. *De l'eau* is a *Fondations* phrase. |
| `sit_12_plumber` | Le plombier | 1st | 3 (plombier, réparer, cet après-midi) | Mme Dumas sends *le plombier*; Robin agrees a time (*cet après-midi*) for him to *réparer* the leak. The plumber is unnamed (role « Plombier », vous). |
| `sit_12_keys` | Les clés | 1st | 3 (à clé, double, serrurier) | Locked out: *j'ai perdu mes clés* is a *Fondations* sentence; new are *fermée à clé* (the phrase *à clé*), M. Ferrand's *double* and *le serrurier*. Kind-underneath Ferrand saves the day. |
| `sit_12_neighbour` | M. Ferrand | 2nd | 3 (prêter, bruit, palier) | Social move with the fussy neighbour: he offers to *prêter* things, complains about *le bruit* from the apéro, and everything happens *sur le palier*. Robin apologises politely (*vous*). |
| `sit_12_broken` | Ça ne marche plus | 2nd | 3 (cassé, machine à laver, lumière) | More breakdowns in the flat: the fridge is *cassé*, *la machine à laver* is *en panne*, *la lumière* doesn't work. Agreement: *cassé / cassée* with the item (Corriger and Compléter target it). |
| `sit_12_landlady` | Écrire à Mme Dumas | 2nd | 4 (déranger, urgent, dès que possible, photo) | Writing to the landlady politely: *désolée de vous déranger*, *c'est urgent*, *une photo*, *dès que possible*. Short, formal WhatsApp French (she is brief). |
| `sit_12_visit` | La visite du plombier | 2nd | 3 (absente, gardienne, boîte aux lettres) | Arranging access while Robin is out: *je serai absente* (feminine: Corriger targets it), *la gardienne* (the building's caretaker) opens the door, the key goes in *la boîte aux lettres*. |

### 13 *Être en retard, annuler*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_13_late` | Prévenir de son retard | 1st | 3 (quart d'heure, commencez sans moi, bouchons) | Warning people you're late: *dans un quart d'heure*, *commencez sans moi* (to a group: *vous* plural), *il y a des bouchons*. *En retard* and *j'arrive* come back. |
| `sit_13_sorry` | S'excuser | 1st | 3 (je m'excuse, faute, promis) | Apologising both ways: *je m'excuse* (everyday, alongside 03's *excusez-moi*), *ce n'est pas ma faute*, and the promise *promis !* Robin is *désolée* (feminine). |
| `sit_13_reason` | Expliquer pourquoi | 1st | 4 (raté, à cause de, réveil, oublié) | Explaining the delay: *j'ai raté le bus*, *mon réveil n'a pas sonné*, *j'ai oublié*, *à cause de la grève*. Passé composé with *avoir*: no agreement with Robin (Corriger targets *ratée*). |
| `sit_13_wait` | Attendre quelqu'un | 1st | 3 (longtemps, presque, t'inquiète) | Now someone else is late: *tu attends depuis longtemps ?*, *je suis presque là*, and the spoken reassurance *t'inquiète* (standard *ne t'inquiète pas*, a *Fondations* phrase; lint change needed, open question 2). |
| `sit_13_cancel` | Annuler | 2nd | 3 (annuler, obligée, empêchement) | Cancelling without offending: *je dois annuler*, *je suis obligée de…* (feminine: Corriger targets it), *j'ai un empêchement* (the polite, vague French reason). Keep *annuler* bare (*je dois annuler*), not *d'annuler*, where it counts as a recurrence. |
| `sit_13_newplan` | Proposer autre chose | 2nd | 3 (on remet ça, un autre jour, on se rattrape) | The social repair after cancelling: *on remet ça ?* (shall we do it another time?), *un autre jour*, *on se rattrape* (we'll make up for it). *Plutôt* and *ça te va ?* come back from 05. |
| `sit_13_react` | Réagir | 2nd | 3 (j'espère, rien de grave, prends soin de toi) | When the other person cancels: *rien de grave, j'espère ?* and *prends soin de toi*. *Dommage*, *pas grave* and *la prochaine fois* (04) come back. Keep *ça va mieux* out (taught in 14). |
| `sit_13_formal` | Reporter un rendez-vous | 2nd | 3 (reporter, je ne pourrai pas, créneau) | The *vous* version: calling the restaurant (09) or the plumber (12) to *reporter* (postpone) a booking or an appointment: *je ne pourrai pas venir*, *un autre créneau*. Futur simple *pourrai* (*Fondations* 21). |

### 14 *Santé*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_14_symptom` | J'ai mal | 1st | 3 (j'ai mal, tête, gorge) | *J'ai mal à la tête / à la gorge*: *avoir mal à* with *à la* / *au*. The phrase key is *j'ai mal*; other persons (*tu as mal*, *vous avez mal*) need the widened base gloss of *mal* (open question 1). |
| `sit_14_cold` | Un rhume | 1st | 3 (rhume, fièvre, toux) | The common cold: *un rhume*, *de la fièvre* (partitive), *de la toux*. Culture: with a cold you skip *la bise* (s02). |
| `sit_14_pharmacy` | À la pharmacie | 1st | 4 (contre, sirop, comprimés, ordonnance) | Culture move: the pharmacist is the first stop. *Quelque chose contre la toux*, *un sirop*, *des comprimés*, *sans ordonnance*. The pharmacy is the one opposite Robin's building (module 10). The pharmacist is an unnamed « Pharmacienne » (vous). |
| `sit_14_advice` | Les conseils | 1st | 3 (reposez-vous, je vous conseille, pendant) | Getting and giving advice: *reposez-vous* (and *Fondations*' *repose-toi*), *je vous conseille de…*, *pendant trois jours*. *Vous* imperatives (*prenez, reposez-vous*) against *tu* (*prends, repose-toi*). |
| `sit_14_appointment` | Prendre rendez-vous | 2nd | 3 (cabinet, docteur, carte vitale) | Calling *le cabinet* (the doctor's surgery): the secretary (unnamed « Secrétaire », vous) offers a time with *le docteur*; don't forget *la carte Vitale* (France's health insurance card: culture). *Rendez-vous* (05), *urgent* (12), *créneau* (13) come back. |
| `sit_14_doctor` | Chez le médecin | 2nd | 3 (qu'est-ce qui ne va pas, ventre, dos) | The consultation: *Qu'est-ce qui ne va pas ?*, *j'ai mal au ventre / au dos* (*au* = *à + le*, Corriger target), *depuis quand ?* (01). The doctor is an unnamed « Médecin » (vous). |
| `sit_14_sick` | Malade | 2nd | 3 (malade, arrêt maladie, bon rétablissement) | Social move: say you're *malade*, send *l'arrêt maladie* (sick note) to work, and wish others *bon rétablissement*. *Arrêt maladie* is its own phrase key, apart from 10's *arrêt* (stop). |
| `sit_14_better` | Ça va mieux | 2nd | 3 (ça va mieux, guérie, en forme) | The happy end: *ça va mieux ?* (new phrase key, apart from 01's *ça va*), *je suis guérie* (feminine: Corriger and Compléter target it), *en forme*. *Mieux* vs *meilleur* (*Fondations* 19). |

### 15 *Ça ne marche pas*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_15_parcel` | Le colis n'arrive pas | 1st | 3 (livré, suivi, service client) | The parcel (*colis*, 10) is marked *livré* but never came: call *le service client* with *le numéro de suivi*. Customer service is an unnamed « Conseillère » (vous). M. Ferrand turns out to have it. |
| `sit_15_wrong` | Ce n'est pas ce que j'ai commandé | 1st | 3 (commandé, il manque, carton) | The wrong or incomplete order: *ce n'est pas ce que j'ai commandé*, *il manque…*, *le carton est abîmé* (*abîmé*, *pull*, *chemise*, *rapporter* come back from 08). Agreement *que j'ai commandé* with *le pull* (masculine). |
| `sit_15_complain` | Se plaindre poliment | 1st | 3 (satisfaite, normal, réclamation) | Polite complaint: *je ne suis pas satisfaite* (feminine: Corriger targets it), *ce n'est pas normal*, *faire une réclamation*. *Rembourser*, *ticket*, *responsable* and *vendeuse* come back from 08. |
| `sit_15_haircut` | Chez le coiffeur | 1st | 4 (coiffeur, cheveux, couper, trop court) | The haircut: *le coiffeur*, *les cheveux*, *couper*, and the complaint *trop court*. Only the phrase *trop court* is a key: a bare *court* would show 02's gloss "runs" (open question 3). The hairdresser is an unnamed « Coiffeuse » (vous). |
| `sit_15_bike` | Le vélo | 2nd | 3 (pneu, crevé, freins) | Robin's bike: *le pneu* is *crevé*, *les freins* don't work. *Réparer* (12) and *en panne* (06) come back. The mechanic is an unnamed « Réparateur » (vous). |
| `sit_15_repair` | À l'atelier | 2nd | 3 (réparation, devis, garantie) | At the repair shop: *la réparation*, *un devis* (a quote, before any work: very French), *la garantie* and the *ticket* (08). Prices are small whole numbers in words. |
| `sit_15_again` | Ça ne marche toujours pas | 2nd | 3 (pareil, encore une fois, la dernière fois) | Going back when it still doesn't work: *ça ne marche toujours pas*, *c'est pareil*, *encore une fois*, *comme la dernière fois*. Firm but polite (*vous*). |
| `sit_15_fix` | Trouver une solution | 2nd | 3 (remplacer, gratuit, proposez) | Getting a fix: *qu'est-ce que vous proposez ?*, *remplacer*, *c'est gratuit* (with the *garantie*), or *rembourser* (08). Robin stays polite and firm. |

## 4. Totals

| Module | New words (1st / 2nd half) | Spoken forms | Dialogues not face to face (of 80) | Channel mix (dialogues) |
|---|---|---|---|---|
| 11 Grève et retards | 26 (14 / 12) | — | 52 | Texto 29, face to face 28, Les copains 12, Appel 10, WhatsApp 1 |
| 12 Le logement | 25 (12 / 13) | — | 53 | face to face 27, Texto 26, WhatsApp 18, Appel 9 |
| 13 Être en retard, annuler | 25 (13 / 12) | 1 | 65 | Texto 34, Appel 15, face to face 15, Les copains 10, WhatsApp 6 |
| 14 Santé | 25 (13 / 12) | — | 40 | face to face 40, Texto 25, Appel 9, WhatsApp 4, Les copains 2 |
| 15 Ça ne marche pas | 25 (13 / 12) | — | 44 | face to face 36, Texto 29, Appel 13, WhatsApp 2 |
| **Arc 3 (11–15)** | **126** | **1** | **254 of 400** | |

The arc is about things going wrong between people, so it leans on texts, the group chat, WhatsApp with Mme Dumas and calls (13 most of all); the station (11), the pharmacy and the surgery (14) and the shop, hairdresser and workshop (15) keep the face-to-face scenes. Every move has 4–8 of its 10 dialogues off its home channel (the most frequent channel). The one new spoken form is *t'inquiète* (13 `wait`; open question 2); the *tu* exchanges reuse *t'es, t'as, ouais, top, bref, pas de souci* from arcs 1–2. Per move, every new word recurs in at least two later dialogues of the same move and gets a later Mot or Mot en retour drill; no item introduces more than two new words.

## 5. Cross-module word progression

Each word is taught once, in the earliest module that needs it. Later modules reuse it freely and never put it back in `newWords`. The right column counts any later use, distractors included.

| Module | Words taught (book-wide first) | Carried into later arc-3 modules |
|---|---|---|
| 11 | *grève*; *trafic*; *perturbé*; *aucun*; *annulé*; *départ*; *quai*; *annonce*; *environ*; *prévu*; *panneau*; *guichet*; *billet*; *valable*; *bloquée*; *tiens au courant*; *covoiturage*; *taxi*; *navette*; *en attendant*; *prévenir*; *réunion*; *en télétravail*; *enfin*; *heureusement*; *ouf* | *grève* (13); *annulé* (13); *quai* (12, 15); *panneau* (12); *guichet* (12, 15); *billet* (14); *prévenir* (12); *réunion* (13, 14, 15); *enfin* (12, 15); *heureusement* (14) |
| 12 | *chaudière*; *chauffage*; *radiateur*; *fuite*; *plafond*; *coule*; *plombier*; *réparer*; *cet après-midi*; *à clé*; *double*; *serrurier*; *prêter*; *bruit*; *palier*; *cassé*; *machine à laver*; *lumière*; *déranger*; *urgent*; *dès que possible*; *photo*; *absente*; *gardienne*; *boîte aux lettres* | *chaudière* (15); *plombier* (13); *réparer* (15); *machine à laver* (15); *urgent* (14); *gardienne* (15) |
| 13 | *quart d'heure*; *commencez sans moi*; *bouchons*; *je m'excuse*; *faute*; *promis*; *raté*; *à cause de*; *réveil*; *oublié*; *longtemps*; *presque*; *t'inquiète*; *annuler*; *obligée*; *empêchement*; *on remet ça*; *un autre jour*; *on se rattrape*; *j'espère*; *rien de grave*; *prends soin de toi*; *reporter*; *je ne pourrai pas*; *créneau* | *faute* (15); *t'inquiète* (14); *rien de grave* (14); *prends soin de toi* (14) |
| 14 | *j'ai mal*; *tête*; *gorge*; *rhume*; *fièvre*; *toux*; *contre*; *sirop*; *comprimés*; *ordonnance*; *reposez-vous*; *je vous conseille*; *pendant*; *cabinet*; *docteur*; *carte vitale*; *qu'est-ce qui ne va pas*; *ventre*; *dos*; *malade*; *arrêt maladie*; *bon rétablissement*; *ça va mieux*; *guérie*; *en forme* | — |
| 15 | *livré*; *suivi*; *service client*; *commandé*; *il manque*; *carton*; *satisfaite*; *normal*; *réclamation*; *coiffeur*; *cheveux*; *couper*; *trop court*; *pneu*; *crevé*; *freins*; *réparation*; *devis*; *garantie*; *pareil*; *encore une fois*; *la dernière fois*; *remplacer*; *gratuit*; *proposez* | — |

**Vocabulary audit** (each new key grepped against the answer sentences in `Resources/Topics/*.json` and against every line printed in 01–10): none of the 126 keys is in *Fondations* or printed earlier. *Fondations* words the arc builds on stay **base** (glossed, never underlined): *train, bus, clés* (« j'ai perdu mes clés »), *eau, froid, chaud, médecin* (« elle est chez le médecin »), *repose-toi, buvez, ne t'inquiète pas* (20), *bientôt, pourquoi, parce que, fatigué(e), voiture, demain, la semaine prochaine, vite, rien*. *Retard / en retard*, *autre*, *prochain(e)*, *dernier / dernière*, *prêt / prête*, *revenir* are already base entries in `words.json`.

## 6. Words moved between modules, avoided or deferred

- **From café, arc 1 or arc 2: none moved.** No earlier entry changes, except the optional gloss widenings in open questions 1 and 3 (*mal*, *court*).
- **Within the batch** (taught once, reused later; see §5): *annulé* (11 → 13 alongside the new *annuler*), *prévenir* (11 → 12), *réunion* (11 → 13–15), *enfin* (11 → 12, 15), *heureusement* (11 → 14), *plombier* (12 → 13 `formal`), *réparer* and *machine à laver* (12 → 15), *urgent* (12 → 14), *t'inquiète, rien de grave, prends soin de toi* (13 → 14), *faute* (13 → 15 as a distractor).
- **Dropped because 01–10 already print them** (a taught key would fail the book-order lint): *toute la journée* (07 « fermé toute la journée »; still usable as base words), *combien de temps* (02), *à l'heure* (matches inside 01's *à tout à l'heure*), *prends ton temps* (05). 11 `strike` teaches *aucun* instead of *toute la journée*.
- **Avoided:** *y a* (spoken; matches inside *il y a*), *je veux bien*, *galère* (kept for 17 *Une galère*), *coucou, nul, truc, hein, oups* (untaught, slangy), *escalier* (elided), *douche, partout, mouillé, sous, juste, remboursement, atelier, réparateur, pharmacien(ne), chef* in lines (untaught; the last three appear only as role or place labels), the numbers *neuf, onze, quinze, trente, quarante*.
- **Deferred:** *galère* (17), *raconter* past narration (16), comparison of flats and phone plans (18).

## 7. Grammar recycled from *Fondations*

Book 1 module numbers are in brackets.

- **11:** *il y a* + noun without article (*il y a grève*) and *aucun* + noun (05 negation); agreement of past participles used as adjectives (*perturbé / perturbée*, *annulé / annulée*, *prévu / prévue*, 07); passé composé with *être* (« le train est parti », and Robin's feminine *je suis arrivée / rentrée*, 14); futur proche (« je vais être en retard », « je vais échanger mon billet », 12); questions with *quel / quelle / à quelle heure / quand* (06); *vous* and *tu* imperatives (*prenez / prends*, *revenez*, 20); object pronouns *je te tiens / je vous tiens au courant*, *je la fais* (17); quantity + *de* (*vingt minutes de retard*, 11); *en* + transport or state (*en navette, en télétravail*) against *à pied / à vélo* (10).
- **12:** negation *ne… pas / ne… plus / pas de* (« il n'y a pas d'eau chaude », « la machine à laver ne marche plus », 05); partitive *de l'eau* (11); adjective agreement with the item (*cassé / cassée*, *froid*, 07) and Robin's feminine *absente*; object pronouns *je le prends*, *je lui laisse*, *je vous envoie*, *me prêter* (17); imparfait for a past state (« il y avait une fuite », « la lumière ne marchait pas », 16); futur proche (« il va réparer », « je vais laisser », 12); futur simple *je serai là / absente* (21); *vous pouvez* + infinitive for polite requests (22); *de + le = du* (« du plafond », « la lumière du palier », 10); possessives *mon / ma / mes, votre / vos* (08).
- **13:** passé composé with *avoir*, no agreement with Robin (*j'ai raté*, *j'ai oublié*; Corriger on *ratée*, 13); negative passé composé (« mon réveil n'a pas sonné », 13); futur simple *je ne pourrai pas*, *je serai là* (21); *devoir* + infinitive (*je dois annuler*); pronominal verbs *je m'excuse*, *on se rattrape*, *on se voit*, *te reposer* (15); *tu / vous* imperatives *commence / commencez sans moi*, *prends soin de toi / prenez soin de vous*, *ne t'inquiète pas* (20); *parce que / à cause de / pourquoi* (06); *depuis* + duration (« depuis longtemps », 10); *être obligée de* + infinitive (Robin, feminine).
- **14:** *avoir mal à* with *à la / au* (*à + le = au*, Corriger on *à le ventre*, 10); partitive *de la fièvre, de la toux, de l'eau* (11); *vous* imperatives *reposez-vous, prenez, buvez* against *tu* *repose-toi, prends* (20); object pronouns *je le prends*, *je l'apporte*, *la voilà* (17); *pendant* vs *depuis* + duration; *mieux / meilleur* (« ça va mieux », Compléter against *meilleur*, 19); *qu'est-ce qui ne va pas ?* (06); *je vous conseille de* + infinitive; imparfait *j'avais de la fièvre* (16); Robin's feminine *guérie* (Corriger on *guéri*).
- **15:** passé composé with *avoir* and agreement with a preceding direct object (« le pull que j'ai commandé », 13 and 23 relative *que*); impersonal *il manque* + noun; negation *ne… toujours pas*, *ne… rien* (05); adjective agreement *satisfaite* (Robin), *abîmé, crevé, gratuit, pareil, normal* (07); object pronouns *je vous le donne*, *je vais les réparer*, *on peut vous rembourser* (17); comparison *pareil que*, *le même* (19); *qu'est-ce que vous proposez ?* (06); futur proche (« ils vont me rembourser », 12); imparfait *c'était* (16).

## 8. Shared base glosses (copy byte for byte)

Arc 1 had 33 gloss conflicts at assembly; arc 2 cut them by giving authors this section. Give it to every author. It has three parts.

### 8.1 Existing `words.json` entries the sketches use in two or more halves

Copied from `words.json`. The last column is the halves whose sketches use the entry (11a = module 11 first half). Copy the entry exactly; never edit it in a draft. Entries used by only one half are not listed: look them up in `words.json`.

| fr | en | spoken | audio | Used by |
|---|---|---|---|---|
| a | has |  | `sitw_a` | 11a, 12a, 12b, 13b, 14a, 14b, 15a, 15b |
| abîmé | damaged |  | `sitw_abime` | 15a, 15b |
| ah | ah / oh |  | `sitw_ah` | 11b, 12b, 13a, 15a, 15b |
| ah bon | oh really? |  | `sitw_ah_bon` | 11a, 14a |
| aller | to go |  | `sitw_aller` | 14a, 14b |
| alors | so / then |  | `sitw_alors` | 11a, 11b, 12a, 13b, 14a, 15a, 15b |
| appeler | to call |  | `sitw_appeler` | 12a, 12b, 14b, 15a |
| appelle | call / calls |  | `sitw_appelle` | 12b, 15a |
| arrive | is coming / arrives |  | `sitw_arrive` | 11b, 15a |
| arrives | arrive (tu) |  | `sitw_arrives` | 11a, 11b, 13a |
| as | have |  | `sitw_as` | 11a, 12a, 13a, 13b, 14a, 14b, 15a, 15b |
| attend | waits, is waiting |  | `sitw_attend` | 11a, 13a |
| attendre | to wait |  | `sitw_attendre` | 11a, 11b, 12b, 13a |
| attends | wait |  | `sitw_attends` | 11a, 13a |
| au | at the / to the |  | `sitw_au` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| aujourd'hui | today |  | `sitw_aujourd_hui` | 11a, 11b, 12a, 14a, 14b, 15a, 15b |
| aussi | also / too |  | `sitw_aussi` | 11b, 12a, 12b, 14a, 15b |
| autre | other |  | `sitw_autre` | 11a, 13b |
| avant | before |  | `sitw_avant` | 11b, 14b |
| avec | with |  | `sitw_avec` | 11a, 11b, 12b, 13b, 14a, 14b, 15a, 15b |
| avez | have |  | `sitw_avez` | 11a, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| beaucoup | a lot / very much |  | `sitw_beaucoup` | 11a, 12a, 12b, 14a, 14b, 15a, 15b |
| bien | well / good / indeed |  | `sitw_bien` | 11b, 14a, 14b, 15a, 15b |
| bien sûr | of course |  | `sitw_bien_sur` | 11b, 12b, 13b, 14a |
| bon | well / OK (also: good, happy) |  | `sitw_bon` | 11a, 14a, 15a |
| bonjour | hello |  | `sitw_bonjour` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| bonne | good (feminine) |  | `sitw_bonne` | 11b, 14a |
| bref | anyway | yes | `sitw_bref` | 11a, 11b, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| bureau | office / desk |  | `sitw_bureau` | 11a, 11b, 12a, 12b, 13b, 14a, 14b, 15b |
| bus | bus |  | `sitw_bus` | 11b, 13a |
| c'est | it is |  | `sitw_c_est` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| c'est noté | noted |  | `sitw_c_est_note` | 13b, 14a |
| c'était | it was |  | `sitw_c_etait` | 12b, 15b |
| café | coffee / café |  | `sitw_cafe` | 11a, 11b, 13a, 14a, 14b |
| ce | this / that |  | `sitw_ce` | 12b, 13a, 13b, 14a, 15a, 15b |
| ce matin | this morning |  | `sitw_ce_matin` | 11a, 12a, 12b, 14a, 14b |
| ce soir | this evening |  | `sitw_ce_soir` | 11a, 11b, 12b, 13a, 13b, 14a |
| cette | this (feminine) |  | `sitw_cette` | 11a, 13b, 14a |
| chaud | hot / warm |  | `sitw_chaud` | 12a, 14a |
| cher | expensive, dear |  | `sitw_cher` | 11b, 12a, 15a, 15b |
| chez | at (someone's place) |  | `sitw_chez` | 11b, 12a, 12b, 14b, 15a |
| chez vous | at your place / at home (vous) |  | `sitw_chez_vous` | 12a, 12b, 15a |
| chère | expensive (feminine) |  | `sitw_chere` | 11b, 15b |
| cinq | five |  | `sitw_cinq` | 11a, 13a, 14a |
| cinéma | cinema, the movies |  | `sitw_cinema` | 13a, 13b |
| clés | keys |  | `sitw_cles` | 12a, 12b, 13a |
| colis | parcel |  | `sitw_colis` | 12b, 14b, 15a, 15b |
| combien | how much / how many |  | `sitw_combien` | 11a, 11b, 14a, 14b, 15a, 15b |
| comme d'habitude | as usual |  | `sitw_comme_d_habitude` | 14a, 14b, 15a |
| comment | how |  | `sitw_comment` | 11b, 14a, 15a |
| cuisine | kitchen / cook(s) |  | `sitw_cuisine` | 12a, 12b |
| d'accord | OK, agreed |  | `sitw_d_accord` | 11a, 11b, 12b, 13a, 14a, 14b, 15b |
| dans | in |  | `sitw_dans` | 11a, 11b, 12a, 12b, 13a, 14a, 14b, 15a |
| de | of / from |  | `sitw_de` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| demain | tomorrow |  | `sitw_demain` | 11a, 11b, 12a, 12b, 13a, 13b, 14b, 15a, 15b |
| depuis | since / for |  | `sitw_depuis` | 11a, 12a, 12b, 13a, 14a, 14b |
| depuis quand | since when / how long |  | `sitw_depuis_quand` | 13a, 14b |
| des | some |  | `sitw_des` | 11b, 12a, 12b, 13a, 14a, 15a |
| deux | two |  | `sitw_deux` | 11a, 11b, 14a, 14b, 15b |
| devant | in front of, outside |  | `sitw_devant` | 11b, 12a, 12b, 15a |
| dimanche | Sunday |  | `sitw_dimanche` | 12b, 13b, 14b |
| dit | says / said |  | `sitw_dit` | 11a, 12b, 14a, 14b, 15a |
| dix | ten |  | `sitw_dix` | 11a, 11b, 12a, 12b, 13a, 14b, 15a |
| dommage | what a shame |  | `sitw_dommage` | 11b, 13b, 14b |
| donne | give / gives |  | `sitw_donne` | 14b, 15a |
| du | some / of the |  | `sitw_du` | 11a, 11b, 12a, 12b, 13a, 14a, 14b |
| désolé | sorry |  | `sitw_desole` | 12b, 13a, 13b |
| désolée | sorry (feminine) |  | `sitw_desolee` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 15b |
| dîner | dinner |  | `sitw_diner` | 13a, 13b |
| elle | she / it |  | `sitw_elle` | 11b, 12a, 12b, 13b, 14b |
| en | in, by / some, of it (pronoun) |  | `sitw_en` | 11a, 11b, 12a, 13a, 13b, 14b |
| en panne | broken / out of order |  | `sitw_en_panne` | 12a, 12b, 15b |
| en retard | late |  | `sitw_en_retard` | 11a, 11b, 13a, 15b |
| encore | still / again / more |  | `sitw_encore` | 11a, 11b, 12a, 12b, 13a, 14a, 14b, 15a, 15b |
| ensemble | together |  | `sitw_ensemble` | 11b, 13b |
| es | are (tu) |  | `sitw_es` | 11b, 12a, 13a, 13b, 14b, 15a, 15b |
| est | is |  | `sitw_est` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| et | and |  | `sitw_et` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| euros | euros |  | `sitw_euros` | 11b, 15b |
| excusez-moi | sorry / excuse me (vous) |  | `sitw_excusez_moi` | 11a, 11b, 13a, 14a, 15b |
| fais | do / make (je, tu) |  | `sitw_fais` | 11b, 14a, 15a, 15b |
| fait | does / makes / comes to |  | `sitw_fait` | 11b, 12b, 13b, 15a, 15b |
| fatiguée | tired (feminine) |  | `sitw_fatiguee` | 12a, 13b, 14b |
| faut | (il faut) you have to, you need |  | `sitw_faut` | 11b, 13a, 14a |
| ferme | closes, shuts |  | `sitw_ferme_verb` | 11a, 14b |
| ferrand | Ferrand (surname) |  | `sitw_ferrand` | 12a, 12b, 15a |
| fois | time (one time, twice…) |  | `sitw_fois` | 13a, 14a, 14b, 15b |
| froid | cold |  | `sitw_froid` | 12a, 14a, 15a |
| froide | cold (feminine) |  | `sitw_froide` | 12a, 14a |
| gare | station |  | `sitw_gare` | 11a, 11b, 14a, 15a |
| gentil | kind |  | `sitw_gentil` | 12a, 12b, 13b, 14a, 14b, 15b |
| gentille | kind (feminine) |  | `sitw_gentille` | 12a, 12b, 13b, 14a, 14b, 15b |
| gentils | kind (plural) |  | `sitw_gentils` | 12a, 13b, 14a, 14b, 15b |
| heure | hour / o'clock |  | `sitw_heure` | 11a, 12a, 13a |
| heures | o'clock / hours |  | `sitw_heures` | 11a, 11b, 12a, 12b, 13a, 13b, 14b, 15a |
| hier | yesterday |  | `sitw_hier` | 12a, 12b, 13b, 14a, 14b, 15a |
| huit | eight |  | `sitw_huit` | 11a, 11b, 13a |
| idée | idea |  | `sitw_idee` | 11b, 14a |
| il | he / it |  | `sitw_il` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| il y a | there is / there are |  | `sitw_il_y_a` | 11a, 11b, 12a, 12b, 13a, 15a, 15b |
| ils | they |  | `sitw_ils` | 15a, 15b |
| j'ai | I have |  | `sitw_j_ai` | 12a, 13a, 13b, 14a, 14b, 15a, 15b |
| j'arrive | I'm on my way, I'm coming |  | `sitw_j_arrive` | 11b, 12a, 13a |
| j'attends | I'm waiting, I wait |  | `sitw_j_attends` | 11a, 12a, 14b |
| jamais | never |  | `sitw_jamais` | 12b, 15a |
| je | I |  | `sitw_je` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| je crois | I think |  | `sitw_je_crois` | 11a, 12b |
| je peux | I can |  | `sitw_je_peux` | 11a, 11b, 12a, 12b, 13b, 14a, 14b, 15a, 15b |
| je prends | I'll have / I take |  | `sitw_je_prends` | 11b, 13a, 14a |
| je reste | I'm staying |  | `sitw_je_reste` | 11b, 13b, 14a, 14b |
| je voudrais | I would like |  | `sitw_je_voudrais` | 13b, 14a, 14b, 15a, 15b |
| je vous attends | I'm waiting for you (vous) |  | `sitw_je_vous_attends` | 12b, 13a |
| je vous remercie | thank you (formal) |  | `sitw_je_vous_remercie` | 13a, 14a |
| jeudi | Thursday |  | `sitw_jeudi` | 13b, 14b |
| jour | day |  | `sitw_jour` | 13b, 14a |
| journée | day |  | `sitw_journee` | 11a, 12b |
| jours | days |  | `sitw_jours` | 14a, 14b |
| jusqu'à | until, as far as |  | `sitw_jusqu_a` | 11a, 12b |
| l'eau | the water, water |  | `sitw_l_eau` | 12a, 12b, 14a |
| la | the (feminine) / it, her |  | `sitw_la` | 11a, 11b, 12a, 12b, 13a, 14a, 14b, 15a, 15b |
| la prochaine fois | next time |  | `sitw_la_prochaine_fois` | 12b, 13b |
| le | the (masculine) / it, him |  | `sitw_le` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| les | the (plural) / them |  | `sitw_les` | 11b, 12b, 13a, 14b, 15a, 15b |
| lit | bed |  | `sitw_lit` | 13b, 14a, 14b |
| livreur | delivery driver |  | `sitw_livreur` | 12a, 12b, 15a |
| lui | (to) him / her |  | `sitw_lui` | 11b, 12a, 12b |
| lundi | Monday |  | `sitw_lundi` | 12b, 14a, 14b |
| là | there / here |  | `sitw_la_there` | 11b, 12a, 12b, 13a, 13b, 14b |
| léa | Léa |  | `sitw_lea` | 12a, 12b, 13a, 14a, 14b |
| M. | Mr |  | `sitw_m` | 12a, 12b, 15a |
| ma | my (feminine) |  | `sitw_ma` | 12a, 13a, 13b, 15a, 15b |
| madame | madam / Mrs |  | `sitw_madame` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| mais | but |  | `sitw_mais` | 11a, 12a, 12b, 13a, 14b, 15a, 15b |
| mal | bad / badly |  | `sitw_mal` | 14a, 14b |
| malheureusement | unfortunately |  | `sitw_malheureusement` | 11b, 14b |
| marche | works (ça marche = that works) |  | `sitw_marche` | 11a, 11b, 12a, 12b, 15b |
| marches | work (tu) |  | `sitw_marches` | 11a, 12a |
| matin | morning |  | `sitw_matin` | 11a, 12a, 13b, 14a |
| me | me |  | `sitw_me` | 11b, 12b, 14a, 14b, 15a, 15b |
| merci | thank you |  | `sitw_merci` | 11a, 11b, 12a, 12b, 13b, 14a, 14b, 15a, 15b |
| merci de | please (+ verb, formal) |  | `sitw_merci_de` | 11b, 14a |
| mes | my (plural) |  | `sitw_mes` | 12a, 15a |
| midi | noon, lunchtime |  | `sitw_midi` | 11a, 13b, 14b |
| minutes | minutes |  | `sitw_minutes` | 11a, 11b, 12a, 13a |
| mme dumas | Mrs Dumas |  | `sitw_mme_dumas` | 12a, 12b |
| moi | me |  | `sitw_moi` | 11b, 12a, 12b, 13a, 14a, 15a |
| moi aussi | me too |  | `sitw_moi_aussi` | 11a, 11b, 13b |
| mon | my (masculine, or before a vowel) |  | `sitw_mon` | 11a, 12a, 12b, 13a, 13b, 14b, 15a, 15b |
| monsieur | sir / Mr |  | `sitw_monsieur` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15b |
| métro | underground, subway |  | `sitw_metro` | 11a, 11b, 13a |
| même | same / even |  | `sitw_meme` | 13b, 15b |
| n'est | is (not) |  | `sitw_n_est` | 13a, 14b, 15a, 15b |
| ne | not (with pas) |  | `sitw_ne` | 11a, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| non | no / right? |  | `sitw_non` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| noter | to note (down) |  | `sitw_noter` | 13b, 14a |
| notre | our |  | `sitw_notre` | 11a, 13a, 13b |
| noté | noted |  | `sitw_note_past` | 13b, 14a |
| notée | noted (feminine) |  | `sitw_notee` | 13b, 14a |
| nous | we / us |  | `sitw_nous` | 12a, 12b, 15a |
| nouveau | new |  | `sitw_nouveau` | 13b, 15b |
| oh | oh |  | `sitw_oh` | 11a, 11b, 12a, 13b, 14a, 14b, 15a, 15b |
| on | we / one | yes | `sitw_on` | 11a, 11b, 12a, 12b, 13a, 13b, 14b, 15a, 15b |
| on se voit | shall we meet? / we'll see each other |  | `sitw_on_se_voit` | 13a, 13b |
| on va | let's go / we're going |  | `sitw_on_va` | 11a, 11b |
| ou | or |  | `sitw_ou` | 11b, 12a, 12b, 13b, 14a, 15b |
| ouais | yeah | yes | `sitw_ouais` | 11a, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| oui | yes |  | `sitw_oui` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| où | where |  | `sitw_ou_where` | 11a, 11b, 12a, 12b, 13a, 14b, 15a, 15b |
| par | by / per |  | `sitw_par` | 11b, 13a, 14a, 14b |
| pardon | sorry / excuse me |  | `sitw_pardon` | 11a, 11b, 12a, 12b, 13a |
| parfait | perfect |  | `sitw_parfait` | 12a, 13b, 14b, 15b |
| parfaite | perfect (feminine) |  | `sitw_parfaite` | 13b, 14b, 15b |
| parfaits | perfect (plural) |  | `sitw_parfaits` | 13b, 14b, 15b |
| paris | Paris |  | `sitw_paris` | 11a, 11b |
| part | leaves |  | `sitw_part` | 11a, 11b |
| pas | not |  | `sitw_pas` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| pas de problème | no problem |  | `sitw_pas_de_probleme` | 12b, 13a, 13b |
| pas de souci | no worries | yes | `sitw_pas_de_souci` | 11b, 13a, 13b |
| pas grave | no big deal, never mind |  | `sitw_pas_grave` | 11a, 12a, 13a, 13b |
| pas trop | not really, not too much |  | `sitw_pas_trop` | 12b, 15a |
| passe | drop by |  | `sitw_passe` | 12a, 12b |
| passé | past / passed |  | `sitw_passe_past` | 12a, 12b |
| petit | small (masculine) |  | `sitw_petit` | 14a, 15a |
| peut | can |  | `sitw_peut` | 12a, 12b, 13b, 14a, 14b, 15b |
| peux | can (je / tu) |  | `sitw_peux` | 12a, 12b, 13b, 14a, 14b |
| pharmacie | chemist's, pharmacy |  | `sitw_pharmacie` | 12b, 14a, 14b |
| place | place (à la place = instead) |  | `sitw_place` | 11b, 12b |
| plus | more / most / no more |  | `sitw_plus` | 12b, 13b, 15b |
| plutôt | rather, instead |  | `sitw_plutot` | 13a, 13b |
| porte | door |  | `sitw_porte` | 12a, 12b, 14a, 15a |
| pour | for |  | `sitw_pour` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| pouvoir | to be able to |  | `sitw_pouvoir` | 12b, 14a |
| prend | takes |  | `sitw_prend` | 11b, 12b, 13a, 14a |
| prendre | to have / to take |  | `sitw_prendre` | 11b, 12b, 13a, 14a |
| prends | take |  | `sitw_prends` | 11a, 11b, 12b, 13a, 14a |
| prenez | take (vous) |  | `sitw_prenez` | 11b, 13b, 14a, 14b |
| problème | problem |  | `sitw_probleme` | 12a, 12b, 13b, 15a, 15b |
| prochain | next |  | `sitw_prochain` | 11a, 13a, 14b |
| prêt | ready |  | `sitw_pret` | 13a, 15b |
| pull | jumper, sweater |  | `sitw_pull` | 15a, 15b |
| qu'est-ce que | what |  | `sitw_qu_est_ce_que` | 14a, 15b |
| quand | when |  | `sitw_quand` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| que | that / which |  | `sitw_que` | 13a, 13b, 14a, 15a, 15b |
| quel | which / what |  | `sitw_quel` | 11a, 12a, 13b |
| quelle | which / what (feminine) |  | `sitw_quelle` | 11a, 12a |
| quelque chose | something |  | `sitw_quelque_chose` | 14a, 15a |
| quoi | what (informal) |  | `sitw_quoi` | 12a, 14a, 14b, 15a, 15b |
| regarde | watch / look (at) |  | `sitw_regarde` | 12a, 15b |
| regarder | to watch |  | `sitw_regarder` | 12a, 15a, 15b |
| rembourser | to refund, pay back |  | `sitw_rembourser` | 15a, 15b |
| rendez-vous | appointment, meeting / let's meet |  | `sitw_rendez_vous` | 13a, 13b, 14b, 15a |
| restaurant | restaurant |  | `sitw_restaurant` | 13a, 13b, 15a |
| reste | stay(s) / remains |  | `sitw_reste` | 11b, 13b, 14b |
| rester | to stay |  | `sitw_rester` | 11b, 13b, 14a, 14b |
| restes | stay (tu) |  | `sitw_restes` | 13b, 14b |
| retard | delay (en retard = late) |  | `sitw_retard` | 11a, 13a |
| rien | nothing |  | `sitw_rien` | 12b, 15a |
| robin | Robin |  | `sitw_robin` | 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a |
| réservation | booking, reservation |  | `sitw_reservation` | 11b, 13b, 15a |
| s'il te plaît | please (to a friend) |  | `sitw_s_il_te_plait` | 12a, 14a |
| s'il vous plaît | please (vous) |  | `sitw_s_il_vous_plait` | 11a, 11b, 12a, 13b, 14a, 14b, 15a, 15b |
| sais | know (je, tu) |  | `sitw_sais` | 11b, 12a, 13a |
| salle de bains | bathroom |  | `sitw_salle_de_bains` | 12a, 12b, 14a |
| salut | hi / bye (informal, tu) |  | `sitw_salut` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| samedi | Saturday |  | `sitw_samedi` | 11b, 12b, 13a, 13b, 14b, 15a |
| sans | without |  | `sitw_sans` | 11b, 13a, 14a |
| semaine | week |  | `sitw_semaine` | 13b, 14b |
| sera | will be |  | `sitw_sera` | 11b, 12a |
| serai | will be (je) |  | `sitw_serai` | 11b, 12a, 13a |
| seras | will be (tu) |  | `sitw_seras` | 11b, 12a |
| si | if / yes (to a negative) |  | `sitw_si` | 11b, 13b |
| soir | evening |  | `sitw_soir` | 12b, 13b, 14a, 14b |
| sont | are (plural) |  | `sitw_sont` | 15a, 15b |
| suis | am |  | `sitw_suis` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| super | great |  | `sitw_super` | 11a, 11b, 12a, 12b, 15b |
| sur | on / about |  | `sitw_sur` | 11a, 12a, 12b, 13a, 14b |
| t'a | has … you |  | `sitw_t_a` | 14b, 15a |
| t'aider | help you |  | `sitw_t_aider` | 11b, 15b |
| t'as | you have (tu as) | yes | `sitw_t_as` | 11a, 11b, 12a, 12b, 13a, 14a, 14b, 15a, 15b |
| t'attend | waits for you, is waiting for you |  | `sitw_t_attend` | 11b, 13a |
| t'es | you are (tu es) | yes | `sitw_t_es` | 11a, 11b, 12a, 13a, 13b, 14b, 15a, 15b |
| ta | your (informal, feminine) |  | `sitw_ta` | 12b, 13a, 14a, 14b, 15a, 15b |
| tard | late |  | `sitw_tard` | 11b, 13b, 15a |
| te | you (informal) |  | `sitw_te` | 11b, 13a, 14a, 14b, 15a |
| temps | time / weather |  | `sitw_temps` | 13a, 13b |
| tes | your (informal, plural) |  | `sitw_tes` | 12a, 13a, 15a, 15b |
| thé | tea |  | `sitw_the` | 14a, 14b |
| théo | Théo |  | `sitw_theo` | 11b, 13a, 13b |
| ticket | receipt, ticket |  | `sitw_ticket` | 15a, 15b |
| toi | you (informal) |  | `sitw_toi` | 11b, 12b, 13a |
| ton | your (informal) |  | `sitw_ton` | 11a, 11b, 12b, 13a, 14a, 14b, 15a, 15b |
| top | great | yes | `sitw_top` | 11b, 13b, 14a, 15b |
| toujours | still / always |  | `sitw_toujours` | 12a, 13a, 15b |
| tout de suite | right away |  | `sitw_tout_de_suite` | 11b, 12a, 12b, 15a |
| toute | all (feminine) |  | `sitw_toute` | 11a, 12b |
| train | train |  | `sitw_train` | 11a, 11b, 13a |
| tram | tram |  | `sitw_tram` | 11a, 13a |
| travaille | work / works |  | `sitw_travaille` | 11a, 11b, 13b |
| trois | three |  | `sitw_trois` | 11a, 14a, 14b, 15a |
| trop | too / too much |  | `sitw_trop` | 11b, 12b, 13a, 13b, 15a, 15b |
| très | very |  | `sitw_tres` | 11a, 12a, 12b, 14a, 15a, 15b |
| tu | you (friend) |  | `sitw_tu` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| tu peux | can you (tu) |  | `sitw_tu_peux` | 11b, 12a, 12b, 13b, 15a, 15b |
| un | a / one |  | `sitw_un` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| un peu | a little |  | `sitw_un_peu` | 12a, 13b, 14a, 15a |
| une | a / one |  | `sitw_une` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 15a, 15b |
| va | goes / go! (tu) / is going to / is doing / suits |  | `sitw_va` | 11a, 12a, 13b, 14a |
| vais | go / am going |  | `sitw_vais` | 11a, 11b, 12b, 13a, 13b, 14a, 14b, 15b |
| vas | go / are doing (tu) |  | `sitw_vas` | 11a, 13b, 15a |
| vendredi | Friday |  | `sitw_vendredi` | 11a, 12b |
| venez | come (vous) |  | `sitw_venez` | 12a, 14b |
| venir | to come |  | `sitw_venir` | 11b, 12a, 12b, 13b |
| vers | around (a time) |  | `sitw_vers` | 11a, 12a, 12b, 14b |
| viens | come (je / tu) |  | `sitw_viens` | 11a, 11b, 12a, 12b, 13b, 14a, 14b, 15b |
| vient | comes / is coming |  | `sitw_vient` | 12a, 12b |
| vingt | twenty |  | `sitw_vingt` | 11a, 11b, 13a, 13b, 15b |
| vite | quick / quickly |  | `sitw_vite` | 11a, 12a, 14b, 15b |
| voilà | here is / here you are / there you go |  | `sitw_voila` | 11a, 13a, 14b, 15a, 15b |
| vont | go (ils, elles) |  | `sitw_vont` | 15a, 15b |
| vos | your (plural, or polite) |  | `sitw_vos` | 12a, 15a |
| votre | your (polite) |  | `sitw_votre` | 11a, 12a, 12b, 13b, 14b, 15a, 15b |
| voulez | want (polite) |  | `sitw_voulez` | 13b, 14a, 15a |
| vous | you (polite / plural) |  | `sitw_vous` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a, 15b |
| vous pouvez | can you (polite) |  | `sitw_vous_pouvez` | 12a, 12b, 13b, 15a, 15b |
| vu | seen |  | `sitw_vu` | 11a, 11b, 12a, 12b, 13a, 14b, 15a |
| vélo | bike |  | `sitw_velo` | 12b, 14b, 15b |
| week-end | weekend |  | `sitw_week_end` | 12b, 13b, 14b |
| y | there |  | `sitw_y` | 12a, 12b |
| à | to / at |  | `sitw_a_prep` | 11a, 11b, 12a, 12b, 13a, 13b, 14a, 14b, 15a |
| à côté | nearby / next door / next to |  | `sitw_a_cote` | 13a, 14b, 15a |
| à la maison | at home |  | `sitw_a_la_maison` | 11a, 11b, 13a, 13b, 14a |
| à pied | on foot |  | `sitw_a_pied` | 11a, 11b, 15b |
| à quelle heure | at what time |  | `sitw_a_quelle_heure` | 11a, 11b, 12a, 15b |
| à vélo | by bike |  | `sitw_a_velo` | 11a, 15b |
| ça | that / it |  | `sitw_ca` | 12a, 12b, 13a, 14a, 15a, 15b |
| ça fait | the total comes to |  | `sitw_ca_fait` | 13b, 14a |
| ça va | how are you? / I'm fine |  | `sitw_ca_va` | 12a, 13a, 13b, 14a, 14b, 15a, 15b |
| écoute | listen / listens |  | `sitw_ecoute` | 15a, 15b |
| était | was |  | `sitw_etait` | 11a, 12b |
| êtes | are (vous) |  | `sitw_etes` | 11b, 12a, 12b, 13b, 14a, 14b, 15a, 15b |
| être | be |  | `sitw_etre` | 11a, 13b |

### 8.2 New base entries this batch needs (not in `words.json` yet)

These are *Fondations* words (or a fixed phrase around one) that the sketches use and `words.json` does not have yet. All have `firstSeen: null` and `spoken: false`. Use exactly these values in every half that needs them; the coordinator's conflict scan should then find nothing for them. *Arrivé*, *regardé* and *travaillé* get a suffix because the bare slug is already taken (*arrive*, *regarde*, *travaille*).

| fr | en | audio | Needed in |
|---|---|---|---|
| arrivé | arrived | `sitw_arrive_past` | 11, 13, 15 |
| arrivée | arrived (feminine) | `sitw_arrivee` | 11 |
| attendez | wait (vous) | `sitw_attendez` | 13 |
| avait | had (il y avait = there was) | `sitw_avait` | 12 |
| avons | have (nous) | `sitw_avons` | 15 |
| bientôt | soon | `sitw_bientot` | 13 |
| billets | tickets (train) | `sitw_billets` | 13 |
| buvez | drink (vous) | `sitw_buvez` | 14 |
| chose | thing | `sitw_chose` | 13 |
| commencer | to start | `sitw_commencer` | 13 |
| coûte | costs | `sitw_coute` | 15 |
| d'eau | (of) water | `sitw_d_eau` | 12, 14 |
| dois | have to, must (je, tu) | `sitw_dois` | 13 |
| fini | finished, over | `sitw_fini` | 12, 14 |
| forme | shape, form (en forme = fit) | `sitw_forme` | 14 |
| j'avais | I had | `sitw_j_avais` | 14 |
| médecin | doctor | `sitw_medecin` | 14 |
| n'a | has (not) | `sitw_n_a` | 13 |
| n'oubliez | (don't) forget (vous) | `sitw_n_oubliez` | 14 |
| parce que | because | `sitw_parce_que` | 13 |
| parti | left, gone | `sitw_parti` | 11 |
| pourquoi | why | `sitw_pourquoi` | 13 |
| prêts | ready (plural) | `sitw_prets` | 15 |
| qu'elle | that she / that it | `sitw_qu_elle` | 12 |
| regardez | look (vous) | `sitw_regardez` | 11 |
| regardé | looked (at) | `sitw_regarde_past` | 15 |
| repose-toi | rest (tu) | `sitw_repose_toi` | 13, 14 |
| reposer | to rest | `sitw_reposer` | 14 |
| reposes | rest (tu) | `sitw_reposes` | 14 |
| s'ils | if they | `sitw_s_ils` | 13 |
| travailler | to work | `sitw_travailler` | 13 |
| travaillé | worked | `sitw_travaille_past` | 13 |
| venu | come (past participle) | `sitw_venu` | 12 |
| vieux | old | `sitw_vieux` | 15 |

### 8.3 Inflections

Each matrix ends with a glossed table of the inflections and distractor forms its sketches use (*perturbée, annulés, bloqué, chaude, cassée, ratée, guéri, satisfait, crevée…*), with audio keys. They follow the `words.json` habit (*désolée* = "sorry (feminine)", *libres* = "free (plural)"). Five need a suffixed audio key because the bare slug belongs to a new word: *annule* `sitw_annule_verb`, *rate* `sitw_rate_verb`, *commande* `sitw_commande_noun`, *doublé* `sitw_double_past`, plus *dès* `sitw_des_from` and *prêté* `sitw_prete_lent` (clashing with *des* and *prête*). The new word *livré* is `sitw_livre_delivered` (*livre* = book). When two modules list the same form (*appelles* in 12 and 15), the earlier module's half writes it and the later one copies it.

## 9. How each matrix blocks the judges' recurring errors

| Error class | Whole batch | 11 | 12 | 13 | 14 | 15 |
|---|---|---|---|---|---|---|
| **Hidden valid replies** | Every *Clarify* row asks the author to accept the reply with and without « Pardon, ». Two-clause model replies need both orders in `accepted` or a bank that fixes the order. Fill distractors were picked so that only one is valid French in context; candidates that were valid were swapped (*très court*, *la grève*, *déjà là*, *ça va bien*, *pour dimanche*, *dans le quart d'heure*). | *Désolée, je ___ en retard* (serai / seras / sera), not *serais*; *il a ___ dix minutes* (environ / vers / depuis). | *Il y a ___ l'eau* (de / du / des); the caretaker Mot en retour avoids *propriétaire*. | *Commencez* vs *Commence* only in the group (vous = you all); *Depuis ___* (longtemps / temps / toujours). | *J'ai mal à la ___* s05 offers *gare / porte*, not *tête*; *ça va ___* (mieux / meilleur / meilleure), not *bien*. | *C'est ___ trop court* (pas / beaucoup / très) and never *très court* as a right answer; *un problème ___ mon colis* (avec / de / à), not *pour*. |
| **Standalone place labels** | Every standalone row carries its own place (§2.2). | `strike s04` WhatsApp · Mme Dumas; `another s01` Dans la rue; `work s02` Texto · responsable. | `boiler s04` Sur le palier; `leak s04` Texto · Inès. | `late s02` Appel · responsable; `wait s02` WhatsApp · Mme Dumas. | `symptom s04` Sur le palier; `doctor s04` WhatsApp · Mme Dumas. | `haircut s01` Appel · coiffeur; `complain s04` Texto · Léa. |
| **Cue leaks and answer echo** | The validator rejected any Fill whose correct choice is printed in another quoted line of the item (fixed: 12 `visit d03`, 14 `better d02`, 15 `parcel d03`, `fix d03`). Quoted French is never cue text, and the cue must not state the fact a Comprendre asks. | The cue never gives the delay, platform or time the staff announce. | The cue never names what is broken or where the leak is. | The cue never gives the reason for the delay. | The cue never names the symptom the doctor or pharmacist asks about. | The cue never names the missing item or the fix offered. |
| **A speaker answering their own question** | Where a question must be followed by its answer, Robin's question is a printed learner line and the other speaker answers (14 `pharmacy d01`, 15 `fix d03`, 12 `landlady d01`, 13 `formal d02`, `late d07`). | Announcements never ask questions. | | | | |
| **« Repeat » asked of a text** | *Clarify* rows are face to face or live calls only; the validator rejected any *Clarify* on Texto, Les copains, WhatsApp or Messagerie. Mme Dumas's and Théo's *Clarify* rows are calls. | `group d05` Appel · Théo; `work d05` Appel · Inès. | `boiler d05`, `broken d05`, `landlady d05` Appel · Mme Dumas. | `late d05` Appel · Théo; `newplan d05` Appel · Théo. | `symptom d05`, `better d05` Appel · Mme Dumas. | All *Clarify* rows are calls or the shop. |
| **Glosses wrong in context** | §2.8 lists the traps; §8 fixes every shared gloss; each matrix glosses its inflections. | *billet* (train) vs 08 *ticket*; *place* (a seat) acceptable. | *chaude* as a base inflection, *eau chaude* not a key. | *t'attends* never for *tu attends*. | *mal* widened or kept to *j'ai mal* (open question 1); *arrêt maladie* keyed apart from *arrêt* (stop). | *trop court* only, never bare *court*. |
| **Phrase key across a comma** | §2.9. | *tiens au courant*, *en attendant* never split. | *dès que possible*, *machine à laver*, *boîte aux lettres*, *à clé* never split. | *on remet ça*, *rien de grave*, *prends soin de toi* never split. | *qu'est-ce qui ne va pas*, *ça va mieux*, *bon rétablissement* never split. | *il manque*, *encore une fois*, *la dernière fois* never split. |
| **Follow-ups that ignore the learner** | A Répondre follow-up must fit every accepted reply. Rows where Robin may answer yes or no need a neutral follow-up. | `cancelled d01`: fits "is there another train?" whatever the answer. | `boiler d01`: Léa's follow-up fits "I'll write to Mme Dumas". | `newplan d01`, `d08`: the follow-up accepts the day Robin proposes. | `pharmacy d01`: the pharmacist's follow-up fits « un petit rhume ». | `fix d01`: fits any thank-you. |
| **False errors** | Corriger never targets an accepted spoken form or a common variant. | *perturbée → perturbé*, *annulée → annulé*, *prévue → prévu*, *valables*, *tient → tiens*, *le navette*, *prévenu → prévenir*, *arrivé → arrivée* (Robin). | *chaud → chaude* (eau), *coulent*, *réparé → réparer*, *le porte*, *prêté → prêter*, *cassé → cassée* (lumière), *Désolé → Désolée*, *absent → absente*. | *une quart d'heure*, *mon faute*, *ratée → raté* (avoir), *arrivé → arrivée*, *obligé → obligée*, *une autre jour*, *j'espères*, *reporté → reporter*. | *au tête*, *une rhume*, *comprimé → comprimés*, *jour → jours*, *mon carte Vitale*, *à le ventre*, *malades*, *guéri → guérie*. | *livrée → livré*, *commander → commandé*, *satisfait → satisfaite*, *cheveu → cheveux*, *crevée → crevé*, *une devis*, *pareille → pareil*, *gratuite → gratuit*. |
| **Logic puzzles** | No gap depends on reasoning about who owns what or on arithmetic; numbers are printed when needed. | Times and platforms are stated in French, never computed. | | The day of the new plan is chosen by Robin, never deduced. | Doses are printed, never calculated. | Prices are printed (*vingt euros*). |
| **Untaught words used early** | Every quoted token and choice was checked in book order against *Fondations*, `words.json` and this batch (0 unknown left). Caught and fixed: *annuler* as an 11 distractor, *toute la journée* (already in 07), *neuf / onze / quinze / trente*, *changer* (now *échanger*, 08), *hé, juste, dessert, année, nul, truc*, *pendant* as a 12 distractor (taught in 14), *taxi* before 11 `another`, *réunion* before 11 `work`. | | | | | |
| **Masculine forms for Robin** | Learner lines use feminine forms only; masculine forms appear as decoys. Cues say "You're a woman." where the answer hinges on it. | `group d02`, `d06`, `s01`; `arrive s03`, `s04`. | `landlady d06`, `s03`; `visit s01`, `s03`. | `sorry d03`; `wait s03`; `cancel s01`, `s03`, `d07`. | `better s01`, `d04`, `d06`, `s03`. | `complain d02`, `s01`, `s03`. |

## 10. `modules.json` entries (ready to paste)

Add these before the first assemble; the author agents don't.

```json
{"id": "sit_11", "title": "Grève et retards", "arc": "Les imprévus", "goal": "Understand a strike, a cancellation or a delay, and find another way to get there.", "file": "11_greve_et_retards.json", "moves": ["strike", "cancelled", "delay", "desk", "group", "another", "work", "arrive"]},
{"id": "sit_12", "title": "Le logement", "arc": "Les imprévus", "goal": "Report a broken boiler, a leak or lost keys, and arrange the repair with the landlady and the neighbours.", "file": "12_le_logement.json", "moves": ["boiler", "leak", "plumber", "keys", "neighbour", "broken", "landlady", "visit"]},
{"id": "sit_13", "title": "Être en retard, annuler", "arc": "Les imprévus", "goal": "Say you're late, apologise and explain, cancel or postpone, and propose a new plan.", "file": "13_en_retard_annuler.json", "moves": ["late", "sorry", "reason", "wait", "cancel", "newplan", "react", "formal"]},
{"id": "sit_14", "title": "Santé", "arc": "Les imprévus", "goal": "Describe a symptom, get advice at the pharmacy, make a doctor's appointment, and say you're ill or better.", "file": "14_sante.json", "moves": ["symptom", "cold", "pharmacy", "advice", "appointment", "doctor", "sick", "better"]},
{"id": "sit_15", "title": "Ça ne marche pas", "arc": "Les imprévus", "goal": "Complain politely about a parcel, a haircut or a bike repair, and ask for a fix.", "file": "15_ca_ne_marche_pas.json", "moves": ["parcel", "wrong", "complain", "haircut", "bike", "repair", "again", "fix"]}
```

Drafts: `11_greve_et_retards_{first,second}_half{,_words}.json`, `12_le_logement_{first,second}_half{,_words}.json`, `13_en_retard_annuler_{first,second}_half{,_words}.json`, `14_sante_{first,second}_half{,_words}.json`, `15_ca_ne_marche_pas_{first,second}_half{,_words}.json`.

## 11. Batch procedure (unchanged from the next-session handoff §4)

1. The coordinator settles the open questions (or takes the defaults below), then:
   - adds the five `modules.json` entries (§10);
   - (default for question 1) widens the base gloss of *mal* in `words.json`;
   - (default for question 2) adds `"t'inquiète"` to `SPOKEN` in `tools/situations/lint.py`, with a test.
2. Two author agents per module (10 in all). Give each this file (§1–2, §8, §9), its matrix and `agents/author.md`, plus the coordinator decisions: « À l'appart » is the home label; unnamed speakers need a `role`; avoid untaught phrase keys and phrase keys across a comma; module 10's map is canon.
3. Gloss conflict scan over all drafts and `words.json` (§8 and the matrices' inflection tables should leave few), then `assemble.py 11 12 13 14 15`, lint, tests, `deep_lint.py` and the Swift model test.
4. Four judges per module (two moves each), with §1–2 and §9 of this file.
5. Fixes, then the *Fondations* audit of every new `firstSeen: null` entry.
6. One 9-card review set for the arc, D D S order, drill types differing across item boundaries and adjacent dialogues with different drill pairs. Suggested: `sit_11_strike_d01 sit_12_leak_d03 sit_13_wait_s02 sit_14_pharmacy_d01 sit_15_haircut_d03 sit_12_keys_s03 sit_13_cancel_d07 sit_14_sick_d08 sit_11_group_s05` (a strike text, the leak, the spoken *t'inquiète*, the pharmacy culture card, the haircut complaint, a Corriger, cancelling with M. Ferrand, the sick-day text, the car-share).

## 12. Open questions for the user (with the default authoring will use)

1. **Widen the gloss of *mal*.** It is a base entry glossed "bad / badly". 14 needs *tu as mal ?*, *vous avez mal ?*, *le mal de tête*. Widen it to "bad / badly / pain (avoir mal = to hurt)"? It changes the tooltip on every earlier *mal* (still correct there). **Default: yes, widen before authoring 14.** (Without it, 14 keeps to the key *j'ai mal* and rewrites about ten rows.)
2. **One new spoken form: *t'inquiète*** (13 `wait`, *don't worry*; the standard *ne t'inquiète pas* is a *Fondations* base phrase). Lint needs `"t'inquiète"` in `SPOKEN`. **Default: yes, add it.** (Alternative: no new spoken form, and 13 `wait` teaches *patienter* instead.)
3. ***Court* is glossed "runs"** (02, *courir*). 15 needs "short" for hair. **Default: keep the gloss and teach only the phrase *trop court***; authors never print a bare *court*. (Alternative: widen *court* to "runs / short".)
4. ***Billet* vs *ticket*.** 11 teaches *billet* for a train ticket; 08's *ticket* stays "receipt, ticket" (metro, shop). **Default: yes.**
5. **Two keys, *annulé* (11) and *annuler* (13)**, so 11 can say a train is cancelled before 13 teaches cancelling plans. **Default: yes.**
6. **New one-off people and facts:** Robin's manager (an unnamed woman, « Responsable », *vous*); the building's caretaker (« Gardienne ») and a neighbour downstairs; M. Ferrand keeps a spare key from Mme Dumas and lends Robin his bike; Léa's birthday party (12 `neighbour d08`); Robin has a bike and works from home on strike days; the 09 restaurant comes back to postpone a booking. **Default: all fine.** Add « Conseillère, Coiffeuse, Secrétaire, Employée, Voyageuse, Gardienne » and their masculine pairs to the role gender lists in `lint.py`? **Default: yes, a small lint change.**
7. **Culture items:** *la grève* and the strike-day *télétravail*, *covoiturage*, the pharmacist as first stop, *la carte Vitale*, skipping *la bise* with a cold (14 `cold s02`), *un devis* before repairs, *j'ai un empêchement*. **Default: keep all.**
8. **Station announcements** as a server turn with role « Annonce » and the female Neural2 voice. **Default: yes.**
9. **Review before authoring.** Memory says to author in bulk only after the user approves a sample. **Default: author all five modules, then show the 9-card set in §11 as review set v8** (as arc 2 did with v7).

