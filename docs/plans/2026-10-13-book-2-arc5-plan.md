# Book 2, arc 5 *Échanger*: plan for modules 21–25

**Date:** 2026-10-13
**Status:** paper plan only. No French is authored. Nothing is committed. `modules.json` is unchanged (entries in §10).
**Matrices:** [21](2026-10-13-book-2-arc5-module-21-matrix.md) · [22](2026-10-13-book-2-arc5-module-22-matrix.md) · [23](2026-10-13-book-2-arc5-module-23-matrix.md) · [24](2026-10-13-book-2-arc5-module-24-matrix.md) · [25](2026-10-13-book-2-arc5-module-25-matrix.md)
**Rulebook:** [audio handoff](2026-10-13-book-2-audio-handoff.md) §3 (gloss rule and decisions) and §5; [arc 4 handoff](2026-10-13-book-2-arc4-handoff.md); [next-session handoff](2026-10-13-book-2-next-session-handoff.md) §4 (lessons, built in here); [content handoff](2026-10-11-book-2-content-handoff.md) §3–§8; [café handoff](2026-10-11-book-2-cafe-handoff.md) §3; `tools/situations/README.md`. The format is copied from the [arc 4 plan](2026-10-13-book-2-arc4-plan.md).

Arc 5 is the last arc of the 25-module book. Modules 01–20 are taught content: everything they teach (514 taught keys in `words.json`, 1,855 entries in all) is known here. That includes arc 4's *conseil, choix, franchement, pratique, surtout, comme ça, fais attention, réfléchir, d'un côté, tu as eu raison, pire, au moins, galère, mince, sans blague, ça dépend, on pourrait, sinon, par personne, en ligne* and the rest.

Each matrix has one row per item (8 moves × 15 items = 120 per module) in the arc 4 format. It also has a new-word table with the exact `en` / `spoken` / `audio` and a **gloss check** for every new key, and a glossed table of every inflection and distractor form its sketches use.

A validator in the planning scratchpad (not in the repo) checked all 600 rows before the matrices were written:
- **Item structure:** item order; standalone labels; the fixed drill template (§2.1); ≥4 dialogue types and Répondre + Compléter ≥ half per move; one *Clarify* dialogue per move, never on a text, the group chat or WhatsApp; ≥2 dialogues off the home channel.
- **New words:** ≤2 new words per item, each printed in a turn of its first-seen item (never only in a gap or a built reply). Each recurs in ≥2 later dialogues and a later Mot or Mot en retour inside its own move. Mot targets are visible in a quoted line, and each Mot en retour target is one of its choices.
- **Line length:** ≤10 words per dialogue line, 8–14 in Construire and Transformer lines.
- **Glosses:** every quoted token and every choice was segmented longest-key-first, breaking at `___` and at a free-standing « ! » « ? » « : » as the app does. It was matched against `words.json`, this batch's keys and the inflection tables: 0 unglossed tokens.
- **Book order and earlier lines:** book order holds inside the batch (0 keys used before their item). Every new key was checked against the exposure lines of all 2,400 items in 01–20 (0 printed earlier). It was also checked against their tappable lines, so no new key swallows an earlier reading; the one multi-word base key that touches an earlier line is listed in §2.8.
- **Audio keys:** 0 collisions across `words.json`, the new keys and the inflection tables, with the `_past` / `_verb` / sense suffixes in §2.7.
- **Masculine forms:** a scan of every quoted line for Robin's masculine self-forms. Hits occur only in Corriger error lines and in Théo's own lines.

## 1. Fixed decisions this plan builds on

- **Robin** is a woman from Eugene, Oregon. Her lines are feminine only.
  - This arc adds *déçue* (21), *occupée* (23) and *contente*, alongside *désolée, fatiguée, sûre*.
  - A cue says "You're a woman." wherever an answer hinges on it.
  - Masculine forms appear only as decoys and in Corriger error lines (21 `formal s03` *déçu*, 23 `so s03` *fatigué*, 23 `refuse s03` *occupé*).
- **Registers:**
  - **Karim:** *tu*.
  - **M. Ferrand, Mme Dumas:** *vous* always.
  - **Léa, Inès, Théo:** *tu*.
  - **Group chat:** *vous* is plural, and the cue says « vous = you all ». A Transformer to "Léa and Théo (vous, you both)" is plural *vous*.
