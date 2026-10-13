# Book 2, arc 1 *Arriver à Lyon*: plan for modules 01–05

**Date:** 2026-10-11
**Status:** paper plan only. No French is authored. Nothing is committed.
**Matrices:** [01](2026-10-11-book-2-arc1-module-01-matrix.md) · [02](2026-10-11-book-2-arc1-module-02-matrix.md) · [03](2026-10-11-book-2-arc1-module-03-matrix.md) · [04](2026-10-11-book-2-arc1-module-04-matrix.md) · [05](2026-10-11-book-2-arc1-module-05-matrix.md)
**Rulebook:** [content handoff](2026-10-11-book-2-content-handoff.md) §3, §7–8; [café handoff](2026-10-11-book-2-cafe-handoff.md) §3 (error classes, vocabulary audit); `tools/situations/README.md` (schema, book-wide word order, drafts, assemble).

Each matrix has one row per item (8 moves × 15 items = 120 per module), in the café matrix format, plus a table of the module's new words. A validator (in the planning scratchpad, not in the repo) checked every rule listed in §9 on all 600 rows before the matrices were written.

## 1. Fixed decisions this plan builds on

- **Karim** says *vous* everywhere before module 06. He switches to *tu* only in `sit_06_usual_d04`. In arc 1 he appears only in 03 (small talk at the café, 15 dialogues) and once in 05 (`where d10`), always *vous*.
- **M. Ferrand** says *vous* forever. **Mme Dumas** says *vous*, mostly on WhatsApp. **Léa, Inès, Théo** say *tu*.
- **« On peut se tutoyer ? »** (03 `tutoyer`) happens with two unnamed people of the learner's age: a neighbour from the third floor and a colleague from another team. Both say *vous* until the switch. It never happens with M. Ferrand or Karim. In `tutoyer d06`, Léa says that M. Ferrand stays *vous*.
- Cast `name` strings: `Léa`, `Inès`, `Théo`, `Karim`, `M. Ferrand`, `Mme Dumas`. Unnamed speakers omit `name`. The neighbour sets `voice: "female"`. The colleague uses the default male Neural2 voice.
- Light history: the learner moved to Lyon for work. Léa is the flatmate, Inès a colleague, Théo runs the group chat, M. Ferrand lives on the landing. History shows only in cues. Every dialogue stands alone.
- Per move: 10 dialogues + 5 standalone drills, ≥4 dialogue drill types, Répondre + Compléter ≥ half the dialogue drills, ≥1 clarification dialogue, ≥2 dialogues on another channel. 1–2 drills per dialogue, no repeated type, no Répondre + Choisir together.

## 2. Conventions new in this arc

