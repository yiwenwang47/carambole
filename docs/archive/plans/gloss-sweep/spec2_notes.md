# Gloss spec 2: notes

Verification method: a scratch copy of the Swift segmenter (`SituationText.segments`). It matches longest key first, left to right. A free-standing « ! » / « ? » / « : » or a `___` token breaks phrases. The Corriger error word is kept apart. It was run over every tappable line of all 20 modules (turns, follow-ups, accepted replies, choices, banks, Corriger choices, filled gap lines), with spec2 applied.
- For every add: I listed every line where the key's tokens occur in sequence, including across commas, and read each segmentation.
- A diff of old vs new segmentation flagged every existing multi-word key that a new key displaces. All 41 displacements are intended: à côté → à côté de, au fond → au fond du, ça dépend → ça dépend du, moi c'est → chez moi / pour moi c'est, merci de → non merci, ça va → ça va être, à + cet après-midi / tout de suite.
- A comma scan listed every match that spans a « , ». The new keys do this only in « Non, merci » and « Pour moi, c'est », and both are correct.
- For every widen: I read all uses of the key, or confirmed the change only appends a sense or note and keeps the first sense.

## Widen (57)

- à samedi / à lundi / à mardi / à mercredi / à jeudi / à vendredi / à dimanche — "to Saturday (À samedi ! = see you Saturday)" etc. (coordinator decision) — fixes 05 move_d01/d04/s02/s03/d07/s05 (MUST), 09 change_d03/d08 (MUST), 13 formal_d01/d06/d08/s05/s02, newplan_d04 — all greeting uses (« À vendredi ! », « Bonne journée et à dimanche ») still read correctly via the note.
- à demain — "to tomorrow (À demain ! = see you tomorrow)" — fixes 05 « décaler à demain » — greeting uses covered by note.
- entre — "come in! (tu) / between, among" — fixes 01 greet_d01, name_d01, others_d10; 09 arrive_s04 (MUST) — every preposition use is now taken by a new key (entre amis / entre deux / entre les deux / entre le). The bare form is left only on the 5 imperatives and the 16 order_d07 distractor tile, which keeps its real meaning.
- fait — + "(weather: il fait froid = it's cold)" — fixes 03 weather_d01/d02/d03/s01/s03/s04/d04 (MUST), 14 symptom_d09, 17 react_d09, story_d04 (MUST) — note only; the first sense is unchanged.
- de — "of / from / to (+ verb) / some (de la, de l' = some, or of / from the)" — fixes 12 landlady_d01/s01/d06/s03, neighbour_d04; 14 advice_*; 20 ask_s01, warn_*, weigh_*; 18 plan_d03 « appelle de la cuisine »; 02 « de la musique/soupe » (no de la key, per coordinator); 09 confirm_d06 « demande de »; 13 « obligée de » — only adds senses.
- du — "some / of the / from the" — fixes 01 greet_d08, others_d09; 11 cancelled_s04/d09; 12 leak_* — only adds a sense.
- chez — "at / to (someone's place)" — fixes 01 bye_s01/d03, 03 slip_d10, 18 rent_d04 « chez Théo » — fits chez le médecin, chez Karim, chez Théo.
- besoin — "need (avoir besoin de = to need)" — fixes 01 flat_d07/d10, 04 bring_d09, 14 better_d07 — note only.
- me — "me, (to) me / myself" — fixes 02 morning_*, 10 ask_d06/s03/d10, 14 advice_d08, 16 late_* — still fits « tu me donnes », « Léa me dit ».
- te — "you, (to / for) you / yourself (informal)" — fixes 02 morning_*, 06 usual_s05/d07, 14 advice_d10, 16 late_d10 — fits subject and object uses.
- vous — "you (polite / plural), (to / for) you / yourself" — fixes 02 morning_d06, 06 order_d02, takeaway_d01/s01 — fits all subject uses.
- quelle — "which / what (a) (feminine)" — fixes 02 react_d06, 17 help_d09, the « Quelle galère ! » lines — still fits « quelle porte / ligne / couleur ».
- allez — "go / are going (to) / are doing (vous)" — fixes 03 quartier_d02 — fits « Allez tout droit », « allez vite », « vous allez bien ».
- vont — "go / are going (to) (ils, elles)" — fixes 15 complain_d10, fix_d04.
- a — "has (il a dit = he said)" — fixes 14 doctor_d10 — the "we has" problem is fixed by the on a key, not here.
- as — "have (tu) (tu as pris = you took)" — fixes 04 thank_d06, 14 pharmacy_d10 — note only.
- j'ai — "I have (j'ai dit = I said)" — fixes 04 arrive_d05 — note only.
- il y a — + "(il y a dix minutes = ten minutes ago)" — fixes the 10 landmark_d08 and 12 keys_d01 distractor tiles — note only.
- il n'y a — "there is / there are (il n'y a pas = there isn't; il n'y a plus de = there's no more)" — fixes 07 errand_d04/d10 tile double negative (MUST) — bare « il n'y a » occurs only as these tiles.
- il reste — "there's … left / there are … left" — fixes 06 available_*, takeaway_d03/d06; 07 pastry_*, price_s01 — all ~40 uses read.
- tu peux — "you can / can you? (tu)" — fixes 08 fitting_d04, exchange_d03 (MUST); 05 who_d07; 13 cancel_s04 — questions still show "can you?" and carry « ? ».
- vous pouvez — "you can / can you? (vous)" — fixes 08 exchange_d06 (MUST); 13 cancel_s04; 19 book_d03 — same check.
- tu me dis — "you tell me, you say to me / let me know (tu)" — fixes 03 slip_d06 (MUST) — "you tell me" fits all 4 other uses.
- pas trop — "not too (much) / not really" — fixes 07 bread_d03/d05, 12 neighbour_d02/d06/d08, 16 out_d08, 18 « pas trop cher » — the « Moi, pas trop » / « j'aime pas trop » lines in 02 still get "not really".
- bien — "well / good / really, indeed" — fixes 07 taste_d02/d09/s03/s05 « bien mûres », 14 symptom_d03 « bien chaud » — first sense unchanged.
- qu'il — "that he / that it" — fixes 06 mixup_d09 (MUST) — once the qu'il y a key exists, this is the only use.
- prends — "take / have / get (je, tu)" — fixes 06 takeaway_d08, usual_d07 — fits every order line.
- vous prenez — "you're having / you take (polite)" — fixes 11 cancelled_d04 tile.
- tourne — "turn (je, tu) / turns" — fixes 10 turn_d03/d04 (MUST) — all other uses are tu orders.
- sonne — "ring (je) / rings" — fixes 10 door_d05 — also fits « mon réveil ne sonne pas ».
- laisse — "leave(s) (je, tu, il, elle)" — fixes 15 parcel_s04 — fits « Laisse un message », « je lui laisse », « je la laisse ».
- ferme — "close(s), shut(s)" — fixes 07 hours_d08, 16 late_d04 « on ferme ».
- passe — "drop(s) by, come(s) by" — fixes 16 order_d08, 12 « le plombier passe » — all ~40 uses read.
- passé — "past / passed (est passé = came by, dropped by)" — fixes 12 visit_d06 — the other use is the 04 invite_d03 distractor.
- choisit — "choose(s) (il, elle, on)" — fixes 19 propose_d01 — fits « chacun choisit ».
- en — "in, by / some, of it, of them (pronoun)" — fixes 19 share_d07 — only adds a sense.
- l'apéro — "the apéro (pre-dinner drinks)" — fixes 19 prefer_d04, compromise_d04, share_d09 — all 10 uses.
- marcher — "to walk / to work (machine)" — fixes 20 reason_d08 — the other use is the 11 strike_d03 distractor.
- toujours — "still / always (il est toujours en retard = it's always late)" — fixes 20 warn_d02 — kept "still" first because most uses are "still" (on se voit toujours, toujours en panne, j'attends toujours).
- super — "great / really (super rapide = really fast)" — fixes 20 after_d02.
- heures — "o'clock / hours (deux heures de bus = two hours on the bus)" — fixes 11 arrive_d01/s04 — kept o'clock first because about 100 clock-time lines would get worse with "hours" first.
- moins — "less / minus" — fixes 08 checkout_d10.
- plaît — "pleases (le pantalon vous plaît ? = do you like the trousers?)" — fixes 08 fitting_s01 — no « vous plaît » key, because it would swallow the gap line « Le soir, ___ vous plaît. »
- loin — "far (loin de = far from)" — fixes 18 pros_d03/d07/s01/d10.
- nom — "name (au nom de = in the name of)" — fixes 10 door_d02, 09 « Au nom ___ Théo » gap lines.
- la bise — + "(faire la bise = to greet with a kiss)" — fixes 14 cold_s02, 04 arrive_d04.
- me faire — "make me / do … for me (me faire un devis = give me a quote)" — fixes 15 repair_s01–s04 — fits « me faire un grand café ».
- trompé / trompée / trompés / je me suis trompée — + "(se tromper de … = to take the wrong …)" — fixes 10 ask_d02/d06/d07/d09/d10/s03 — note only. No « je me suis trompé » key, because the 10 ask_s03 Corriger word is trompé.

## Add (84)

- non merci — "no thank you" — fixes 14 symptom_d08 « Non merci, de l'eau » (MUST; « merci de » no longer swallows across the comma) — all 12 « Non(,) merci » lines read correctly; no « non merci de + verb » anywhere.
- on est — "we are (on est allés = we went)" — fixes 01 name_d10, origin_d07/d10; 05 who_*; 07 hours_d02/d05; 09 book_d06 etc.; 16 out_d07; 17 react_d02 — 30 lines, all "we are". « on est combien » still wins. I chose a key over widening est (the 09/16 suggestion), as the coordinator asked; the passé composé note covers the case those reports were worried about.
- on a — "we have (on a mangé = we ate)" — fixes 03 tutoyer_d08/s05, 09 options_d07, change_d08, 12 leak_d08, 14 better_d07, 16 order_d02, dinner_s01–s05, 19 vote_s02 — 20 lines, all "we have" or passé composé.
- on fait — "we do, we make / we're doing" — fixes 17 help_d09 and ~25 lines (on fait un apéro / un compromis / la bise …) — the longer keys on fait quoi / on fait comment still win.
- on dit — "we say, people say (on dit tu = we use tu)" — fixes 03 landing_d06 — 2 lines.
- on se dit — "we say to each other (on se dit tu = we use tu with each other)" — fixes 03 tutoyer_d03/d07 — 3 lines.
- on se fait la bise — "shall we do the cheek kiss? (faire la bise = to greet with a kiss)" — fixes 04 arrive_d02/d10 — 1 text.
- chez moi — "(at / to) my place, home" — fixes 02 commute_d05 (MUST: « De chez moi, c'est » was taken by moi c'est), 02 commute_d04, likes_d06; 07 errand_d08; 10 transit_*; 11 arrive_d03, work_d07; 17 react_s04, sympathise_s01, help_* — about 50 distinct lines read, including « c'est chez moi », « devant chez moi », « de chez moi »; all mean my place.
- chez toi — "(at / to) your place, home (tu)" — fixes 10 turn_d09, landmark_d04; 11 arrive_d10; 18 plan_d06, rent_d08 — « fais comme chez toi » still wins.
- chez lui — "(at / to) his place, home" — fixes 17 what_d08 — 1 use.
- chez nous — "(at / to) our place, home" — fixes 01 flat_s05 « Bienvenue chez nous » — 2 uses (+ « apéro chez nous »).
- le lundi / le samedi / le dimanche — "on Mondays / (on) Monday" etc. — fixes 03 quartier_d02–d07; 07 hours_d01/d02/d06/s01/s04; 09 slot_d10; 10 landmark_d06 — about 25 lines, all habitual or "on Sunday". No le mardi to le vendredi uses exist, so those keys were not added.
- le matin — "in the morning / the morning" — fixes 02 morning/commute/react/hobbies/frequency (about 30 lines), 03 quartier_d07, 14 pharmacy_d09, 18 decide_d04, 20 reason_d04/d05.
- le soir — "in the evening / the evening" — fixes 02 likes/react/hobbies/frequency, 03 quartier_d09, 12 visit_d04, neighbour_d05, 13 formal_d07, 18 decide_d04 — « midi ou le soir » gets the "/ the evening" sense.
- le week-end — "at the weekend / the weekend" — fixes 02 weekend_* — 14 doctor_d06 « depuis le week-end » gets "/ the weekend".
- je le / tu le — "I … it / him", "you … it / him" — fixes 04 group_d03, 13 reason_d01, 18 plan_d01, bike_d10, better_d01/d04/d10, and « je le prends / cherche / rapporte / prendrais » (×30) — every « je le » / « tu le » in the book is the object pronoun.
- je la / tu la — "I … it / her", "you … her / it" — fixes 04 arrive_d09, 10 lost_d07, landmark_d03/d07, « je la prends / laisse / regarde / fais » — all are pronouns. This replaces 10's « je la vois » key.
- je les / ne les — "I … them", "(not) … them" — fixes 04 group_d06 and « je les prends / remplace / coupe / répare / appelle / ai » — all are pronouns.
- le voir / le visiter — "see it / him", "visit it, view it" — fixes 18 better_d08, rent_d01 — « je voudrais le voir » (08) also fits.
- entre amis / entre deux / entre les deux / entre le — "among friends", "between two", "between the two", "between the" — these keep every preposition use of entre off the new "come in!" first sense: 04 invite_d05, 20 ask_d03/s03/s05, 18 decide_d01/d10/s01/s05.
- il faut — "you have to, you need (to)" — fixes 08 exchange_d09, refund_d05; 09 voicemail_d01; 11 work_d01/d04; 14 pharmacy_d07; 19 vote_* — all 13 uses are impersonal. The Corriger keepApart on « voté » is unaffected.
- qu'il y a — "that there is / that there are" — fixes 06 mixup_d01/s01/s02/s03/d08 (MUST), 12 neighbour_d08 (MUST).
- il en reste — "there's … left / there are … left (of them)" — fixes 08 colour_d09 (MUST) — 1 use.
- ça va être — "it's going to be" — fixes 03 register_d01 (MUST) — 1 use.
- ça ne va pas — "aren't you well? / it's not OK" — fixes 14 symptom_d02 — 1 use; « qu'est-ce qui ne va pas » still wins.
- ça dépend du — "it depends on (the)" — fixes 18 decide_s01/d02/d03/s02/d05/d08/d09/s05 (MUST) — includes « du temps » = "on the weather". Tiles are unaffected.
- ce que / ce qui — "what (= the thing that)", "what (as subject: the thing that)" — fixes 15 wrong_s01/d06/s03 (MUST) and the 15 wrong_s01 tile — elsewhere these words occur only inside qu'est-ce / est-ce tokens, which cannot match.
- toujours pas — "still not" — fixes 15 parcel_d01, again_d01/s01/d04 — all 7 uses; the « pas toujours » distractor is unaffected.
- depuis toujours — "forever, all my life" — fixes 01 askback_d04 — 1 use.
- ne marche plus / marche plus / ne marchent plus — "doesn't work any more", "… (informal, ne dropped)", "don't work any more" — fixes 12 broken_d02/s02 (MUST), 15 bike_d06 — no other « marche plus » exists.
- faire réparer — "have … repaired, get … fixed" — fixes 15 bike_d06 — 1 use.
- toutes les — "every (toutes les dix minutes = every ten minutes)" — fixes 11 another_d02/d05 (MUST) — 3 lines.
- tous les soirs — "every evening" — fixes 20 reason_d03 — 1 use.
- quelle heure — "what time" — fixes 11 desk_s05, 10 landmark_d06, 07 « jusqu'à quelle heure », 02 « Il est quelle heure ? » — « à quelle heure » still wins in about 60 lines.
- quelle journée — "what a day" — fixes 11 cancelled_d07, group_d02, arrive_d03; 12 broken_d02; 02 react_d06; 17 help_d09.
- combien de temps — "how long" — fixes 02 commute_d09 — 1 use.
- à la télé — "on TV" — fixes 02 likes_d04/d08/s05, react_s03/s04; 16 mood_d07 — all mean "on TV".
- et demi — "half past (after midi / minuit)" — fixes 02 morning_d09 — the 02 morning_s03 Corriger line (error word demi) stays split. The tiles « et demi. » / « et demi ? » show the real meaning.
- aimes bien — "like (tu)" — fixes 02 likes_d05 — 2 lines.
- à côté de — "next to" — fixes 09 options_d05, name_s05 tile — 20 lines, all "next to".
- à tout de suite — "see you in a minute" — fixes 11 another_d10 — 1 use.
- à cet après-midi — "see you this afternoon" — fixes 12 plumber_d03 — 1 use.
- à quand — "(to) when" — fixes 13 newplan_d10 « On remet ça à quand » — 1 use.
- bon après-midi / bon anniversaire — "have a good afternoon", "happy birthday" — fixes 12 plumber_d07, neighbour_d08, 08 gift_d10.
- au fond du — "at the back of the" — fixes 08 checkout_d05, checkout_s02 — 4 lines.
- à ma taille / à votre taille — "in my size", "in your size (vous)" — fixes 08 size_d06/d08, colour_s01.
- si besoin — "if needed" — fixes 08 browse_d08 — 1 use.
- besoin d'un — "need a (avoir besoin de = to need)" — fixes 20 inplace_d09 — 1 use.
- je vous écoute — "I'm listening (how can I help?)" — fixes 09 book_s01/s02, confirm_s01, change_s01; 13 formal_s01; 15 parcel_d07.
- je vous prends / je te prends — "shall I get you / I'll get you (vous / tu)" — fixes 07 bread_d08, 06 usual_d07, takeaway_d08 — all mean "get for you".
- mal de tête — "headache" — fixes 14 pharmacy_d04/s05 (MUST).
- vous avez mal / tu as mal — "you're in pain, does it hurt? (… mal à = your … hurts)" — fixes 14 symptom_*, doctor_* (MUST), 17 what_d03/d06/d09 — 20 lines. No « t'as mal » exists, so that key was not added.
- encore mal — "still hurting, still in pain" — fixes 14 symptom_d07/d10, doctor_d03.
- prenez soin de vous — "take care of yourself (vous)" — fixes 14 cold_d01/d08, 13 react_s04.
- la barquette — "the punnet, per punnet" — fixes 07 price_d01/d03/d08/s01 — the wrong tile « le barquette » is unaffected.
- même heure — "same time" — fixes 05 move_d01 — « à la même heure » / « au même heure » (wrong tile) also fit.
- à deux minutes / à cinq minutes — "two minutes away", "five minutes away" — fixes 05 meet_d09, 20 formal_d04, weigh_d03, 18 pros_d09, area_d09.
- pour moi c'est — "for me, it's" — fixes 05 time_d07 — 1 item (spans the comma on purpose).
- c'est pour moi — "it's for me / it's on me (I'm paying)" — fixes 16 dinner_d03 — 14 better_d10 ("on me") and the 08 gift_d08 tile ("for me") also fit.
- ça vous plaît — "do you like it? (vous)" — fixes 15 haircut_d10 — 1 use.
- ça vous dirait — "would you fancy it? (vous)" — fixes 19 propose_s02 — 1 use.
- il est comment — "what's it like? / what's he like?" — fixes 18 pros_s01 — 1 use.
- comme tu veux — "as you like (tu)" — fixes 19 prefer_s02/s04/d08, 16 dinner_d03 — 4 lines.
- tu as fait comment — "how did you manage? / what did you do? (tu)" — fixes 17 what_d02 — the gap version is unaffected.
- elle a raison / elle a eu raison — "she's right", "she was right" — fixes 20 weigh_d04, after_d10.
- pas de chance — "bad luck / too bad" — fixes 20 weigh_d08 tile, 15 again_d07.