- **Unnamed speakers carry a `role`:**
  - existing roles: « Serveur / Serveuse » (21 `food`, `formal`), « Responsable » (Robin's manager, female), « Employé / Employée » (station and ticket desk), « Annonce » (station announcements, as in 11);
  - one new role: « Propriétaire » (the gîte owner, `voice: "female"`; open question 1).
- **Home label « À l'appart »** (book-wide). Lines never print *appart*.
- **Module 10's map and the cast facts are canon.** Robin works in an office with Inès and a female manager. She lives at huit, rue Pasteur with Léa, M. Ferrand is on the landing and Mme Dumas is the landlady on WhatsApp.
  - New one-off facts are in open question 6.
- **Underlines** mean "new here" only. A word taught in 01–20 is never put back in `newWords`.
- **Comprendre `correct`:** the author writes the question and **checks every `correct` index against the true choice** (arc 3 shipped 15 inverted keys).
- **Choisir le ton:** every option is natural French.
  - The wrong options are good French in the wrong register: *tu* to Mme Dumas, *Salut !* to the manager, a blunt imperative.
  - No stray « bref », « ouais », « hein », « bah » or slang (« genre », « bouffe »). The validator rejected each.
- **No Grammalecte suppression.** Reword instead (the next-session handoff §4 lesson).
- **Per move:** 10 dialogues + 5 standalones (Construire, Choisir le ton, Corriger, Transformer, Mot en retour).

## 2. Conventions in this arc

1. **Same drill template in every move** (as arcs 2–4):
   - d01 U R · d02 U C · d03 C U · d04 M R · d05 R M (*Clarify*) · d06 C U · d07 M C · d08 R U · d09 U C · d10 U R.
   - That gives 4 types, and Répondre + Compléter = 10 of 20 in each move. No engine repeats across a boundary.
   - **Mot targets:** the d01 word at d04, the d02 word at d05, the d03 word at d07. A fourth word (21 `food` *sucré*, 22 `chores` *lessive*, 23 `lyon` *célèbre*, 24 `etsi` *randonnée*, 25 `annonce` *correspondance*) gets s05.
2. **Places** (plain text, never glossed).
   - **Existing:** `À l'appart`, `Au bureau`, `Au café`, `Sur le palier`, `Dans la rue`, `Au restaurant`, `À la gare`, `Au guichet`, `Texto · <name>`, `Les copains · groupe`, `WhatsApp · Mme Dumas`, `Appel · <name>`.
   - **New:** `Devant le cinéma` (21 `film`), `Au gîte` (25), `Appel · gîte` (24, 25), `Appel · M. Ferrand` (25 `home`, `repair`), `Texto · Karim` (25).
   - Standalone labels add « · phrase seule » and match the cue's setting, not the move's home place.
3. **Two speakers in one dialogue** need `followUpBy`:
   - 25 `group d02`: Théo, then Inès, then Robin;
   - 25 `annonce d02`, `d03`, `d07`: « Annonce », then Robin's printed line to Inès.
4. **Numbers stay small words:** *deux … dix, quinze, vingt, midi*.
   - No *neuf*: it is also "new".
   - Tracks are *voie deux / trois*, never *voie B* (*b* would need a gloss).
   - Budgets are *dix / vingt euros par personne*.
5. **Feminine keys for Robin:** *déçue* (21) and *occupée* (23) are keyed feminine. *Déçu* is an inflection; *occupé* is already a base entry.
6. **Elided and contracted forms are separate tokens**, so a key only matches its exact form:
   - **Article included:** *histoire* is keyed bare, and *l'histoire* is a base entry (§8.2), so recurrences say *une / cette histoire*. *Acteurs* is keyed plural (*les acteurs*).
   - ***grâce à*** never meets *le / les*: write *grâce à toi / à vous / à ma tarte*.
   - ***en raison de*** never meets *un / une*: write *en raison de la / de l'*.
   - **No *de* + vowel infinitive:** no line writes *c'est d'économiser*, *d'arroser* or *d'arriver*. The elided token loses the key.
   - **No *s'il y a*:** *s'il* is one token, so *il y a* would not match.
   - **No plural *bouchons lyonnais*:** bare *bouchons* is 13's "traffic jams".
7. **Audio keys.** A verb form and its past participle never share a slug (arc 3 lesson). A second sense gets a sense suffix. Planned:
   - *déraillé* `sitw_deraille_past` / *déraille* `sitw_deraille_verb`;
   - *récupéré* `sitw_recupere_past` / *récupère* `sitw_recupere_verb`;
   - *arrosé* `sitw_arrose_past` / *arrose* `sitw_arrose_verb`;
   - *dépensé* `sitw_depense_past` / *dépense* `sitw_depense_verb`;
   - *sucré* `sitw_sucre_sweet` and *sucrés* `sitw_sucres_sweet` (*sucre / sucres* = sugar own the bare slugs);
   - *sale* `sitw_sale_dirty` and *sales* `sitw_sales_dirty` (21's *salé* owns `sitw_sale`);
   - *trompes* `sitw_trompes_verb` (*trompés* owns `sitw_trompes`).

   Authors who need a form not in the tables check `words.json` and the matrices for the slug before writing it.
8. **Gloss rule (user, hard rule): every tap gloss must be correct in every drill and sentence it appears in.** Each key has one book-wide gloss. The app matches the longest key first, left to right. A key may span a comma, but not a free-standing « ! » « ? » « : » or a `___` gap. This plan builds on the decisions already in `words.json`:
   - **Negation.** *n'*-forms show the plain verb with a note (*n'est* = "is (n'est pas = isn't)", *n'aime* = "like (n'aime pas = don't like)"), and *ne* / *pas* carry negation notes. There is no bare « pas de » key.
     - New negative keys swallow their whole negation, so it reads once: *je ne suis pas d'accord*, *ce n'est pas juste*, *pas du tout*, *pas forcément*, *pas question*.
     - Lines never print « tu n'es pas d'accord », and never put *pas forcément* after an *n'*-form: the negation would read twice.
   - **Être forms** note the passé composé (*suis* = "am (je suis allée = I went)"); nothing new is needed.
   - ***à* + weekday** keeps its literal-first gloss (*à demain*, *à jeudi*).
   - **Phrase keys reused as they stand:** *on est / on a / on fait / on dit*, *on va*, *le dimanche / le samedi / le lundi* (= on Sundays…), *le matin / le soir / le week-end*, *chez moi*, *il faut*, *il y avait*, *il n'y a pas (de)*, *il n'y a plus de*, *si j'étais vous / toi*, *si tu veux*, *ça me va*, *tous les soirs*, *de la chance*.
     - Every new key that starts with one of these is longer and wins: *on est d'accord*, *on verra*, *on irait*, *on se calme*, *je suis d'accord*.
   - **No `de la` key**, **no bare « pas de » key**, and **comma-spanning keys only for *moi c'est***. No new key spans a comma, and no sketch splits a key with one (*à tour de rôle, de toute façon, pendant ce temps, je vois ce que tu veux dire* are always unbroken).
   - **Three new base phrase keys** (`firstSeen: null`, *Fondations* 25 and 21; open question 4):
     - *s'il fait beau* = "if the weather's nice";
     - *s'il pleut* = "if it rains";
     - *plus tôt* = "earlier" (otherwise "more / most · early").

     *s'il pleut* also re-glosses one earlier line, 18 `decide d09`'s follow-up « Bon, s'il pleut, cinéma ! ». It reads right there.
   - **Senses existing glosses don't cover, so the sketches avoid them:**
     - *marche* only for machines (*le chauffage marche*), never "walk" or "business is good";
     - *sors / sort* never for "take out" (hence *sortir les poubelles* and *sors / sort les poubelles* as keys);
     - *à ta place* never for "instead of you" (it means "if I were you");
     - *plus de* + noun never for "more" (it shows "no more");
     - *été* never for "summer";
     - *annonce* never as a verb;
     - *trouve / trouvé* never for the opinion sense outside the keys *je trouve / tu trouves*;
     - *allez* never for "come on";
     - *juste* never bare;
     - *tombe* only inside *ça tombe mal / bien*;
     - *billets* only for train tickets;
     - *fait* only for "does / makes" and the weather;
     - *faire beau* never in the future (« il va faire beau » would read "do / make · nice"): the sketches write « il fait beau ».
   - **Keys a later line could mislead, flagged in each matrix's gloss-check column:**
     - *je trouve / tu trouves* (opinion only);
     - *propre* (clean, never "own");
     - *moyen* (adjective, never "a means");
     - *tour* (turn, never "tower / a walk");
     - *ça t'a plu / ça m'a plu / ça vous a plu* (never split by *beaucoup*; never *il a plu* "it rained");
     - *faire le pont* (infinitive only: « on fait le pont » would read "we do · the · bridge");
     - *et si on* (*et si* alone is printed in 01);
     - *sortir les poubelles* (no pronoun inside);
     - *grâce à* and *en raison de* (contractions);
     - *si seulement* (no *plus de* after it);
     - *pas forcément* (free-standing only);
     - *ce n'est pas juste* (a *c'est juste* key would swallow 10's « c'est juste après »).
   - **Author self-check (required before handing in)** is step 2 of §11.
9. **Phrase keys must not be split by a comma:** *à mon avis, à ton avis, ça t'a plu, ça m'a plu, ça vous a plu, pas du tout, sans plus, je suis d'accord, tout à fait, je ne suis pas d'accord, tu as tort, pas question, pas forcément, en partie, je vois ce que tu veux dire, à tour de rôle, ce n'est pas juste, je veux bien, en échange, ça te dérange, ça m'énerve, on est d'accord, marché conclu, pourquoi pas, comment ça, pour quelle raison, grâce à, c'est pour ça que, voilà pourquoi, par exemple, en général, au cas où, je m'explique, c'est-à-dire, en fait, Vieux Lyon, Fête des Lumières, ça tombe mal, ça tombe bien, faire le pont, jour férié, et si on, plan B, au pire, de toute façon, on irait, si seulement, on verra, si jamais, à la dernière minute, en raison de, je croyais que, autrement dit, boîte à clés, objets trouvés, sac à dos, pendant ce temps, de mauvaise humeur, tu exagères, on se calme, le bon côté, au final.*
10. **Keys that must not appear before their module or move** (the validator found none; keep it that way when rewriting):
    - *pas du tout* before 21 `strong` (21 `mixed s05` and 22 `deal` reuse it after);
    - *au cas où* before 23 `purpose`: it is taught there, not in 24;
    - *en fait* before 23 `explain`;
    - *on verra* before 24 `decide`, so 23 `lyon s04` says *on ira*;
    - *tellement* before 23 `so`;
    - *louer* before 24 `book` (24 `dream d10` reuses it);
    - *exactement* and *exprès* before 22 and 23 (21's Mot en retour decoys avoid both);
    - *rire* before 25 `bright` (no *on a bien ri* in 21–24).
11. **Drafts:** `21_donner_son_avis_{first,second}_half{,_words}.json`, `22_d_accord_ou_pas_{first,second}_half{,_words}.json`, `23_expliquer_pourquoi_{first,second}_half{,_words}.json`, `24_et_si_{first,second}_half{,_words}.json`, `25_un_week_end_qui_deraille_{first,second}_half{,_words}.json`.

## 3. Move lists

Moves 1–4 go to author agent 1 (first half) and moves 5–8 to author agent 2 (second half). Each new word belongs to the half where it first appears. Its recurrences and Mot drill stay inside its own move, so the halves never depend on each other's drafts. A second-half item that reuses a first-half word copies its entry from the matrix's word table.

### 21 *Donner son avis*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_21_opinion` | À mon avis | 1st | 3 (à mon avis, je trouve, tu trouves) | The syllabus move: say what you think. *À mon avis*, *je trouve* (opinion sense) and the check-back *tu trouves ?*. Léa at home after a film; Inès, Théo and Karim elsewhere. |
| `sit_21_film` | Le film | 1st | 3 (drôle, histoire, acteurs) | Opinions about a film outside the cinema (a new plain-text place): *drôle*, *une histoire*, *les acteurs*. Imparfait for how it was (*c'était drôle, les acteurs étaient bons*). |
| `sit_21_food` | Ce plat | 1st | 4 (épicé, salé, sucré, goût) | Opinions about food: *épicé*, *salé*, *sucré* (the French sweet-or-savoury choice) and *le goût*. The waiter's *Le plat vous plaît ?* comes back in *vous*. |
| `sit_21_area` | Le quartier | 1st | 3 (animé, agréable, propre) | Opinions about the neighbourhood on a walk with Inès and Théo: *animé*, *agréable*, *propre*. Comparatives *plus agréable* (19) and Robin's own *quartier calme* (03). |
| `sit_21_ask` | Et toi, ton avis ? | 2nd | 3 (à ton avis, ça t'a plu, ça m'a plu) | The social move: ask for the other person's opinion. *À ton avis ?*, *ça t'a plu ?* and the answer *ça m'a plu*. Bare *avis* is never printed (only inside the keys), so no gloss is needed for it. |
| `sit_21_strong` | J'adore, je déteste | 2nd | 3 (déteste, pas du tout, incroyable) | Strong opinions: *je déteste* (against the base *j'adore*), *pas du tout* and *incroyable*. *Pas du tout* is one key, so « je n'aime pas du tout » reads « like (n'aime pas = don't like) · not at all ». |
| `sit_21_mixed` | Bof, sans plus | 2nd | 3 (bof, sans plus, moyen) | Lukewarm opinions: *bof*, *bien, sans plus* and *moyen* (so-so). Inès at the office is the home scene; the manager (*vous*) gets the polite version. |
| `sit_21_formal` | Ça vous a plu ? | 2nd | 3 (ça vous a plu, excellent, déçue) | The *vous* version: the waiter's *Ça vous a plu ?*, *excellent*, and Robin's polite disappointment *je suis un peu déçue* (feminine: Corriger on *déçu*). M. Ferrand, Mme Dumas and the manager ask too. |

### 22 *D'accord ou pas*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_22_chores` | Les tâches | 1st | 4 (ménage, lessive, vaisselle, sortir les poubelles) | The syllabus scene: chores with Léa. *Le ménage*, *la lessive*, *la vaisselle* and *sortir les poubelles*. *Sortir les poubelles* is keyed as a phrase (and *sors / sort les poubelles* as inflections), because bare *sortir / sors* show « go out ». |
| `sit_22_agree` | Je suis d'accord | 1st | 3 (je suis d'accord, tout à fait, exactement) | Agreeing: *je suis d'accord* (a key, so it doesn't read « I · am · OK »), *tout à fait* and *exactement*, beside the base *tu as raison*. |
| `sit_22_disagree` | Pas d'accord | 1st | 3 (je ne suis pas d'accord, tu as tort, pas question) | Disagreeing: *je ne suis pas d'accord* (one key, so the negation reads once), *tu as tort* (the opposite of the base *tu as raison*) and *pas question*. Lines never print « tu n'es pas d'accord », which would read « are (n'es pas = aren't) · not · OK ». |
| `sit_22_soften` | Adoucir | 1st | 3 (pas forcément, en partie, je vois ce que tu veux dire) | Softening a disagreement: *pas forcément*, *en partie* (*tu as raison en partie*) and *je vois ce que tu veux dire*. *Pas forcément* is printed only as a free-standing reply: after a *n'*-form it would read « is (n'est pas = isn't) · not necessarily ». |
| `sit_22_turns` | Chacun son tour | 2nd | 3 (tour, à tour de rôle, ce n'est pas juste) | Taking turns and fairness: *c'est ton tour*, *à tour de rôle* and *ce n'est pas juste*. *Juste* is never printed bare: 08's *je regarde juste* and 10's *juste après* keep their keys, and a bare *c'est juste* key would swallow 10's « c'est juste après ». |
| `sit_22_deal` | Un arrangement | 2nd | 3 (je veux bien, en échange, ça te dérange) | Making a deal: *je veux bien* (I'm happy to), *en échange* (in return) and *ça te dérange ?* (do you mind?). Lines never write « à ta place » for “instead of you”: the key means « if I were you ». |
| `sit_22_complain` | Se plaindre gentiment | 2nd | 3 (ranger, sale, ça m'énerve) | Complaining kindly: *ranger*, *sale* and *ça m'énerve*, with *désolée* and a fix in reply. Robin is on both sides: Léa asks her to tidy, and she asks M. Ferrand about his bike. |
| `sit_22_settle` | On est d'accord | 2nd | 3 (on est d'accord, marché conclu, planning) | Settling it: *on est d'accord ?* (longer than the base *on est*), *marché conclu* (longer than 07's *marché*) and *le planning* on the fridge. |

### 23 *Expliquer pourquoi*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_23_why` | Pourquoi ? | 1st | 3 (pourquoi pas, comment ça, pour quelle raison) | Asking why: *pourquoi pas*, *comment ça ?* (what do you mean?) and the formal *pour quelle raison ?* (the manager, M. Ferrand, Mme Dumas). |
| `sit_23_because` | Parce que, car, puisque | 1st | 3 (grâce à, car, puisque) | Giving the cause: *grâce à* (thanks to), the written-style *car* (Mme Dumas, M. Ferrand, the manager) and *puisque* (since). *Grâce à* never meets *le*: « grâce au » is an inflection key (§2.6). |
| `sit_23_so` | C'est pour ça que | 1st | 3 (c'est pour ça que, voilà pourquoi, tellement) | Consequences: *c'est pour ça que* (that's why), *voilà pourquoi* and *tellement* (so, so much). *C'est pour ça* without *que* is an inflection key for the end of a line. |
| `sit_23_example` | Par exemple | 1st | 3 (par exemple, d'ailleurs, en général) | Backing a point with an example: *par exemple*, *d'ailleurs* (besides, actually) and *en général*. *Bouchons lyonnais* is never written in the plural: bare *bouchons* is 13's « traffic jams ». |
| `sit_23_purpose` | Pour que | 2nd | 3 (exprès, au cas où, but) | Purpose: *exprès* (on purpose, specially), *au cas où* (just in case) and *le but* (the aim), with *pour que* + subjunctive from *Fondations* 24 (*pour que tu comprennes*). Lines never write *c'est d'* + a vowel infinitive (« d'économiser » is one token and would lose its key). |
| `sit_23_explain` | Je m'explique | 2nd | 3 (je m'explique, c'est-à-dire, en fait) | Explaining at work: *je m'explique* (let me explain), *c'est-à-dire* (that is, I mean) and *en fait* (actually). The manager (*vous*) and Inès (*tu*) side by side. |
| `sit_23_lyon` | Pourquoi Lyon ? | 2nd | 4 (vieux lyon, célèbre, traboules, fête des lumières) | Culture move: Robin explains why she loves Lyon. *Le Vieux Lyon*, *célèbre*, *les traboules* (passageways through the old buildings) and *la Fête des Lumières* (every December). The keys are longer than the base *vieux* and *fête*, so those keep their glosses elsewhere. |
| `sit_23_refuse` | Dire non, avec une raison | 2nd | 3 (occupée, ça tombe mal, ça tombe bien) | The social move: say no and give the reason. Robin's *je suis occupée* (feminine: Corriger on *occupé*), *ça tombe mal* and *ça tombe bien*. Both are keys, so bare *tombe* (« fall(s) ») never shows here. |

### 24 *Et si… ?*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_24_pont` | Le pont | 1st | 3 (faire le pont, jour férié, congé) | Culture move: *faire le pont*, the extra day off between a *jour férié* and the weekend, and a *jour de congé*. *Faire le pont* is keyed only in the infinitive: « on fait le pont » would read « we do · the · bridge » (10's *pont*), so every line says *faire le pont*. |
| `sit_24_etsi` | Et si on… ? | 1st | 4 (et si on, montagne, randonnée, lac) | The syllabus move: suggest with *et si on* + imparfait (*Fondations* 25, *si on allait au cinéma*). The group dreams of the mountains: *la montagne*, *une randonnée*, *le lac* at Annecy. *Et si* alone is not a key (01 prints « Et si vous avez besoin »), so the key is *et si on*. |
| `sit_24_weather` | S'il fait beau | 1st | 3 (météo, orage, degrés) | The realistic condition, *si* + present + futur (*Fondations* 25): *s'il fait beau, on ira au lac*. New: *la météo*, *un orage*, *vingt degrés*. Two new base phrase keys make the condition read right: *s'il fait beau* and *s'il pleut* (§2.8). |
| `sit_24_planb` | Un plan B | 1st | 3 (plan b, au pire, de toute façon) | The alternative: *un plan B*, *au pire* (at worst, if worst comes to worst) and *de toute façon* (anyway, in any case). *Au pire* is longer than 17's *pire*, so it reads as a phrase. |
| `sit_24_book` | Réserver le voyage | 2nd | 3 (louer, aller-retour, gîte) | Booking it: *louer* (a car, bikes), *un aller-retour* at the ticket desk, and *un gîte* (a rented country cottage, a French holiday classic). The gîte owner gets the new role « Propriétaire » (§2.3). |
| `sit_24_dream` | Si on avait… | 2nd | 3 (on irait, rêve, si seulement) | The unreal condition, *si* + imparfait + conditional (*Fondations* 25): *si on avait une voiture, on irait…*. New: *on irait*, *un rêve*, *si seulement*. Lines never write *plus de* + noun (« plus de temps » would show « no more »). |
| `sit_24_budget` | Le budget | 2nd | 3 (budget, dépenser, raisonnable) | Money for the trip: *le budget*, *dépenser* and *raisonnable*, in the group chat. Sums stay small words (*dix, vingt euros par personne*) and are printed, never computed. |
| `sit_24_decide` | On verra | 2nd | 3 (on verra, si jamais, à la dernière minute) | Deciding without deciding: *on verra* (we'll see), *si jamais* (if by any chance) and *à la dernière minute*. The futur simple comes back in *on verra*, *on restera*. |

### 25 *Un week-end qui déraille*

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_25_annonce` | L'annonce | 1st | 4 (voie, correspondance, supprimé, en raison de) | Listening move: station announcements (role « Annonce », as in 11) with *la voie*, *supprimé*, *en raison de* and *la correspondance*. *En raison de* is never followed by *un / une* (« d'une » is one token and would lose the key). |
| `sit_25_repair` | Un malentendu | 1st | 3 (je croyais que, malentendu, autrement dit) | Repair: *je croyais que…* (I thought…), *un malentendu* and *autrement dit* (in other words: checking you've understood). Calls with Théo, the gîte owner and M. Ferrand. |
| `sit_25_gite` | Au gîte | 1st | 3 (boîte à clés, draps, fonctionne) | Sorting out problems at the rental: *la boîte à clés*, *les draps* and *ça ne fonctionne pas* (beside 15's *ça ne marche pas*). The owner is on the phone (*vous*), the friends are in the house (*tu*). |
| `sit_25_lost` | Objets perdus | 1st | 3 (objets trouvés, sac à dos, récupérer) | Robin leaves her rucksack on the train: *un sac à dos*, *les objets trouvés* (lost property) and *récupérer*. Agreement after *l'* in the passé composé (*je l'ai oublié*: the bag is masculine) is the one subtle Fill. |
| `sit_25_home` | Pendant ce temps, à Lyon | 2nd | 3 (pendant ce temps, plantes, arroser) | Meanwhile back in Lyon: Mme Dumas reports a leak, M. Ferrand waters Robin's plants, Karim texts. *Pendant ce temps*, *les plantes*, *arroser*. Lines never write *d'arroser* (one token, no key). |
| `sit_25_group` | On se calme ! | 2nd | 3 (de mauvaise humeur, tu exagères, on se calme) | Tempers fray in the rain: *de mauvaise humeur*, *tu exagères* and *on se calme*. Group scenes have two named speakers, so the follow-up needs `followUpBy`. |
| `sit_25_bright` | Le bon côté | 2nd | 3 (le bon côté, souvenir, rire) | Looking on the bright side: *le bon côté*, *un bon souvenir* and *rire* (*on a bien ri*). *Le bon côté* is longer than the base *côté* and 20's *d'un côté*, so each keeps its gloss. |
| `sit_25_tell` | Lundi matin | 2nd | 3 (aventure, déraillé, au final) | Telling the whole story on Monday: *une aventure*, *tout a déraillé* (everything went off the rails, the module's title) and *au final* (in the end). Passé composé + imparfait, and the *vous* version for the manager and M. Ferrand. |

## 4. Totals

| Module | New words (1st / 2nd half) | Spoken forms | Dialogues not face to face (of 80) | Channel mix (dialogues) |
|---|---|---|---|---|
| 21 Donner son avis | 25 (13 / 12) | — | 35 | face to face 45, Texto 22, WhatsApp 6, Appel 5, Les copains 2 |
| 22 D'accord ou pas | 25 (13 / 12) | — | 37 | face to face 43, Texto 25, Appel 6, Les copains 3, WhatsApp 3 |
| 23 Expliquer pourquoi | 25 (12 / 13) | — | 38 | face to face 42, Texto 26, WhatsApp 6, Appel 4, Les copains 2 |
| 24 Et si… ? | 25 (13 / 12) | — | 48 | face to face 32, Texto 27, Les copains 10, Appel 7, WhatsApp 4 |
| 25 Un week-end qui déraille | 25 (13 / 12) | — | 39 | face to face 41, Appel 17, Texto 13, Les copains 5, WhatsApp 4 |
| **Arc 5 (21–25)** | **125** | **0** | **197 of 400** | |

The arc is about exchanging views with people Robin knows, so the home scenes are face to face: the flat with Léa (22), the office (21, 23), the café, the landing, the street (21, 23), the restaurant (21) and the gîte (25). Texts, calls and the group chat carry the rest; 24 (planning the weekend) leans most on them.

- **Off the home channel:** every move has at least 2 of its 10 dialogues off its home channel; most have 5–9.
- **No new spoken form:** the *tu* exchanges reuse *t'es, t'as, y a, t'inquiète, pas de souci, top, carrément* from arcs 1–4.
- **Informal words glossed plainly:** the informal words this arc teaches (*bof, pas question, marché conclu, ça m'énerve, tu exagères, au final*) are standard spoken French, glossed plainly (open question 2).
- **Recurrence:** per move, every new word recurs in at least two later dialogues of the same move and gets a later Mot or Mot en retour drill. No item introduces more than two new words.

## 5. Cross-module word progression

Each word is taught once, in the earliest module that needs it. Later modules reuse it freely and never put it back in `newWords`. The right column lists the later arc-5 modules whose sketches reuse it.

| Module | Words taught (book-wide first) | Carried into later arc-5 modules |
|---|---|---|
| 21 | *à mon avis*; *je trouve*; *tu trouves*; *drôle*; *histoire*; *acteurs*; *épicé*; *salé*; *sucré*; *goût*; *animé*; *agréable*; *propre*; *à ton avis*; *ça t'a plu*; *ça m'a plu*; *déteste*; *pas du tout*; *incroyable*; *bof*; *sans plus*; *moyen*; *ça vous a plu*; *excellent*; *déçue* | *drôle* (25); *animé* (22, 23); *déteste* (22); *pas du tout* (22); *bof* (24) |
| 22 | *ménage*; *lessive*; *vaisselle*; *sortir les poubelles*; *je suis d'accord*; *tout à fait*; *exactement*; *je ne suis pas d'accord*; *tu as tort*; *pas question*; *pas forcément*; *en partie*; *je vois ce que tu veux dire*; *tour*; *à tour de rôle*; *ce n'est pas juste*; *je veux bien*; *en échange*; *ça te dérange*; *ranger*; *sale*; *ça m'énerve*; *on est d'accord*; *marché conclu*; *planning* | *ménage* (24); *vaisselle* (24); *tout à fait* (23); *ranger* (24) |
| 23 | *pourquoi pas*; *comment ça*; *pour quelle raison*; *grâce à*; *car*; *puisque*; *c'est pour ça que*; *voilà pourquoi*; *tellement*; *par exemple*; *d'ailleurs*; *en général*; *exprès*; *au cas où*; *but*; *je m'explique*; *c'est-à-dire*; *en fait*; *vieux lyon*; *célèbre*; *traboules*; *fête des lumières*; *occupée*; *ça tombe mal*; *ça tombe bien* | — |
| 24 | *faire le pont*; *jour férié*; *congé*; *et si on*; *montagne*; *randonnée*; *lac*; *météo*; *orage*; *degrés*; *plan b*; *au pire*; *de toute façon*; *louer*; *aller-retour*; *gîte*; *on irait*; *rêve*; *si seulement*; *budget*; *dépenser*; *raisonnable*; *on verra*; *si jamais*; *à la dernière minute* | *lac* (25); *orage* (25); *gîte* (25) |
| 25 | *voie*; *correspondance*; *supprimé*; *en raison de*; *je croyais que*; *malentendu*; *autrement dit*; *boîte à clés*; *draps*; *fonctionne*; *objets trouvés*; *sac à dos*; *récupérer*; *pendant ce temps*; *plantes*; *arroser*; *de mauvaise humeur*; *tu exagères*; *on se calme*; *le bon côté*; *souvenir*; *rire*; *aventure*; *déraillé*; *au final* | — |

**Vocabulary audit.** Each new key was grepped against the *Fondations* answer sentences in `Resources/Topics/*.json` and against the exposure lines of every item in 01–20.
- **No key is printed earlier, and none is a *Fondations* answer phrase.**
- ***Fondations* words stay base** (glossed, never underlined; §8.2): *l'histoire, mer, pleuvoir, serait, irait, s'est, repose*, the *si* sentences (25), *il faut que* (24), *ce serait* (22), *pour que* + subjunctive (24).
- **Kept out because 01–20 already print them** (a taught key would fail the book-order lint): *je comprends, je vois* (10), *pour moi, une autre fois, c'est juste, et si, à cause de ça, juste*.

## 6. Words moved between modules, avoided or deferred

- **From café, arcs 1–4: none moved.** No earlier entry changes, except the one gloss-neutral addition in §2.8 (*s'il pleut* now shows as a phrase in 18 `decide d09`).
- **Within the batch** (taught once, reused later; see §5):
  - 21's *drôle, animé, déteste, pas du tout, bof* → 22–25;
  - 22's *ménage, vaisselle, tour, sortir les poubelles* → 23–24;
  - 23's *au cas où* → 24;
  - 24's *gîte, orage, louer, météo* → 25.
- **Taught in 23 instead of 24:** *au cas où*, because 23 `purpose` needs it ("just in case").
- **Avoided:**
  - spoken or slang forms: *nul, genre, bouffe, hein, bah, oups, sérieux, tu rigoles, rando*;
  - untaught or non-*Fondations* words: *crêpes, joli, chaussures, salon, jardin, hôtel, important, décembre, vacances, fenêtres, argent, quelqu'un, escalier, ascenseur, magnifique, touristes, client*;
  - grammar outside *Fondations*: the plus-que-parfait (*j'avais compris*), the conditionnel passé (*ça aurait pu être pire*), the passive (*a été supprimé*);
  - gloss traps: *ne… que* (*ce n'est qu'un week-end*), *tant mieux* (untaught), *neuf*, *voie B*, *au bord du*, *grâce au*, *s'il y a*, *il va faire beau*, *la météo annonce*.
- **Nothing deferred:** the book ends with 25.

## 7. Grammar recycled from *Fondations*

Book 1 module numbers are in brackets.

**What arc 5 adds from *Fondations*:**
- futur simple (21);
- conditional (22);
- relatives *qui / que / où* (23), used where natural;
- subjunctive after *il faut que / pour que* (24);
- *si* clauses: present + futur and imparfait + conditional, plus the suggestion *si on* + imparfait (25).

**Not taught there, so the sketches avoid it:** the plus-que-parfait, the conditionnel passé, the passive, the gérondif, passé récent *venir de*, *le mien / le tien*, *ne… que*.

- **21:** opinion verbs *je trouve (que)*, *tu trouves ?*, *je pense que* (base) with the present (04, 09); *ça m'a plu / ça t'a plu / ça vous a plu* and *j'ai adoré* in the passé composé with *avoir* (13); description in the imparfait *c'était, les acteurs étaient* (16; Transformer present → imparfait); adjective agreement *drôle(s), épicé(e), salé(e), propre(s), moyen(s), déçue* (07; Corriger on *drôles, délicieux, propre, moyen, incroyables*); comparatives *plus agréable, le meilleur du quartier* (19); relatives *le film que j'ai vu* (23) where natural; object pronouns *je les ai trouvés*, avoided where the gloss would mislead (17); *tu / vous* questions (*Tu trouves ? / Vous trouvez ?*, 03, 06); Robin's feminine *déçue* (Corriger on *déçu*).
- **22:** *il faut + infinitive* and *il faut que* + subjunctive where natural (*il faut que tu fasses la vaisselle*, 24); imperatives *range, rangez, regardez, dites-moi* (20; Transformer *tu → vous* plural); object pronouns *je la fais, je les range, je le fais* (17); futur simple *je ferai la lessive samedi* (21; Transformer); conditional softeners *on pourrait, vous pourriez* (22); *si* + present *dis-moi si tu es d'accord* (25); adjective agreement *petite, sale(s), vrai* (07; Corriger); possessives *ton tour / mon tour* (08; Corriger on *ta tour*); *chacun* + singular (19 review).
- **23:** causes *parce que, car, puisque, comme, grâce à, à cause de* (06, 10); consequences *donc, alors, c'est pour ça que, voilà pourquoi, tellement … que* (06); *pour que* + subjunctive *pour que tu comprennes, pour que tu sois contente* (24; Corriger *es → sois*, Transformer); *pour* + infinitive (06); passé composé and imparfait in explanations *j'ai raté le train, il pleuvait* (13, 16); futur simple *on ira, on visitera* (21; Transformer); imperatives *prends ton parapluie* (20); *pourquoi* questions and the formal *pour quelle raison* (06); adjective agreement *célèbre(s), occupée, fatiguée* (07; Corriger on *occupé, fatigué*).
- **24:** *si* + present + futur simple *s'il fait beau, on ira au lac* (25 with 21; Transformer); *si* + imparfait + conditional *si on avait une voiture, on irait à Annecy* (25 with 22; Transformer, Corriger on *irais*); the suggestion *et si on* + imparfait *et si on partait ?* (25: *si on allait au cinéma*; Transformer); futur simple *on restera, on regardera, je ferai* (21); conditional *je voudrais louer, vous pourriez, ce serait* (22); *il faut* + infinitive and *on peut / on pourrait* (22); *y* in *on y va* (18); *de toute façon / au pire* for alternatives.
- **25:** everything in review. Announcements in formal French *en raison de la grève, le train est supprimé* (Transformer into everyday *à cause de*); the imparfait of mistaken belief *je croyais que le train était à neuf heures* (16; *je croyais* is keyed); the passé composé and imparfait in the final story *on a raté le train, il pleuvait, tout a déraillé* (13, 14, 16; Transformer); object pronouns *je l'ai oublié* with agreement (17; Fill on *oublié / oubliée*); pronominal *on se calme, calmez-vous* (15, 20); imperatives (20); futur simple *ce sera un bon souvenir* (21); conditional *vous pourriez* (22); *pour que* and *si* review (24, 25); repair moves from 03 (*vous pouvez répéter ?*) in every Clarify row.

## 8. Shared base glosses (copy byte for byte)

Arc 1 had 33 gloss conflicts at assembly; arcs 2–4 cut them by giving authors this section. Give it to every author.

### 8.1 Existing `words.json` entries the sketches use in two or more halves

Copied from `words.json` (413 entries). The last column is the halves whose sketches use the entry (21a = module 21 first half), counting every quoted line, filled gap and choice. Copy the entry exactly; never edit it in a draft. Entries used by only one half are not listed: look them up in `words.json`.

| fr | en | spoken | audio | Used by |
|---|---|---|---|---|
| a | has (il a dit = he said) |  | `sitw_a` | 21a, 21b, 23a, 23b, 24a, 24b, 25a, 25b |
| ah | ah / oh |  | `sitw_ah` | 21b, 22b, 25a |
| ah bon | oh really? |  | `sitw_ah_bon` | 21a, 21b, 22a, 23b, 24a, 24b |
| allez | go / are going (to) / are doing (vous) |  | `sitw_allez` | 24a, 25a |
| allons | go (we) |  | `sitw_allons` | 25a, 25b |
| allô | hello? (on the phone) |  | `sitw_allo` | 24b, 25a |
| alors | so / then |  | `sitw_alors` | 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| amie | friend (female) |  | `sitw_amie` | 22b, 23a |
| annulé | cancelled |  | `sitw_annule` | 21a, 24b |
| annulée | cancelled (feminine) |  | `sitw_annulee` | 23a, 24a |
| appartement | flat, apartment |  | `sitw_appartement` | 21a, 21b, 22a, 23a, 24b |
| apporte | bring(s) / am bringing |  | `sitw_apporte` | 22a, 22b |
| apporter | to bring (a thing) |  | `sitw_apporter` | 22a, 22b |
| après | after |  | `sitw_apres` | 22a, 22b, 23a |
| as | have (tu) (tu as pris = you took) |  | `sitw_as` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a |
| attention | attention, care (fais attention = be careful) |  | `sitw_attention` | 21a, 24a |
| au | at the / to the |  | `sitw_au` | 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| au bord de | by, on the banks of |  | `sitw_au_bord_de` | 23a, 24b |
| au fond | at the back, at the end |  | `sitw_au_fond` | 23b, 24a |
| aujourd'hui | today |  | `sitw_aujourd_hui` | 21b, 23a, 23b |
| aussi | also / too |  | `sitw_aussi` | 21a, 21b, 22b, 23a, 24a, 24b |
| aux | to the / at the / with (à + les) |  | `sitw_aux` | 22b, 23a, 23b, 24a, 25a |
| avant | before |  | `sitw_avant` | 22a, 22b, 23b, 24a, 25b |
| avec | with |  | `sitw_avec` | 21a, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| avez | have |  | `sitw_avez` | 22a, 24a, 24b, 25a |
| bar | bar |  | `sitw_bar` | 21a, 21b |
| beau | beautiful, nice |  | `sitw_beau` | 21a, 23b, 24a, 24b, 25b |
| beaucoup | a lot / very much |  | `sitw_beaucoup` | 21b, 22b, 25a, 25b |
| beaux | beautiful (plural) |  | `sitw_beaux` | 21a, 23a, 24a |
| bien | well / good / really, indeed |  | `sitw_bien` | 21a, 21b, 23b, 24b, 25a, 25b |
| bien sûr | of course |  | `sitw_bien_sur` | 22b, 23a, 24b |
| billets | tickets (train) |  | `sitw_billets` | 24a, 24b, 25a |
| bleu | blue |  | `sitw_bleu` | 21b, 25a |
| bon | good / well, OK (c'est bon = it's fine; also: happy) |  | `sitw_bon` | 21a, 21b, 22b, 23b, 24b, 25b |
| bonjour | hello |  | `sitw_bonjour` | 21b, 24b, 25a |
| bonne | good (feminine) |  | `sitw_bonne` | 21a, 21b, 22b, 23a, 23b, 24a, 24b, 25b |
| bons | good (plural) |  | `sitw_bons` | 21a, 21b, 25b |
| bouchon lyonnais | bouchon (Lyon's traditional bistro) |  | `sitw_bouchon_lyonnais` | 21a, 21b, 24b |
| boulangerie | bakery |  | `sitw_boulangerie` | 21a, 21b, 23a |
| bruit | noise |  | `sitw_bruit` | 21b, 22a, 22b, 23a, 25b |
| bruyant | noisy |  | `sitw_bruyant` | 21a, 22a, 22b |
| bruyante | noisy (feminine) |  | `sitw_bruyante` | 21a, 22b |
| bruyants | noisy (plural) |  | `sitw_bruyants` | 21a, 22b |
| bureau | office / desk |  | `sitw_bureau` | 22b, 23a |
| bus | bus |  | `sitw_bus` | 23a, 25a |
| c'est | it is |  | `sitw_c_est` | 21a, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| c'est noté | noted |  | `sitw_c_est_note` | 22a, 22b, 23b, 24b |
| c'est vrai | really? / it's true |  | `sitw_c_est_vrai` | 21a, 22a, 23a |
| c'était | it was |  | `sitw_c_etait` | 21a, 21b, 23a, 25a, 25b |
| café | coffee / café |  | `sitw_cafe` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| calme | quiet, calm |  | `sitw_calme` | 21a, 22a |
| ce | this / that |  | `sitw_ce` | 21a, 21b, 22a, 22b, 23a, 23b, 24b, 25a, 25b |
| ce matin | this morning |  | `sitw_ce_matin` | 21b, 25b |
| ce soir | this evening |  | `sitw_ce_soir` | 21a, 21b, 22a, 22b, 23b, 24a, 25b |
| cet | this (before a vowel) |  | `sitw_cet` | 22a, 25a |
| cette | this (feminine) |  | `sitw_cette` | 21a, 21b, 22b, 25a |
| chambre | bedroom |  | `sitw_chambre` | 22b, 25a |
| chauffage | heating |  | `sitw_chauffage` | 23a, 25a |
| cher | expensive, dear |  | `sitw_cher` | 21b, 22a, 23b, 24b |
| chers | expensive (plural) |  | `sitw_chers` | 21a, 24b |
| chez | at / to (someone's place) |  | `sitw_chez` | 23a, 23b |
| choisit | choose(s) (il, elle, on) |  | `sitw_choisit` | 22b, 23b |
| chère | expensive (feminine) |  | `sitw_chere` | 21a, 22a, 23b, 24b |
| cinq | five |  | `sitw_cinq` | 23b, 24a |
| cinéma | cinema, the movies |  | `sitw_cinema` | 22a, 23a, 23b, 24a |
| clés | keys |  | `sitw_cles` | 23b, 24b, 25a |
| combien | how much / how many |  | `sitw_combien` | 23b, 24a, 24b |
| commence | start(s) |  | `sitw_commence` | 23a, 23b |
| complet | full, fully booked |  | `sitw_complet` | 23b, 24a |
| comprends | understand |  | `sitw_comprends` | 21b, 23a, 23b |
| concert | concert, gig |  | `sitw_concert` | 21a, 21b, 22a, 23a, 23b |
| contente | happy (feminine) |  | `sitw_contente` | 23b, 25b |
| courses | food shopping |  | `sitw_courses` | 22b, 23a, 23b |
| cuisine | kitchen / cook(s) |  | `sitw_cuisine` | 22a, 22b, 23b |
| d'accord | OK, agreed |  | `sitw_d_accord` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| dans | in |  | `sitw_dans` | 22b, 23b, 25a, 25b |
| de | of / from / some / to (+ verb) |  | `sitw_de` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| demain | tomorrow |  | `sitw_demain` | 21a, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| demande | ask / asks |  | `sitw_demande` | 22a, 22b, 23a |
| des | some / of the |  | `sitw_des` | 23a, 23b, 24a, 24b |
| dessert | dessert, pudding |  | `sitw_dessert` | 21a, 21b |
| deux | two |  | `sitw_deux` | 23a, 23b, 24a, 25a, 25b |
| deuxième | second |  | `sitw_deuxieme` | 21b, 24a, 25a |
| devant | in front of, outside |  | `sitw_devant` | 22a, 22b, 23a, 23b |
| devrais | should (je, tu) |  | `sitw_devrais` | 22b, 23a |
| devrait | should (il, elle) |  | `sitw_devrait` | 22b, 23a |
| devriez | should (vous) |  | `sitw_devriez` | 22b, 23a |
| dimanche | Sunday |  | `sitw_dimanche` | 22a, 22b, 23a, 23b, 24a, 24b |
| dis | say, tell |  | `sitw_dis` | 21a, 22a, 23a, 25a |
| dit | says / said |  | `sitw_dit` | 24a, 25b |
| dix | ten |  | `sitw_dix` | 22b, 23b, 24b, 25a |
| dois | have to, must (je, tu) |  | `sitw_dois` | 22b, 23b, 24b |
| dommage | what a shame |  | `sitw_dommage` | 21b, 23b, 25b |
| du | some / of the / from the |  | `sitw_du` | 21a, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| déjà | already |  | `sitw_deja` | 23a, 25b |
| délicieuse | delicious (feminine) |  | `sitw_delicieuse` | 21a, 21b, 23a, 23b |
| délicieuses | delicious (feminine plural) |  | `sitw_delicieuses` | 21a, 21b |
| délicieux | delicious |  | `sitw_delicieux` | 21a, 21b, 23b |
| désolée | sorry (feminine) |  | `sitw_desolee` | 22b, 23a, 23b, 24b, 25a, 25b |
| dîner | dinner |  | `sitw_diner` | 22a, 22b, 23b |
| elle | she / it |  | `sitw_elle` | 21a, 21b, 22a, 22b, 23a, 23b, 25a, 25b |
| en | in, by / some, of it, of them (pronoun) |  | `sitw_en` | 23a, 24a, 24b, 25b |
| en ligne | online |  | `sitw_en_ligne` | 22b, 23a |
| en panne | broken / out of order |  | `sitw_en_panne` | 22b, 23a, 25a |
| en retard | late |  | `sitw_en_retard` | 22b, 23a, 23b, 25a |
| en télétravail | working from home |  | `sitw_en_teletravail` | 23a, 23b |
| encore | still / again / more |  | `sitw_encore` | 22a, 22b, 23b, 24b, 25a, 25b |
| ennuyeuse | boring (feminine) |  | `sitw_ennuyeuse` | 21a, 21b, 22a |
| ennuyeuses | boring (feminine plural) |  | `sitw_ennuyeuses` | 21b, 22a |
| ennuyeux | boring |  | `sitw_ennuyeux` | 21b, 22a, 23a |
| ensemble | together |  | `sitw_ensemble` | 22a, 23b, 24a, 25b |
| entre | come in! (tu) / between, among |  | `sitw_entre` | 23b, 25b |
| es | are (tu) (tu es allée = you went) |  | `sitw_es` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| est | is (il est allé = he went) |  | `sitw_est` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| et | and |  | `sitw_et` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| excusez-moi | sorry / excuse me (vous) |  | `sitw_excusez_moi` | 21a, 22a, 22b, 23a, 24b, 25a |
| faire | do / make |  | `sitw_faire` | 22a, 22b, 23a, 24a |
| fais | do / make (je, tu) |  | `sitw_fais` | 21a, 22a, 22b, 23a, 23b, 24a, 25b |
| fait | does / makes / done, made / comes to (weather: il fait froid = it's cold) |  | `sitw_fait` | 22b, 23a, 23b, 24a, 25a, 25b |
| fatigué | tired |  | `sitw_fatigue` | 23a, 23b, 24a, 25b |
| fatiguée | tired (feminine) |  | `sitw_fatiguee` | 21b, 23a, 23b |
| faute | fault |  | `sitw_faute` | 23a, 25b |
| fermée | closed (feminine) |  | `sitw_fermee` | 22a, 25a |
| ferrand | Ferrand (surname) |  | `sitw_ferrand` | 22b, 23b, 25b |
| film | film, movie |  | `sitw_film` | 21a, 21b, 22b, 23a, 24b, 25b |
| franchement | honestly, frankly |  | `sitw_franchement` | 21a, 21b, 24b |
| frigo | fridge |  | `sitw_frigo` | 22b, 23a |
| froid | cold |  | `sitw_froid` | 24a, 25a |
| fuite | leak |  | `sitw_fuite` | 23a, 25b |
| gare | station |  | `sitw_gare` | 21a, 22a, 23a, 23b, 24a, 24b, 25a |
| gentil | kind |  | `sitw_gentil` | 22a, 22b, 25b |
| gentille | kind (feminine) |  | `sitw_gentille` | 22a, 22b, 23b, 25b |
| gentils | kind (plural) |  | `sitw_gentils` | 22a, 22b, 25b |
| grand | large |  | `sitw_grand` | 22a, 23a, 24a |
| grande | large (feminine) |  | `sitw_grande` | 23a, 24b |
| grave | serious |  | `sitw_grave` | 23a, 25b |
| grève | strike |  | `sitw_greve` | 23a, 25a, 25b |
| génial | great |  | `sitw_genial` | 21a, 21b, 22a, 23b, 24a, 24b, 25b |
| géniale | great (feminine) |  | `sitw_geniale` | 21b, 22a, 23b, 25b |
| géniaux | great (plural) |  | `sitw_geniaux` | 21b, 22a, 23b, 25b |
| heures | o'clock / hours (deux heures de bus = two hours on the bus) |  | `sitw_heures` | 22a, 22b, 23a, 23b, 24a, 24b, 25a |
| huit | eight |  | `sitw_huit` | 22b, 23a, 23b, 24a, 24b, 25a |
| ici | here (on the phone: this is) |  | `sitw_ici` | 21a, 22a, 22b, 23a, 23b, 24a, 25a, 25b |
| idée | idea |  | `sitw_idee` | 21b, 22b, 23a, 23b, 24a, 24b, 25b |
| idées | ideas |  | `sitw_idees` | 22b, 23a, 25b |
| il | he / it |  | `sitw_il` | 21a, 21b, 22a, 23a, 23b, 24a, 24b, 25a, 25b |
| il fait beau | the weather's nice |  | `sitw_il_fait_beau` | 24a, 25b |
| il faut | you have to, you need (to) |  | `sitw_il_faut` | 22a, 24a, 24b |
| il pleut | it's raining |  | `sitw_il_pleut` | 23a, 24b, 25b |
| il y a | there is / there are (il y a dix minutes = ten minutes ago) |  | `sitw_il_y_a` | 21a, 22a, 23a, 23b, 24a, 25b |
| ils | they |  | `sitw_ils` | 21a, 25a |
| inès | Inès |  | `sitw_ines` | 21b, 22b, 23a, 23b, 25a, 25b |
| j'adore | I love |  | `sitw_j_adore` | 21a, 21b, 23b |
| j'ai | I have (j'ai dit = I said) |  | `sitw_j_ai` | 21a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| j'aime bien | I quite like / I like |  | `sitw_j_aime_bien` | 21a, 22b |
| j'appelle | I call, I'm calling |  | `sitw_j_appelle` | 23a, 25a |
| j'apporte | I'm bringing / shall I bring |  | `sitw_j_apporte` | 23a, 24a |
| j'arrive | I'm coming, I'm on my way / I arrive |  | `sitw_j_arrive` | 23a, 23b |
| je | I |  | `sitw_je` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| je la | I … it / her |  | `sitw_je_la` | 22a, 22b |
| je le | I … it / him |  | `sitw_je_le` | 21a, 22a, 22b, 23a, 24b |
| je les | I … them |  | `sitw_je_les` | 23b, 24b |
| je peux | I can |  | `sitw_je_peux` | 24a, 25a, 25b |
| je prends | I'll have / I'll take, I take |  | `sitw_je_prends` | 21b, 23a, 23b, 24a |
| je t'invite | it's my treat, I'm inviting you |  | `sitw_je_t_invite` | 22a, 22b |
| je voudrais | I would like |  | `sitw_je_voudrais` | 24a, 24b |
| jeudi | Thursday |  | `sitw_jeudi` | 22b, 23a, 23b, 24a, 24b, 25a |
| jour | day |  | `sitw_jour` | 22a, 23b, 24a, 24b |
| journée | day |  | `sitw_journee` | 21b, 23b, 24a |
| jours | days |  | `sitw_jours` | 23b, 24a, 24b |
| karim | Karim |  | `sitw_karim` | 21b, 22a, 23a |
| l'appartement | the flat |  | `sitw_l_appartement` | 21b, 23b |
| l'expo | the exhibition |  | `sitw_l_expo` | 21b, 22a |
| l'heure | the time |  | `sitw_l_heure` | 23a, 23b |
| la | the (feminine) / it, her |  | `sitw_la` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| laisse | leave(s) (je, tu, il, elle) |  | `sitw_laisse` | 22b, 23b, 24b |
| le | the (masculine) / it, him |  | `sitw_le` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| le dimanche | on Sundays / (on) Sunday |  | `sitw_le_dimanche` | 22a, 23a, 23b, 25a |
| le matin | in the morning / the morning |  | `sitw_le_matin` | 21b, 22a, 23a |
| le soir | in the evening / the evening |  | `sitw_le_soir` | 21a, 22a, 22b |
| le week-end | at the weekend / the weekend |  | `sitw_le_week_end` | 22b, 24a, 24b, 25b |
| les | the (plural) / them |  | `sitw_les` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| libre | free (not busy) |  | `sitw_libre` | 23a, 23b, 24b, 25a |
| long | long |  | `sitw_long` | 21a, 21b, 23a, 24a |
| longs | long (plural) |  | `sitw_longs` | 21b, 24a |
| longue | long (feminine) |  | `sitw_longue` | 21a, 21b, 22a, 24a |
| lumineux | bright, full of light |  | `sitw_lumineux` | 21a, 21b, 22a, 24b |
| lundi | Monday |  | `sitw_lundi` | 22a, 22b, 23a, 23b, 24a, 25a |
| lyon | Lyon |  | `sitw_lyon` | 23b, 24a, 24b, 25b |
| là | there / here |  | `sitw_la_there` | 22b, 23a, 23b, 25a |
| léa | Léa |  | `sitw_lea` | 21a, 22a, 22b, 24a, 25b |
| m'a | has … me |  | `sitw_m_a` | 23a, 25b |
| M. | Mr |  | `sitw_m` | 22b, 23b, 25b |
| ma | my (feminine) |  | `sitw_ma` | 21a, 21b, 22b, 23a, 25b |
| machine à laver | washing machine |  | `sitw_machine_a_laver` | 21b, 25a |
| madame | madam / Mrs |  | `sitw_madame` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| maintenant | now |  | `sitw_maintenant` | 21a, 21b, 22a, 23a, 24b, 25a |
| mais | but |  | `sitw_mais` | 21a, 21b, 22a, 23a, 23b, 24a, 24b, 25a, 25b |
| malade | ill, sick |  | `sitw_malade` | 23a, 25b |
| malheureusement | unfortunately |  | `sitw_malheureusement` | 23a, 25a |
| mange | eat / eats |  | `sitw_mange` | 22b, 23b, 25b |
| marche | works (ça marche = that works) |  | `sitw_marche` | 21b, 22a, 23a, 23b, 25a |
| marcher | to walk / to work (machine) |  | `sitw_marcher` | 21b, 22a, 23b, 25a |
| marches | work (tu) |  | `sitw_marches` | 21b, 25a |
| marché | market |  | `sitw_marche_market` | 21a, 22a, 22b, 23a, 23b |
| mardi | Tuesday |  | `sitw_mardi` | 21b, 22a, 23b, 25b |
| matin | morning |  | `sitw_matin` | 21b, 22b, 23b, 24a, 24b, 25a |
| mauvais | bad |  | `sitw_mauvais` | 21b, 25b |
| me | me, (to) me / myself |  | `sitw_me` | 24b, 25b |
| meilleur | better, best |  | `sitw_meilleur` | 21a, 21b, 22a, 23a, 25b |
| merci | thank you |  | `sitw_merci` | 21a, 21b, 22a, 22b, 23b, 25a, 25b |
| mes | my (plural) |  | `sitw_mes` | 22b, 25a, 25b |
| mieux | better |  | `sitw_mieux` | 21b, 22a |
| mince | darn, oh no |  | `sitw_mince` | 23b, 24a, 25a, 25b |
| moi | me |  | `sitw_moi` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25b |
| moi aussi | me too |  | `sitw_moi_aussi` | 21a, 21b, 22a, 22b, 23a |
| moins | less / minus |  | `sitw_moins` | 22a, 23b, 24b |
| mon | my (masculine, or before a vowel) |  | `sitw_mon` | 21a, 21b, 22a, 22b, 23a, 23b, 24b, 25a |
| monde | people / world |  | `sitw_monde` | 21a, 21b, 23a, 23b |
| monsieur | sir / Mr |  | `sitw_monsieur` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| musique | music |  | `sitw_musique` | 21b, 22b |
| musée | museum |  | `sitw_musee` | 23a, 24a, 24b |
| métro | underground, subway |  | `sitw_metro` | 22a, 22b, 23a, 24a |
| n'aime | like (n'aime pas = don't like) |  | `sitw_n_aime` | 21a, 21b, 24a |
| n'es | are (tu) (n'es pas = aren't) |  | `sitw_n_es` | 21b, 23a, 25a |
| n'est | is (n'est pas = isn't) |  | `sitw_n_est` | 21a, 21b, 22a, 23a, 24a, 25b |
| ne | (negation word: ne … pas = not, ne … rien = nothing, ne … jamais = never, ne … plus = no more) |  | `sitw_ne` | 21a, 21b, 22a, 23a, 23b, 24b, 25a, 25b |
| non | no / right? |  | `sitw_non` | 21a, 21b, 22a, 22b, 23b, 24a, 24b, 25a, 25b |
| non plus | either / neither (after a negative) |  | `sitw_non_plus` | 21a, 22b, 23a, 24a, 24b |
| notre | our |  | `sitw_notre` | 21a, 24a, 24b, 25a |
| nous | we / us |  | `sitw_nous` | 22a, 24a, 25a, 25b |
| nouveau | new |  | `sitw_nouveau` | 21a, 21b, 22b, 25b |
| oh | oh |  | `sitw_oh` | 23a, 23b, 24a, 24b, 25a, 25b |
| on | we / one | yes | `sitw_on` | 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| on a | we have (on a mangé = we ate) |  | `sitw_on_a` | 24a, 24b, 25a, 25b |
| on est | we are (on est allés = we went) |  | `sitw_on_est` | 24b, 25b |
| on fait | we do, we make / we're doing |  | `sitw_on_fait` | 22a, 22b, 23a, 23b, 24a |
| on pourrait | we could |  | `sitw_on_pourrait` | 22b, 23a, 24b |
| on se retrouve | we meet up |  | `sitw_on_se_retrouve` | 22a, 23b, 24a |
| on va | we're going (to) / let's go |  | `sitw_on_va` | 21b, 22a, 23a, 23b, 24a, 24b, 25a, 25b |
| on y va | let's go / shall we go? |  | `sitw_on_y_va` | 22a, 23b, 24a |
| ou | or |  | `sitw_ou` | 21a, 24a, 24b, 25a |
| oublié | forgotten, forgot |  | `sitw_oublie` | 23a, 25a |
| oui | yes |  | `sitw_oui` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| ouvert | open |  | `sitw_ouvert` | 23a, 24b |
| ouverte | open (feminine) |  | `sitw_ouverte` | 23a, 24b |
| ouverts | open (plural) |  | `sitw_ouverts` | 23a, 24b, 25a |
| où | where |  | `sitw_ou_where` | 23a, 23b, 24a, 24b, 25a |
| pain | bread |  | `sitw_pain` | 21a, 21b, 23a, 23b |
| par | by / per |  | `sitw_par` | 21b, 22a, 23a, 24b |
| parapluie | umbrella |  | `sitw_parapluie` | 21a, 23b |
| pardon | sorry / excuse me |  | `sitw_pardon` | 21a, 22b, 25a, 25b |
| parfait | perfect |  | `sitw_parfait` | 21a, 22a, 22b, 23b, 24a, 24b |
| parfaite | perfect (feminine) |  | `sitw_parfaite` | 21a, 24a |
| pars | leave (je, tu) |  | `sitw_pars` | 22b, 23a, 23b, 24a, 24b |
| part | leaves |  | `sitw_part` | 22a, 22b, 23a, 23b, 24a, 24b, 25a |
| partez | leave (vous) |  | `sitw_partez` | 23a, 24a, 24b |
| partir | to leave |  | `sitw_partir` | 23a, 24a |
| pas | not (pas de … = no …) |  | `sitw_pas` | 21a, 21b, 22a, 23a, 23b, 24a, 24b, 25a, 25b |
| pas de problème | no problem |  | `sitw_pas_de_probleme` | 22a, 22b |
| pas grave | no big deal, never mind |  | `sitw_pas_grave` | 22b, 23b, 25b |
| pas terrible | not great |  | `sitw_pas_terrible` | 21a, 21b |
| pas trop | not too (much) / not really |  | `sitw_pas_trop` | 21a, 24a, 24b |
| payer | to pay |  | `sitw_payer` | 22a, 22b, 23b |
| petit | small, little (masculine) |  | `sitw_petit` | 22a, 24b |
| peut | can |  | `sitw_peut` | 24a, 24b |
| peut-être | maybe |  | `sitw_peut_etre` | 23b, 24a, 24b, 25b |
| peux | can (je / tu) |  | `sitw_peux` | 23a, 23b, 24a, 25b |
| pique-nique | picnic |  | `sitw_pique_nique` | 22a, 23a, 23b, 24a |
| pire | worse |  | `sitw_pire` | 21a, 24a |
| plat | dish |  | `sitw_plat` | 21a, 21b |
| plein | full (plein de = lots of) |  | `sitw_plein` | 21a, 21b, 22a, 23a, 24a, 24b, 25b |
| plein de | lots of |  | `sitw_plein_de` | 21a, 22a, 23a, 23b, 25b |
| plombier | plumber |  | `sitw_plombier` | 21a, 21b, 23a, 23b, 25b |
| pluie | rain |  | `sitw_pluie` | 21b, 23b, 24a, 25b |
| plus | more / most (ne … plus = no more, no longer) |  | `sitw_plus` | 21a, 21b, 22a, 23a, 24a, 24b, 25b |
| portable | mobile (phone) |  | `sitw_portable` | 23a, 25a |
| porte | door |  | `sitw_porte` | 22b, 23b, 25a |
| possible | possible |  | `sitw_possible` | 23b, 24a |
| pour | for / (in order) to |  | `sitw_pour` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a |
| pourquoi | why |  | `sitw_pourquoi` | 22a, 23a, 23b |
| pralines | pralines (pink sugared almonds, a Lyon speciality) |  | `sitw_pralines` | 21a, 22b, 23a, 23b |
| pratique | practical, handy |  | `sitw_pratique` | 23a, 24b |
| premier | first |  | `sitw_premier` | 21a, 21b, 22a |
| prend | take(s), have (on, il, elle) |  | `sitw_prend` | 22b, 23a, 24b, 25a |
| prendre | to have / to take |  | `sitw_prendre` | 22b, 23a, 25a |
| prends | take / have / get (je, tu) |  | `sitw_prends` | 21a, 22b, 23a, 23b, 24a, 25a |
| prix | price, prices |  | `sitw_prix` | 21a, 22b, 24b |
| prochain | next |  | `sitw_prochain` | 25a, 25b |
| prochaine | next (feminine) |  | `sitw_prochaine` | 22b, 23b, 25a |
| près | near, close (près de = near) |  | `sitw_pres` | 22a, 24a, 24b |
| préfères | prefer (tu) |  | `sitw_preferes` | 21a, 24a |
| prêt | ready |  | `sitw_pret` | 22a, 24b |
| pull | jumper, sweater |  | `sitw_pull` | 21a, 21b, 23b, 24a |
| qu'il | that he / that it |  | `sitw_qu_il` | 21a, 24a |
| qu'il y a | that there is / that there are |  | `sitw_qu_il_y_a` | 24a, 25a |
| quand | when |  | `sitw_quand` | 21a, 22a, 23a, 23b, 24b, 25a |
| quartier | neighbourhood |  | `sitw_quartier` | 21a, 21b, 22a, 23a |
| que | that / which / than |  | `sitw_que` | 21b, 22a, 23b |
| quel | which / what |  | `sitw_quel` | 22a, 23b, 24b, 25a |
| quelle | which / what (a) (feminine) |  | `sitw_quelle` | 23a, 23b, 24b, 25a, 25b |
| quelle heure | what time |  | `sitw_quelle_heure` | 21b, 23b, 25a |
| quelque chose | something |  | `sitw_quelque_chose` | 23b, 25b |
| qui | who |  | `sitw_qui` | 22a, 22b, 23a, 23b, 24a |
| quoi | what (informal) |  | `sitw_quoi` | 22b, 23a, 23b, 24a |
| rapide | quick, fast |  | `sitw_rapide` | 22a, 23a |
| raté | missed (a bus, a train) |  | `sitw_rate` | 23a, 25a, 25b |
| regarde | watch / look (at) / check |  | `sitw_regarde` | 22a, 22b, 24a, 24b, 25a, 25b |
| rentre | go / come home, goes / comes home |  | `sitw_rentre` | 23a, 23b, 24a, 24b |
| restaurant | restaurant |  | `sitw_restaurant` | 21a, 21b, 22a, 22b, 24b, 25b |
| reste | stay(s) / remains |  | `sitw_reste` | 21b, 24a, 24b |
| rester | to stay |  | `sitw_rester` | 21b, 22b, 25a |
| restes | stay (tu) |  | `sitw_restes` | 21b, 24b |
| réserve | book / books (reserve) |  | `sitw_reserve` | 24a, 24b |
| réserver | to book, reserve |  | `sitw_reserver` | 24a, 24b |
| réserves | book (tu) |  | `sitw_reserves` | 24a, 24b |
| réunion | meeting |  | `sitw_reunion` | 21a, 21b, 22a, 22b, 23a, 23b, 24a |
| s'il te plaît | please (to a friend) |  | `sitw_s_il_te_plait` | 22a, 22b, 23a, 24a, 24b, 25b |
| s'il vous plaît | please (vous) |  | `sitw_s_il_vous_plait` | 22b, 24b, 25b |
| sais | know (je, tu) |  | `sitw_sais` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| salut | hi / bye (informal, tu) |  | `sitw_salut` | 21b, 23b, 24b |
| samedi | Saturday |  | `sitw_samedi` | 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| sans | without |  | `sitw_sans` | 23b, 25b |
| se | oneself / each other |  | `sitw_se` | 22a, 25b |
| semaine | week |  | `sitw_semaine` | 22b, 23b, 24a, 24b |
| sera | will be |  | `sitw_sera` | 25a, 25b |
| si | if / yes (to a negative) |  | `sitw_si` | 22b, 24a, 24b |
| six | six |  | `sitw_six` | 22a, 23a, 25a |
| soir | evening |  | `sitw_soir` | 22a, 23b, 24a, 25a |
| son | his / her / its |  | `sitw_son` | 23a, 25a |
| sont | are (plural) (ils sont allés = they went) |  | `sitw_sont` | 21a, 21b, 23b, 25a |
| sous | under |  | `sitw_sous` | 24b, 25b |
| suis | am (je suis allée = I went) |  | `sitw_suis` | 21b, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| super | great / really (super rapide = really fast) |  | `sitw_super` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| sur | on / about |  | `sitw_sur` | 21a, 22b, 24b, 25a, 25b |
| surtout | above all, especially |  | `sitw_surtout` | 21a, 21b |
| sympa | nice, friendly |  | `sitw_sympa` | 21a, 25b |
| sûre | sure (feminine) |  | `sitw_sure` | 21a, 24b |
| t'as | you have (tu as) | yes | `sitw_t_as` | 22a, 24b |
| t'inquiète | don't worry | yes | `sitw_t_inquiete` | 23b, 24a, 25b |
| ta | your (informal, feminine) |  | `sitw_ta` | 22a, 22b, 25b |
| tard | late |  | `sitw_tard` | 21a, 21b, 22b, 23b |
| tarte | tart, pie |  | `sitw_tarte` | 21a, 21b, 22b, 23a, 23b |
| te | you, (to / for) you / yourself (informal) |  | `sitw_te` | 21a, 21b, 23a, 25a, 25b |
| temps | time / weather |  | `sitw_temps` | 22a, 24b |
| thé | tea |  | `sitw_the` | 21b, 23a, 25b |
| théo | Théo |  | `sitw_theo` | 22a, 23a, 23b, 24a, 24b, 25a, 25b |
| toi | you (informal) |  | `sitw_toi` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| ton | your (informal) |  | `sitw_ton` | 21a, 21b, 22a, 22b, 23a, 23b, 24b, 25a, 25b |
| top | great | yes | `sitw_top` | 21a, 21b, 22a, 25b |
| toujours | still / always (il est toujours en retard = it's always late) |  | `sitw_toujours` | 22a, 22b, 24b |
| tous | all |  | `sitw_tous` | 24b, 25b |
| tout | all / everything |  | `sitw_tout` | 22a, 24a, 25a, 25b |
| tout de suite | right away |  | `sitw_tout_de_suite` | 22a, 22b, 23b |
| tout à coup | suddenly, all of a sudden |  | `sitw_tout_a_coup` | 22a, 22b, 23b |
| train | train |  | `sitw_train` | 23a, 24a, 24b, 25a, 25b |
| travail | work, job |  | `sitw_travail` | 23a, 23b |
| travaille | work / works |  | `sitw_travaille` | 22b, 23a, 23b |
| trois | three |  | `sitw_trois` | 24a, 24b, 25a |
| trop | too / too much |  | `sitw_trop` | 21a, 21b, 22a, 22b, 23b, 24a, 24b, 25b |
| trouvé | found |  | `sitw_trouve_past` | 23a, 24b |
| très | very |  | `sitw_tres` | 21a, 21b, 22a, 22b, 23b, 24a, 25b |
| très bien | very well / very good |  | `sitw_tres_bien` | 21a, 23b, 25b |
| tu | you (friend) |  | `sitw_tu` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| tu as eu raison | you were right |  | `sitw_tu_as_eu_raison` | 22a, 25b |
| tu as raison | you're right (tu) |  | `sitw_tu_as_raison` | 22a, 25b |
| tu peux | you can / can you? (tu) |  | `sitw_tu_peux` | 22a, 22b, 23a, 23b, 25a, 25b |
| tôt | early |  | `sitw_tot` | 21b, 22a, 22b, 23a, 24a |
| un | a / one |  | `sitw_un` | 21a, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| un peu | a little |  | `sitw_un_peu` | 21a, 21b, 22b, 23a, 24a, 25b |
| une | a / one |  | `sitw_une` | 21a, 22a, 22b, 23a, 23b, 24a, 24b, 25b |
| va | goes / go! (tu) / is going to / is doing / suits |  | `sitw_va` | 21a, 21b, 22a, 23b, 24a, 24b, 25b |
| vais | go / am going (to) |  | `sitw_vais` | 21a, 22a, 22b, 23a, 23b, 24a, 25a |
| vas | go / are going (to) / are doing (tu) |  | `sitw_vas` | 21a, 21b, 23b, 24a, 24b, 25a |
| vendredi | Friday |  | `sitw_vendredi` | 23b, 24a |
| venir | to come |  | `sitw_venir` | 23b, 25a |
| veut | wants |  | `sitw_veut` | 24a, 24b |
| veux | want |  | `sitw_veux` | 22a, 23b, 24a, 24b |
| viens | come (je / tu) |  | `sitw_viens` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 25b |
| vient | comes / is coming |  | `sitw_vient` | 23a, 23b |
| vingt | twenty |  | `sitw_vingt` | 24a, 24b |
| voir | to see |  | `sitw_voir` | 21a, 23b |
| vois | see (je, tu) |  | `sitw_vois` | 21a, 23a, 24b |
| voisin | neighbour |  | `sitw_voisin` | 22b, 23a |
| voiture | car |  | `sitw_voiture` | 23a, 24b |
| vont | go / are going (to) (ils, elles) |  | `sitw_vont` | 21a, 21b, 24a, 25b |
| votre | your (polite / plural) |  | `sitw_votre` | 21b, 22b, 24b, 25a, 25b |
| vous | you (polite / plural), (to / for) you / yourself |  | `sitw_vous` | 21a, 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| vous pouvez | you can / can you? (vous) |  | `sitw_vous_pouvez` | 23a, 23b, 25a, 25b |
| vraiment | really |  | `sitw_vraiment` | 21a, 24b, 25b |
| vu | seen |  | `sitw_vu` | 21a, 22b, 23b, 24a, 25a, 25b |
| vélo | bike |  | `sitw_velo` | 21b, 22a, 22b, 23a |
| week-end | weekend |  | `sitw_week_end` | 22a, 22b, 24b, 25b |
| y | there |  | `sitw_y` | 21b, 23a, 24a, 25a |
| à | to / at |  | `sitw_a_prep` | 21b, 22a, 22b, 23a, 23b, 24a, 24b, 25a, 25b |
| à côté de | next to |  | `sitw_a_cote_de` | 23a, 25a |
| à la maison | (at) home |  | `sitw_a_la_maison` | 21b, 23a, 24b |
| à ta place | in your place, if I were you (tu) |  | `sitw_a_ta_place` | 21a, 21b |
| à votre place | if I were you (vous) |  | `sitw_a_votre_place` | 21a, 21b |
| ça | that / it |  | `sitw_ca` | 21a, 21b, 25b |
| ça me va | that suits me |  | `sitw_ca_me_va` | 23b, 24a |
| ça te va | does that suit you? / it suits you (tu) |  | `sitw_ca_te_va` | 22b, 24a |
| ça va | how are you? / I'm fine / it's fine |  | `sitw_ca_va` | 23a, 25b |
| électrique | electric |  | `sitw_electrique` | 21b, 23a |
| énervant | annoying |  | `sitw_enervant` | 22b, 25a |
| énervante | annoying (feminine) |  | `sitw_enervante` | 22b, 25a |
| énervants | annoying (plural) |  | `sitw_enervants` | 22b, 25a |
| étaient | were (ils, elles) |  | `sitw_etaient` | 21a, 21b |
| étais | was (je, tu) |  | `sitw_etais` | 21a, 21b, 25a |
| était | was |  | `sitw_etait` | 21a, 21b, 22a, 24b, 25a, 25b |
| été | been |  | `sitw_ete` | 21a, 21b |
| êtes | are (vous) (vous êtes allés = you went) |  | `sitw_etes` | 21b, 22b, 23a, 23b, 24a, 25b |
| être | be |  | `sitw_etre` | 23b, 25b |

### 8.2 New base entries this batch needs (not in `words.json` yet)

**Fondations words.** These are *Fondations* tokens the sketches use that `words.json` does not have yet. All have `firstSeen: null` and `spoken: false`. Use exactly these values in every half that needs them.

| fr | en | audio | Needed in |
|---|---|---|---|
| boit | drinks (on boit = we drink) | `sitw_boit` | 25 |
| chambres | bedrooms | `sitw_chambres` | 24, 25 |
| choisi | chosen, chose | `sitw_choisi` | 23 |
| finis | finish, finished (je, tu) | `sitw_finis` | 23 |
| irait | would go (il, on) | `sitw_irait` | 24 |
| l'aime | like it, love it / like him, like her | `sitw_l_aime` | 21 |
| l'histoire | the story | `sitw_l_histoire` | 21 |
| mer | sea | `sitw_mer` | 24 |
| nouvelle | new (feminine) | `sitw_nouvelle` | 21 |
| pleuvoir | to rain | `sitw_pleuvoir` | 21, 23, 24 |
| qu'elle | that she / that it | `sitw_qu_elle` | 21 |
| repose | rest(s) (on se repose = let's rest) | `sitw_repose` | 22, 25 |
| s'est | (reflexive) has (ça s'est bien passé = it went well) | `sitw_s_est` | 22, 23, 25 |
| serait | would be (ce serait = it would be) | `sitw_serait` | 24 |

**Base phrase keys** (§2.8; `firstSeen: null`): *s'il fait beau* = "if the weather's nice" `sitw_s_il_fait_beau` (23, 24); *s'il pleut* = "if it rains" `sitw_s_il_pleut` (23, 24, 25); *plus tôt* = "earlier" `sitw_plus_tot` (22, 23, 24).

They need audio from a plain `generate_audio.py` run.

### 8.3 Inflections

Each matrix ends with a glossed table of the inflections and distractor forms its sketches use that are neither in `words.json` nor *Fondations* answers, with audio keys.
- They follow the `words.json` habit (*désolée* = "sorry (feminine)").
- A wrong form a Corriger or Fill decoy needs is glossed "(wrong form of …)", as with *vaisselles, ensembles, déraillée*.
- A form is listed once, in the earliest module that uses it; a later module's half copies it.

Totals: 21: 32, 22: 27, 23: 29, 24: 50, 25: 44.

## 9. How each matrix blocks the judges' recurring errors

| Error class | Whole batch | 21 | 22 | 23 | 24 | 25 |
|---|---|---|---|---|---|---|
| **Glosses wrong in context** | §2.8: every token segmented; risky keys flagged in each matrix's gloss-check column; authors run the dump self-check (§11 step 2) and judges get the dump. | *je trouve* opinion only; *ça … plu* never split; *propre* = clean. | *sortir les poubelles* keyed; no « tu n'es pas d'accord »; *juste* never bare. | *grâce à* never + *le*; *marche* never "walk"; no plural *bouchons lyonnais*. | *faire le pont* infinitive only; *et si on*; no *plus de* + noun; *il fait beau*, not *il va faire beau*. | *en raison de la / de l'*; no *d'arroser*; *rire* inflections. |
| **Hidden valid replies** | Every *Clarify* row asks the author to accept the reply with and without « Pardon, ». Two-clause model replies need both orders in `accepted` or a bank that fixes the order. Fill distractors were chosen so only one is valid French in context; valid candidates were swapped out (*pareil* after *moi*, *triste*, *dur*, *tant pis*, *on ira*, *un aller*, *demain*, *au moins*, *en plus*, *ça va*). | *Moi ___ !* (aussi / non plus / plus); *J'adore les ___* (desserts / dessert / tarte). | *Pas ___ !* style decoys never include a second valid adverb; *je les sors* avoided. | *grâce à / à côté de / au bord de* (no *à cause de*). | *Si seulement… on ___* (irait / irais / iraient), never *ira*. | *je l'ai ___* (oublié / oubliée / oublier): the bag is masculine. |
| **Standalone place labels** | Every standalone row carries its own place (§2.2). | `film s02` WhatsApp · Mme Dumas; `food s04` Sur le palier. | `chores s02` WhatsApp · Mme Dumas; `deal s04` Sur le palier. | `purpose s04` Appel · Théo. | `book s02` Appel · gîte; `etsi s02` Sur le palier. | `home s02` Sur le palier; `lost s02` À la gare. |
| **Cue leaks and answer echo** | The cue never states what a Comprendre asks or prints a Fill answer. A Répondre model never repeats the server's key line word for word (22 `settle d10` was changed for that). | The cue never names the opinion. | The cue never says who does which chore. | The cue never gives the reason. | The cue never gives the forecast or the price. | The cue never gives the track or the time. |
| **A speaker answering their own question** | Where a question needs an answer, the other speaker asks and Robin answers, or Robin's printed line asks. Two-speaker rows set `followUpBy` (§2.3). | | | | | 25 `group d02`, `annonce d02/d03/d07`. |
| **« Repeat » asked of a text** | *Clarify* rows are face to face or live calls only (validator). Group-chat and texting moves put theirs on a call. | `opinion`, `food`, `ask`, `strong`, `mixed` d05 are calls. | `chores`, `soften`, `turns`, `deal`, `complain` d05 are calls. | `why`, `so`, `purpose` d05 are calls. | `pont`, `etsi`, `weather`, `planb`, `budget`, `decide` d05 are calls. | `repair`, `home` d05 are calls; `gite d05` is a call. |
| **Follow-ups that ignore the learner** | A Répondre follow-up must fit every accepted reply. Where Robin chooses (a day, a dish, a plan), the follow-up accepts the choice without naming it. | `food d10`, `area d10`. | `deal d04`, `settle d01`. | `example d04`, `refuse d01`. | `planb d01`, `decide d01`. | `annonce d01`, `tell d01`. |
| **False errors** | Corriger never targets an accepted spoken form or a common variant: *en congés* is common, so 24 `pont s03` targets *ensembles*; *c'est pas* is not an error. | *délicieux → délicieuse*, *drôles → drôle*, *salée → salé*, *propre → propres*, *étaient*, *incroyables*, *moyen → moyens*, *déçu → déçue*. | *vaisselles*, *petit → petite*, *chère → cher*, *vraie → vrai*, *ta → ton* (×2), *fait → fais*, *sales → sale*. | *raisons*, *beaux → beau*, *fatigué → fatiguée*, *prend → prends*, *es → sois*, *minute → minutes*, *célèbre → célèbres*, *occupé → occupée*. | *ensembles*, *beaux → beau*, *orage → orages*, *gratuite → gratuit*, *grande → grand*, *irais → irait*, *dépensé → dépenser*, *complète → complet*. | *supprimée → supprimé*, *malentendus*, *fonctionnent*, *récupéré → récupérer*, *plante → plantes*, *mauvais → mauvaise*, *rire → ri*, *déraillée → déraillé*. |
| **Logic puzzles** | No gap depends on reasoning or arithmetic; sums and times are printed. | | | | Budgets are printed per person. | Times and tracks are printed. |
| **Untaught words used early** | Every quoted token and choice was segmented against `words.json`, this batch's keys in book order, the tables and the *Fondations* tokens (0 unknown, 0 early). Caught and replaced: the words listed in §6 under "Avoided". | | | | | |
| **Masculine forms for Robin** | Learner lines use feminine forms only; masculine forms appear as decoys and Corriger errors. The validator's scan hit only Corriger lines and Théo's lines. `MASC_SELF` gains *déçu* (open question 3). | `formal s03`. | — | `so s03`, `refuse s03`; `refuse d01`, `d04`, `d08` (*occupée* addressed to Robin). | — | — |

## 10. `modules.json` entries (ready to paste)

Add these before the first assemble; the author agents don't.

```json
{"id": "sit_21", "title": "Donner son avis", "arc": "Échanger", "goal": "Give and ask for an opinion on a film, a dish or the neighbourhood, back it up and soften it.", "file": "21_donner_son_avis.json", "moves": ["opinion", "film", "food", "area", "ask", "strong", "mixed", "formal"]},
{"id": "sit_22", "title": "D'accord ou pas", "arc": "Échanger", "goal": "Share the chores with Léa: agree, disagree, soften, take turns and settle a deal.", "file": "22_d_accord_ou_pas.json", "moves": ["chores", "agree", "disagree", "soften", "turns", "deal", "complain", "settle"]},
{"id": "sit_23", "title": "Expliquer pourquoi", "arc": "Échanger", "goal": "Ask why, give reasons and consequences, add examples, and explain a refusal.", "file": "23_expliquer_pourquoi.json", "moves": ["why", "because", "so", "example", "purpose", "explain", "lyon", "refuse"]},
{"id": "sit_24", "title": "Et si… ?", "arc": "Échanger", "goal": "Plan a long weekend: suggest with « et si on… », weigh the weather, make a plan B, book and budget, and decide.", "file": "24_et_si.json", "moves": ["pont", "etsi", "weather", "planb", "book", "dream", "budget", "decide"]},
{"id": "sit_25", "title": "Un week-end qui déraille", "arc": "Échanger", "goal": "Get through a long weekend that goes wrong: understand announcements, clear up misunderstandings, sort out problems, and tell the story afterwards.", "file": "25_un_week_end_qui_deraille.json", "moves": ["annonce", "repair", "gite", "lost", "home", "group", "bright", "tell"]}
```

## 11. Batch procedure

1. **Coordinator prep.** The coordinator settles the open questions (or takes the defaults in §12), then:
   - adds the five `modules.json` entries (§10);
   - (default for question 3) adds *déçu* to `MASC_SELF` in `tools/situations/lint.py`, with a test;
   - (default for question 4) adds the base keys *s'il fait beau, s'il pleut, plus tôt* to `words.json` with `apply_gloss_spec.py` (`{"add": {...}}`), so authors see them.
2. **Two author agents per module** (10 in all), **about 7 at a time**. Resume with SendMessage if the usage limit hits. Give each this file (§1–2, §8, §9), its matrix and `agents/author.md`, plus these lessons in the prompt:
   - check every Comprendre `correct` against the true choice;
   - every Choisir le ton option must be natural French;
   - use the planned `_past` / `_verb` audio keys, and check `words.json` before adding any participle;
   - Robin is feminine only (`MASC_SELF`), and Corriger may target her agreement;
   - reword Grammalecte flags, never suppress them.

   **Author gloss self-check (required before handing in):**
   - wrap the draft with its `modules.json` header in a scratch module and merge `words.json` with the draft words file;
   - run `python3 tools/situations/gloss_dump.py <scratch module> <merged words>`;
   - read every `key=gloss` pair against its sentence, including bank tiles and choices;
   - fix each wrong one by rewording the line or adding a longer phrase key (`firstSeen: null`, after checking it swallows nothing in 01–25). Never edit an existing gloss in a draft: list any needed widening in the report;
   - the report says "gloss dump read: N lines, M fixes".
3. **Gloss conflict scan and assembly.**
   - Run the conflict scan over all drafts and `words.json`. §8 and the matrices' tables should leave few conflicts.
   - Then run `assemble.py 21 22 23 24 25`, lint, the tests, `deep_lint.py` and the Swift model test.
4. **Four judges per module** (two moves each), about 7 at a time, with §1–2 and §9 of this file **and each judge's moves' `gloss_dump.py` output** (they check every pair).
   - Judge pairs: 21 opinion/film, food/area, ask/strong, mixed/formal; 22 chores/agree, disagree/soften, turns/deal, complain/settle; 23 why/because, so/example, purpose/explain, lyon/refuse; 24 pont/etsi, weather/planb, book/dream, budget/decide; 25 annonce/repair, gite/lost, home/group, bright/tell.
5. **Fixers, then the book-wide pass.**
   - Fixers re-check every Comprendre `correct` too.
   - One coordinator then applies book-wide gloss widenings and new keys in a single `apply_gloss_spec.py` pass (fixers only reword lines).
   - Then run the *Fondations* audit of every new `firstSeen: null` entry and a gloss-dump spot check of all 25 modules' changed keys.
6. **One 9-card review set (v11)**, in D D S order, with drill types differing across item boundaries and adjacent dialogues having different drill pairs. Suggested:
   - `sit_24_pont_d01 sit_23_lyon_d03 sit_21_formal_s03 sit_22_chores_d04 sit_25_annonce_d02 sit_24_dream_s04 sit_22_turns_d06 sit_25_repair_d05 sit_23_purpose_s03`;
   - it covers *faire le pont*, the Fête des Lumières, Robin's *déçue* Corriger, the chores, a station announcement, a *si* + imparfait Transformer, taking turns, a *Clarify* call about a misunderstanding and the *pour que* + subjunctive Corriger.
7. **Phone and audio.** Install on the phone (Test book) only if the user asks. After the user's verdict, generate production audio: `--module` for 21–25, then one plain run for the base keys.

## 12. Open questions for the user (with the default authoring will use)

1. **New role « Propriétaire »** (`voice: "female"`) for the gîte owner in 24–25. It is gender-neutral, so `lint.py`'s role lists need no change. New plain-text places: `Devant le cinéma`, `Au gîte`, `Appel · gîte`, `Appel · M. Ferrand`, `Texto · Karim`. **Default: yes, no lint change.**
2. **Informal words without a spoken flag.** *Bof, pas question, marché conclu, ça m'énerve, tu exagères, au final* are everyday standard French, so they are glossed plainly (`spoken: false`), like arc 4's *galère, mince*. **Default: no new `SPOKEN` entries.** (Alternative: mark *bof* and *au final* spoken.)
3. **Extend `MASC_SELF`** with *déçu* (Robin's *déçue*; *occupé* is already listed). **Default: yes, with a test.**
4. **Three new base phrase keys:** *s'il fait beau* ("if the weather's nice"), *s'il pleut* ("if it rains") and *plus tôt* ("earlier"). Without them the condition reads "if he · does / makes · nice" and *plus tôt* reads "more · early". *S'il pleut* also re-glosses 18 `decide d09`'s follow-up, where "if it rains" is right. **Default: add all three (`firstSeen: null`) before authoring; their clips come from the plain audio run.**
5. **Culture items:**
   - *faire le pont* and *les jours fériés* of May (24);
   - *le gîte* (24–25);
   - *le Vieux Lyon*, *les traboules* and *la Fête des Lumières* (23);
   - the sweet-or-savoury choice (21);
   - SNCF-style announcements with *voie, supprimé, correspondance, en raison de* (25).

   **Default: keep all.**
6. **New one-off facts:**
   - Robin, Inès and Théo take the May *pont* to Annecy by train, change at Chambéry and rent a gîte by the lake, while Léa stays in Lyon;
   - the train is cancelled for a strike, the gîte has no sheets and cold heating, Robin leaves her rucksack on the train and gets it back from lost property;
   - M. Ferrand waters her plants and Mme Dumas reports a small leak;
   - Robin chose Lyon for work and loves the Vieux Lyon;
   - Léa and Robin put a chores rota on the fridge.

   **Default: all fine.**
7. ***Car*** (formal "because") is used mainly with *vous* people (Mme Dumas, M. Ferrand, the manager) and once in Inès's text. **Default: keep.** (Alternative: *vous* people only.)
8. **Grammar beyond *Fondations*.** The plus-que-parfait, the conditionnel passé, the passive, the gérondif and *ne… que* are kept out. *Je croyais que* (imparfait) carries the "I thought" repair. **Default: keep these out.**
9. **The arc name « Échanger »** comes from the syllabus table, for `modules.json` and the module headers. **Default: yes.**
10. **Review before authoring.** Memory says to author in bulk only after the user approves a sample. **Default: author all five modules, then show the 9-card set in §11 as review set v11** (as arcs 2–4 did).