1. **Learner name.** Self-introductions need a name in printed learner lines (« Moi, c'est Alex »). The plan uses **Alex**, which works for any gender and in both languages. Open question 1.
2. **Hometown.** Cues give the learner's hometown as **Boston**. It is a proper noun that is the same in English, so it needs no teaching. The cue states it every time, so no answer depends on a fact the learner can't know. Open question 2.
3. **Places** (`place` field; the label is plain text, not tappable): `À l'appart`, `Sur le palier`, `Dans l'escalier`, `Au bureau`, `Au café`, `Chez Théo`, `Texto · Léa|Inès|Théo`, `Les copains · groupe`, `WhatsApp · Mme Dumas`, `Appel · <name>`, `Messagerie · <name>`. A standalone drill uses its move's home place plus `· phrase seule`. The label « Les copains · groupe » appears from module 01, but the word *copains* is taught only in 04 `group d02`. This is fine because the label is not glossed text.
4. **Group chat.** When Théo writes to the whole group, his *vous* is plural. The cue says so (« vous = you all »). The learner still says *tu* to Théo.
5. **firstSeen is printed.** A new word's `firstSeen` item shows it in a printed turn (a server line or a printed learner line), never only in a gap answer or a built reply. Every matrix row with a word in **New** is planned this way.
6. **Quoted French in the matrices is a sketch** for the author, not final text, and never cue text. The English cue the author writes must name the speaker and state tu or vous. It must not repeat the fact that a Comprendre drill asks about.
7. **Inflected forms** of a taught word get their own `words.json` entries with `firstSeen: null`, because they are compositional: *enchantée, désolée, apporte, cours, quel, quelle, libres, délicieuse, décale*. Those that appear only as distractors are listed in the matrices (e.g. *demies, couru, passes, notée, remercies*).
8. **Café phrase keys** match longest first, book-wide. So arc 1 must not use these café phrases at all, in any sense: *ça fait, il reste, plus de, pour deux, à la place, sur place, à emporter, quand même, comme d'habitude, y a encore, un sac, je crois, erreur, euros, monnaie, par carte, en panne, (en) espèces, terminal*. Use *d'habitude*, which is a base word, rather than *comme d'habitude*. The validator checked every sketch against this list.
9. **Glosses shared with café** must match `words.json` exactly, or `assemble.py` fails. The ten moved words keep their café `en`, `spoken` and `audio` values (§6).
10. **`modules.json` entries** must be added before the first assemble. The author agents don't do this; the coordinator does. Proposed entries:

```json
{"id": "sit_01", "title": "Faire connaissance", "arc": "Arriver à Lyon", "goal": "Introduce yourself, introduce others, and ask a follow-up.", "file": "01_faire_connaissance.json", "moves": ["greet", "name", "others", "origin", "work", "askback", "flat", "bye"]},
{"id": "sit_02", "title": "Le quotidien", "arc": "Arriver à Lyon", "goal": "Exchange routines, likes, and how often you do things.", "file": "02_le_quotidien.json", "moves": ["morning", "commute", "likes", "react", "evening", "hobbies", "frequency", "weekend"]},
{"id": "sit_03", "title": "Tu ou vous ?", "arc": "Arriver à Lyon", "goal": "Pick the register, make small talk, ask to repeat, and switch to tu.", "file": "03_tu_ou_vous.json", "moves": ["landing", "register", "weather", "repeat", "quartier", "tutoyer", "dumas", "slip"]},
{"id": "sit_04", "title": "Inviter", "arc": "Arriver à Lyon", "goal": "Invite to an apéro; accept or decline without offending.", "file": "04_inviter.json", "moves": ["invite", "group", "accept", "decline", "maybe", "bring", "arrive", "thank"]},
{"id": "sit_05", "title": "Fixer un rendez-vous", "arc": "Arriver à Lyon", "goal": "Agree on time, place, and people; move the plan.", "file": "05_fixer_un_rendez_vous.json", "moves": ["when", "time", "where", "who", "confirm", "call", "move", "meet"]}
```

   Drafts: `NN_<slug>_first_half.json` / `_second_half.json`, each with its `_words.json` (e.g. `01_faire_connaissance_first_half.json`).

## 3. Move lists

Moves 1–4 go to author agent 1 (first half) and moves 5–8 to author agent 2 (second half). Each new word is owned by the half where it first appears, and every word's recurrences and its Mot drill fall inside its own move. So neither half depends on the other's draft, except to copy an entry byte for byte when it reuses a word.

### 01 *Faire connaissance* (Léa on move-in day)

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_01_greet` | Saluer | 1st | 5 | The first exchange: *salut* with Léa, *bonjour* with M. Ferrand, and the « Ça va ? — Ça va, merci. Et toi ? » loop. |
| `sit_01_name` | Se présenter | 1st | 3 | Your name two ways (*je m'appelle* from *Fondations*, *moi, c'est*), and *enchanté*. |
| `sit_01_others` | Présenter quelqu'un | 1st | 4 | *Je te présente…*, plus who people are to you (*ma coloc, ma collègue, notre voisin*). Drills possessive gender. |
| `sit_01_origin` | Dire d'où l'on vient | 1st | 3 | *Je viens de…*, *tu viens d'où ?*, and how to react (*ah bon ?, c'est loin !*). |
| `sit_01_work` | Parler de son travail | 2nd | 4 | « Tu fais quoi dans la vie ? » Learner lines avoid gendered job titles. |
| `sit_01_askback` | Relancer la conversation | 2nd | 5 | The syllabus core: answer, then ask a follow-up (*depuis quand ?, c'est comment ?*). |
| `sit_01_flat` | Découvrir l'appart | 2nd | 4 | Move-in logistics (*bienvenue, la salle de bains est à côté*) and Léa's spoken *t'as*. |
| `sit_01_bye` | Remercier et prendre congé | 2nd | 5 | Thank someone, answer thanks, and say goodbye for later today, tonight or soon. |

### 02 *Le quotidien* (Léa, Inès · texts)

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_02_morning` | Le matin | 1st | 3 | Times (*à quelle heure, vers, et demie*) with *se lever* from *Fondations*. |
| `sit_02_commute` | Aller au travail | 1st | 4 | *À pied, à vélo, en métro, dix minutes*. Fixes the à/en preposition. |
| `sit_02_likes` | Dire ce qu'on aime | 1st | 4 | *J'aime bien / pas trop*, the article after *aimer*, and spoken *ouais*. |
| `sit_02_react` | Réagir : moi aussi, moi non plus | 1st | 4 | Find common ground, contradict with *si*, and change topic with *bref*. |
| `sit_02_evening` | Le soir | 2nd | 3 | Evening routine (*une série, tranquille*) and spoken *du coup*. |
| `sit_02_hobbies` | Les loisirs | 2nd | 3 | Sport and free time (*courir, la piscine, en ce moment*). |
| `sit_02_frequency` | Dire la fréquence | 2nd | 4 | *Parfois, une fois par semaine*, and spoken *je sais pas* when unsure. |
| `sit_02_weekend` | Le week-end | 2nd | 4 | *Samedi, dimanche*, and *carrément*. Prepares the invitations in 04. |

### 03 *Tu ou vous ?* (M. Ferrand, Karim, Inès, Mme Dumas, a neighbour your age)

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_03_landing` | Saluer M. Ferrand | 1st | 3 | The formal greeting: *Bonjour, monsieur*, *Vous allez bien ?*, *excusez-moi*. |
| `sit_03_register` | Choisir tu ou vous | 1st | 2 | Match each person to tu or vous; the pairs *s'il te plaît / s'il vous plaît* and *excuse-moi / excusez-moi*; plural *vous* for a group. |
| `sit_03_weather` | Parler de la pluie et du beau temps | 1st | 4 | Small talk with neighbours and Karim, plus *encore* in the sense “still”. |
| `sit_03_repeat` | Faire répéter, demander le sens | 1st | 2 | *Vous pouvez répéter ?*, *plus lentement*, « … ça veut dire quoi ? ». The words the learner asks about are always ones already taught. |
| `sit_03_quartier` | Parler du quartier | 2nd | 3 | Neighbourhood small talk with Karim (vous) and M. Ferrand: *calme, en face de*. |
| `sit_03_tutoyer` | Passer au tu | 2nd | 3 | The culture move « On peut se tutoyer ? », with *bien sûr* and *d'accord*. |
| `sit_03_dumas` | Écrire à Mme Dumas | 2nd | 4 | Formal written register: *je vous remercie, bien reçu, n'hésitez pas*. |
| `sit_03_slip` | Rattraper un tu de trop | 2nd | 3 | Repair a register slip (*je voulais dire vous*) and reassure someone (*pas grave, ça arrive*). |

### 04 *Inviter* (« Les copains », Théo, Léa)

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_04_invite` | Inviter à un apéro | 1st | 3 | *Un apéro, ça te dit ?*, *tu veux passer ?*. The apéro is the culture move. |
| `sit_04_group` | Écrire au groupe | 1st | 3 | Group-chat plural *vous*, *libre/libres* agreement, spoken *dispo*. |
| `sit_04_accept` | Accepter | 1st | 3 | Accept warmly in the right register: *super*, spoken *top*, and *volontiers* with M. Ferrand. |
| `sit_04_decline` | Refuser sans vexer | 1st | 4 | Decline and keep the door open: *dommage, malheureusement, la prochaine fois*. |
| `sit_04_maybe` | Hésiter | 2nd | 3 | An honest maybe: *peut-être, normalement, je te dis demain*. |
| `sit_04_bring` | Apporter quelque chose | 2nd | 4 | The etiquette question « J'apporte quelque chose ? » — « Des chips ! » or « Pas besoin ! ». |
| `sit_04_arrive` | À l'apéro | 2nd | 3 | Arriving at someone's place: *fais comme chez toi*, *la bise* (culture), a compliment (*délicieux*). |
| `sit_04_thank` | Remercier après | 2nd | 3 | The day after: *merci pour l'invitation, à refaire*, and *pas de souci* as the answer to thanks. |

### 05 *Fixer un rendez-vous* (texts, a call)

| Element | Move | Half | New | Why this move |
|---|---|---|---|---|
| `sit_05_when` | Choisir le jour | 1st | 3 | *On se voit vendredi ?* or *quand tu veux*. |
| `sit_05_time` | Fixer l'heure | 1st | 3 | *Et quart*, *ça te va ?* with friends, *ça vous va ?* with Mme Dumas or a whole group. |
| `sit_05_where` | Fixer le lieu | 1st | 3 | *On se retrouve où ?*, *devant la gare*, *à l'entrée du parc*. |
| `sit_05_who` | Qui vient ? | 1st | 3 | *On est combien ?*, *à part*, and *amener* (people), kept apart from *apporter* (things). |
| `sit_05_confirm` | Confirmer | 2nd | 3 | *Ça marche*, *c'est noté*, and a formal *rendez-vous* with Mme Dumas. |
| `sit_05_call` | Au téléphone | 2nd | 3 | *Allô ?*, a bad line, *je te rappelle*. Calls and voicemail are audio plus text. |
| `sit_05_move` | Déplacer le rendez-vous | 2nd | 4 | *On peut décaler ?*, *plutôt lundi*, *finalement*. |
| `sit_05_meet` | Se retrouver sur place | 2nd | 3 | On the day: *t'es où ?*, *j'arrive*, *je suis en avance*. |

## 4. Totals

| Module | New words (1st / 2nd half) | Spoken forms | Dialogues not face to face (of 80) | Channel mix (dialogues) |
|---|---|---|---|---|
| 01 Faire connaissance | 33 (15 / 18) | boulot, t'as | 23 | face to face 57, Texto 17, Les copains 6 |
| 02 Le quotidien | 29 (15 / 14) | ouais, bref, du coup, je sais pas, carrément | 42 | face to face 38, Texto 31, Les copains 10, Messagerie 1 |
| 03 Tu ou vous ? | 24 (11 / 13) | — | 24 | face to face 56, WhatsApp 11, Texto 9, Les copains 3, Messagerie 1 |
| 04 Inviter | 26 (13 / 13) | dispo, top, pas de souci | 51 | Texto 29, face to face 29, Les copains 22 |
| 05 Fixer un rendez-vous | 25 (12 / 13) | ça marche, t'es | 66 | Texto 32, face to face 14, Les copains 12, Appel 11, WhatsApp 10, Messagerie 1 |
| **Arc 1** | **137** | **12** | **206 of 400** | |

Per move, every new word recurs in at least two later dialogues of the same move and gets a later Mot or Mot en retour drill. No dialogue introduces more than two new words. Every move has at least 2 dialogues on another channel type than its home channel (most have 3–8), and at least one dialogue whose cue starts with *Clarify*. The `lint.py` heuristic is looser: it counts any Léa, Théo, Inès, M. Ferrand or Mme Dumas dialogue as social. So the stricter count above is the one to trust.

## 5. Cross-module word progression

Each word is taught once, in the earliest module that needs it. Later modules reuse it freely, and a later item may list it in `newWords` again to underline it.

| Module | Words taught (book-wide first) | Carried into later arc-1 modules |
|---|---|---|
| 01 | *salut*; *ça va*; *merci*; *bonjour*; *pardon*; *moi, c'est*; *enchanté*; *prénom*; *je te présente*; *voisin*; *coloc*; *collègue*; *d'où*; *loin*; *ah bon*; *quoi*; *dans la vie*; *entreprise*; *boulot*; *depuis quand*; *c'est comment*; *sympa*; *pas mal*; *vraiment*; *bienvenue*; *salle de bains*; *à côté*; *t'as*; *de rien*; *au revoir*; *bonne soirée*; *à tout à l'heure*; *à bientôt* | *salut* (03, 04, 05); *ça va* (03); *merci* (03, 04); *bonjour* (03, 05); *pardon* (02, 03, 05); *enchanté* (03); *coloc* (05); *loin* (02); *ah bon* (02); *quoi* (02, 03, 04); *sympa* (03, 04); *à côté* (02, 03); *t'as* (03); *de rien* (03); *au revoir* (03); *à bientôt* (03) |
| 02 | *à quelle heure*; *vers*; *et demie*; *à pied*; *métro*; *à vélo*; *minutes*; *j'aime bien*; *musique*; *pas trop*; *ouais*; *moi aussi*; *moi non plus*; *c'est vrai*; *bref*; *série*; *tranquille*; *du coup*; *courir*; *en ce moment*; *piscine*; *parfois*; *fois*; *par semaine*; *je sais pas*; *week-end*; *samedi*; *dimanche*; *carrément* | *vers* (04, 05); *métro* (03, 05); *minutes* (05); *j'aime bien* (03); *pas trop* (03); *ouais* (05); *du coup* (03, 05); *je sais pas* (04); *samedi* (04, 05); *dimanche* (03, 04, 05); *carrément* (03, 04) |
| 03 | *monsieur*; *madame*; *excusez-moi*; *s'il te plaît*; *excuse-moi*; *il pleut*; *soleil*; *encore*; *pluie*; *vous pouvez répéter*; *ça veut dire*; *quartier*; *calme*; *en face*; *on peut se tutoyer*; *bien sûr*; *d'accord*; *propriétaire*; *n'hésitez pas*; *bien reçu*; *je vous remercie*; *pas grave*; *je voulais dire*; *ça arrive* | *madame* (05); *ça veut dire* (04); *bien sûr* (05); *d'accord* (04, 05) |
| 04 | *apéro*; *ça te dit*; *passer*; *libre*; *dispo*; *copains*; *super*; *volontiers*; *top*; *dommage*; *désolé*; *malheureusement*; *la prochaine fois*; *peut-être*; *je te dis*; *normalement*; *apporter*; *quelque chose*; *chips*; *pas besoin*; *fais comme chez toi*; *la bise*; *délicieux*; *pas de souci*; *invitation*; *à refaire* | *passer* (05); *libre* (05); *copains* (05); *top* (05); *pas de souci* (05) |
| 05 | *on se voit*; *vendredi*; *quand tu veux*; *et quart*; *ça te va*; *ça vous va*; *on se retrouve*; *devant*; *entrée*; *on est combien*; *amener*; *à part*; *ça marche*; *c'est noté*; *rendez-vous*; *allô*; *je t'entends mal*; *je te rappelle*; *décaler*; *plutôt*; *finalement*; *lundi*; *t'es*; *j'arrive*; *en avance* | — (06 onward) |

The vocabulary audit (`grep` of each word against the answer sentences in `Resources/Topics/*.json`) found 134 of the 137 words absent from *Fondations* answers. The other three appear once each, in another sense or another form: *entrée* (the participle « entrée », module 14), *tranquille* (« une journée tranquille », module 22) and *t'es* (part of a reflexive *tu t'es…*). They stay taught words. Other borderline cases were also treated as taught, because teaching a word that is nearly known costs nothing: *courir* (Book 1 has only « il court »), *passer* (only « le bus qui passe »), *quelle* (only in Book 1's French instructions). As in café, function words that `words.json` already lists as base (*mais, alors, vous pouvez, répéter*) stay base.

## 6. Café words: firstSeen changes

These café-taught words move to their first arc-1 use. Their `en`, `spoken` and `audio` stay exactly as in `words.json`. `assemble.py` keeps the entry with the earliest `firstSeen` in book order, so the arc-1 drafts' entries win automatically.

| Word | Café firstSeen now | New firstSeen | Owning half |
|---|---|---|---|
| merci | `sit_06_substitute_d02` | `sit_01_greet_d02` | 01 first |
| bonjour | `sit_06_order_d01` | `sit_01_greet_d03` | 01 first |
| pardon | `sit_06_order_d05` | `sit_01_greet_d05` | 01 first |
| t'as | `sit_06_takeaway_d07` | `sit_01_flat_d04` | 01 second |
| s'il te plaît | `sit_06_order_d04` | `sit_03_register_d01` | 03 first |
| encore | `sit_06_available_d02` | `sit_03_weather_d03` | 03 first |
| vous pouvez répéter | `sit_06_order_d05` | `sit_03_repeat_d01` | 03 first |
| on peut se tutoyer | `sit_06_usual_d04` | `sit_03_tutoyer_d01` | 03 second |
| désolé | `sit_06_substitute_d06` | `sit_04_decline_d02` | 04 first |
| pas de souci | `sit_06_mixup_d07` | `sit_04_thank_d01` | 04 second |

**Words café deliberately avoided, now taught in arc 1:** *salut* (01 `greet d01`), *minutes* (02 `commute d04`), *bien sûr* (03 `tutoyer d02`), *d'accord* (03 `tutoyer d03`), *super* (04 `accept d01`), *j'arrive* (05 `meet d02`). *Payer, je vous dois, il vous faut* and bare *carte* are still not taught. Café's lines don't change. Its items that used to introduce these words keep them in `newWords` as an underline (open question 4).

**Café words that stay first-taught in 06:** *comme d'habitude, il reste, y a encore, plus de, à la place, pour deux, quand même, sur place, à emporter, un sac, je crois, (une) erreur, ça fait, par carte, euros, en panne, monnaie, terminal, (en) espèces*. Arc 1 must not use any of them (§2.8).

## 7. Grammar recycled from *Fondations*

Book 1 module numbers are in brackets.

- **01:** *être/avoir* present, including spoken *t'as* (02, 03); *s'appeler* (15); *venir de* + city, *à côté de* with *du / de la* (10); possessives *ma / mon / ta / notre*, with Corriger on « mon coloc » for Léa (08); questions by intonation, *où*, *comment*, *quoi* (06); adjective agreement (*une grande chambre*) and the invariable *sympa* (07); *toi* after *et*; object pronoun *les* (« Oui, je les ai », 17).
- **02:** *se lever* (15); present of *partir, sortir, courir, prendre* (04, 09); clock times with *à*, and the *midi et demi* / *heures et demie* agreement; *à* or *en* with transport (10); definite article after *aimer* (01); *ne… pas trop*, *non plus*, and *si* against a negative question (05, 06); *faire du* + partitive (11); *aller* + infinitive (12); *on* for *nous*.
- **03:** tu/vous verb pairs (*vas/allez, peux/pouvez, as/avez*); *pouvoir* + infinitive requests; *il fait*, *il pleut*, and *très* not *beaucoup* before an adjective (Corriger); the position of *encore* (Transformer); *en face du* (10); *tu as dit* (13); *je voulais dire* (16); *vous verrez*, receptive only (21); *se tutoyer* (15); *je te / je vous* (17).
- **04:** *vouloir / pouvoir* + infinitive, *je ne peux pas* (05); *aller* + infinitive (Transformer, 12); *en* (« j'en ai », « Léa va en apporter », 18); tu and vous imperatives (*passe, fais comme chez toi, entrez, faites*, 20); *libre/libres* and *délicieux/délicieuse* (07); *c'était* (16); one Choisir le ton option with *que j'apporte*, receptive only (24); plural *vous* for a group.
- **05:** reciprocal *on se voit, on se retrouve* (15); *te / vous / me* objects in *je te rappelle, je t'entends, ça me va* (17); *est-ce que* questions (06); *devant*, *à l'entrée du* (10); infinitive vs past participle (*décaler / décalé*, *noté / noter*, both in Corriger); *et quart*; *venir* (09).

## 8. Proposed review sets

Following the "small sets" rule, use one 9-card set per module after its judge pass, in D D S order. Suggested picks: 01 `greet d01, others d06, name s03, origin d04, askback d01, flat s02, work d05, bye d05, askback s05`; 03 `landing d01, register d02, register s02, tutoyer d01, tutoyer d06, slip s02, repeat d10, dumas d04, dumas s05`. The 03 picks cover both registers, the tu switch, the slip repair and WhatsApp.

## 9. How the plan blocks the judge-found error classes

Every check below ran on all 600 rows.

| Error class | What the plan does |
|---|---|
| Untaught words used early | Book-order check on every quoted sketch and choice list against all 137 words and the café phrase list. *Copains*, *t'es* and *ça marche* were caught in early modules and replaced. Every remaining non-*Fondations* token in a sketch is an inflection of a taught or base word (§2.7). |
| Answer echo | The correct gap answer must not appear in a printed line of the same item. This caught 21 sketches, and their gaps were moved (e.g. « Tu aimes la musique ? » now gaps the verb, not *la*). Authors must re-check against their final lines. |
| Hidden valid replies | The plan avoids gaps where two choices are both correct French (*à / vers* before a time; *pas trop / pas beaucoup*; *je suis de / je viens de*). Authors still list every valid bank order in `accepted`. |
| False errors | Corriger targets only clear errors: *demi → demie*, *en pied → à pied*, *le musique*, *ça te dis*, *noter → noté*, *la entrée*, *mon coloc* (for Léa), *beaucoup froid*. It never targets the learner's gender or an accepted spoken form (*t'as, je sais pas, c'est pas mal*). |
| Cue leaks | Cues state the speaker, the register and the learner's goal (and the hometown, the day or the time when the reply needs them). They never state the fact a Comprendre drill asks about. The sketches in the matrices are author notes, not cues. |
| Follow-ups that ignore the learner | Each Répondre follow-up must fit every accepted reply. A follow-up never assumes yes when the bank also lets the learner say no. |
| Logic puzzles | No gap depends on reasoning about who owns what. The facts a reply needs are in the cue or in the French line. |
| Unnatural French | Spoken forms appear only in tu exchanges and are glossed `spoken`. The plan uses « il y a du soleil » rather than « il fait soleil », and never uses *copain* in the singular (it can mean boyfriend). Judges still need to read every line. |

## 10. Batch procedure (unchanged from café handoff §5.4)

1. The coordinator adds the five `modules.json` entries (§2.10).
2. Two author agents per module (first and second half). Each edits only its own draft pair and copies shared word entries byte for byte, using the café glosses for the ten moved words.
3. `assemble.py 01` … `05`, then `lint.py --no-audio`, the unit tests and `deep_lint.py`.
4. Four judges per module (two moves each). Give them §1–2 and §9 of this file, Karim's vous rule, and the café phrase list.
5. Fixes, then a *Fondations* audit of every new `firstSeen: null` entry.
6. A review set of about 9 cards per module for the user. Audition the new voices first (open question 8).

## 11. Open questions for the user

1. **Learner name.** Printed self-introductions use « Alex » (01 `name`, `others`; 03 `landing d02`; 05 `call s01`). Is Alex all right, or should printed learner lines never contain a name (the name only ever a tile in a built reply)?
2. **Hometown.** Cues fix Boston (01 `origin`, 03 `repeat d03`). Keep one hometown book-wide, or vary it by cue?
3. **The tu-switch partners** in 03 are two unnamed people: a neighbour your age (female Neural2 voice) and a colleague from another team. Should the neighbour become a named recurring character? That would need a seventh voice and an entry in the cast table.
4. **Café underlines.** Café items that used to introduce the ten moved words (e.g. `order_d01` for *bonjour*) can keep them in `newWords` as an underline, or drop them. Keeping them is recommended as light review.
5. **Module 03 teaches 24 words**, one under the ~25 floor, because its moves recombine 01–02 vocabulary into register choices. Accept, or add one more word?
6. **Office culture.** Inès says tu from the first day (01, 02), and in 03 she says « Au bureau, on dit tu ». Does that match your picture of the office?
7. **Karim before the café module.** He appears in 03 (weather, *repeat*, *quartier*, *slip*) and in 05 `where d10`, always vous. Is meeting him before module 06 fine?
8. **New voices.** M. Ferrand (Algenib), Inès (Despina) and Mme Dumas (Gacrux) are not auditioned yet. Arc 1 leans on them: Inès speaks in 102 dialogues, M. Ferrand in 41, Mme Dumas in 23. Audition them before generating any audio.
9. **Borderline Fondations words** *courir, passer, quelle* are treated as taught (§5). Fine?