## Rewrite (1)

- sit_02_morning_d07 turns[1].text « Non, plus ___ : vers huit heures. » → « Non ! Plus ___ : vers huit heures. » (MUST, 02). The filled line « Non ! Plus tard : … » now segments as non · plus tard = no · later. The distractor fills (plus tôt / plus vite) segment cleanly too. No accepted-reply array or other text in the item repeats the old string. If line audio is keyed on the text, this line needs a new clip.

## Report findings dropped or changed

- 02 court "runs / short" (and pas trop court key): the key « pas trop court » = "not too short" already exists, and « trop court » too, so every "short" use is already right. No change needed.
- 02 « de la » key: dropped per coordinator. It would hit « de la voir », « de la cuisine » = from the. Covered by the de widening.
- 04 « a besoin de », 09 « demande de », 13 « obligée de / obligé de »: dropped as redundant. The besoin / de widenings cover them.
- 04 invite_d09 « Moi ! C'est à quelle heure ? »: a dump artifact. The app's segmenter breaks phrases at the free-standing « ! », and my replica confirms it shows moi · c'est. No change.
- 05 / 06 / 08 / 09 gap artifacts (« ça ___ va », « je ___ prends »): the app emits the gap as its own segment. No change.
- 06 « c'est bien ça » key: DROPPED. It would also match 15 complain_d06 « Super ! C'est bien, ça. » ("That's good.") across the comma and gloss it "is that right?". The bien widening ("really, indeed") makes 06 takeaway_d05 readable. SHOULD only.
- 09 « décale à / décaler à / décalé à » and 13 « reporter à / reporté à / on remet ça à »: not added. After the literal-first reorder of the à + day keys, « On décale à mardi » reads move · to Tuesday. 13 newplan_d10 « à quand » got its own key.
- 09 / 16 widen « est » to "(on est = we are …)" and 09 / 12 / 16 widen « a » to "(on a = we have)": replaced by the coordinator's on est / on a keys. Verified: no « on est allés » or other clash exists.
- 10 « je la vois », 13 « je le dis »: replaced by the general je la / je le keys.
- 11 reorder heures to "hours / o'clock" and 20 reorder toujours to "always / still": I kept the majority sense first and added a note instead, so about 100 clock lines and about 15 "still" lines do not get worse.
- 13 « pas de retard » = "no being late!": dropped. The gloss is awkward, and the pas note "(pas de … = no …)" already gives "no lateness".
- 14 « t'as mal »: not added (no uses in the book).
- 14 "bien chaud" note: folded into the bien widening as the "really" sense.
- 15 « ça vous plaît » plus plaît widening: both done. No « vous plaît » key (it would swallow the « ___ vous plaît » gap line).
- 18 du widening "(ça dépend du = …)": not needed after the ça dépend du key. « et du réseau » keeps "some / of the / from the".

## Counts

widen 57 · add 84 · rewrite 1. Every MUST is resolved (24 MUST lines across reports 02, 03, 05–12, 14, 15, 17, 18).
