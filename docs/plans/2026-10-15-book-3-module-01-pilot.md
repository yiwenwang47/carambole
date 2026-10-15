# Book 3, module 01: review pilot

**Status:** Draft for card review. This is not a content schema or a module-size decision.
**Curriculum source:** [Book 3 handoff](2026-10-15-book-3-curriculum-handoff.md).

## Aim

In *Ce qui s'est passé*, the learner separates a continuing setting from an
event that changes it. The cards pair *imparfait* and *passé composé* with
*une panne*, *s'interrompre*, and *au moment où*. All information needed to
answer is in the French source or the short task. There is no scene-setting
cue above the source. Audio, if added later, repeats visible French.

## Provisional card and answer model

One card has a format, visible French source blocks, one task, one response
control, a model answer, and concise feedback. Dialogue blocks carry speaker
names. A microtext, rewrite, or word-in-context card uses the same source area
without pretending to be a chat. A card may link words to optional tap glosses;
the gloss is support, not a hidden fact needed to solve the task. Each pilot
card records one response; how cards group into an FSRS review unit is open.

For this pilot, interpretation questions use choices. Only tightly constrained
sentence rewrites use typing. A typed answer is checked against a small,
author-reviewed list of complete acceptable forms after Unicode normalization,
case folding, whitespace collapse, apostrophe normalization, and removal of
terminal punctuation. Accents and tense remain significant. Do not use fuzzy
matching, an LLM grade, or a silently broadened synonym list. An unlisted but
valid answer is a content defect to catch in review; before a production typing
drill can affect FSRS, the card needs either exhaustive accepted forms for its
narrow task or a response control that avoids that risk. No pilot answer asks
the learner to type punctuation.

The eventual Book 3 content should get its own book ID and noncolliding element
IDs. It can reuse the in-memory Book → Module → Element structure, shared FSRS
grading, and `TooEasyGate`. Its cards, selection, and any item history need a
Book 3 path; Book 2's `SituationItem` requires a cue and permits two drills,
which conflict with this pilot. History and settings remain scoped by book ID
or by that book's element IDs. Any new persisted fields or tables require a
new additive `CoreDataManager.migrate()` version; existing migration blocks and
user rows stay untouched. The exact schema, review unit, graduation gate,
vocabulary UI, and audio policy wait for card feedback.

## Eight cards for review

The order lets *panne*, *s'interrompre*, and *au moment où* recur. Choices are
listed here for review; the app would shuffle their display order.

### 1. Dialogue · identify an event

**French source**

> Lina : La salle était pleine quand la lumière s'est éteinte.
>
> Marc : Le concert s'est interrompu pendant deux minutes.

**Task:** Quel événement a interrompu le concert ?

**Choices:** La lumière s'est éteinte. / La salle était pleine. / Le concert a commencé.

**Answer:** La lumière s'est éteinte.

**Feedback:** *Était pleine* décrit la situation ; *s'est éteinte* marque l'événement.

### 2. Microtext · find the change

**French source**

> La bibliothèque était calme. Au moment où j'ouvrais mon livre, une panne a
> coupé la lumière. Nous sommes sortis.

**Task:** Qu'est-ce qui a changé la situation ?

**Choices:** Une panne a coupé la lumière. / La bibliothèque était calme. / J'ouvrais mon livre.

**Answer:** Une panne a coupé la lumière.

**Feedback:** Le calme et la lecture sont le cadre ; la coupure survient ensuite.

### 3. Rewrite · report the event

**French source**

> Le micro s'interrompt pendant que la guide parle.

**Task:** Mets l'événement au passé composé : « Le micro s'interrompt. »

**Typed answer:** Le micro s'est interrompu

**Feedback:** *S'est interrompu* présente l'arrêt comme un événement terminé.

### 4. Word in context · infer a noun

**French source**

> Une panne a coupé la lumière de la bibliothèque ; les lampes ne fonctionnaient plus.

**Task:** Que signifie « une panne » ici ?

**Choices:** Un problème technique. / Une fermeture prévue. / Une lampe neuve.

**Answer:** Un problème technique.

**Feedback:** Les lampes ne fonctionnaient plus à cause de ce problème.

### 5. Dialogue · identify the setting

**French source**

> Nadia : Je traversais la place quand la pluie a commencé.
>
> Hugo : Et les vendeurs ?
>
> Nadia : Ils ont fermé leurs stands.

**Task:** Que faisait Nadia quand la pluie a commencé ?

**Choices:** Elle traversait la place. / Elle fermait un stand. / Elle attendait Hugo.

**Answer:** Elle traversait la place.

**Feedback:** *Traversais* décrit l'action en cours au début de la pluie.

### 6. Microtext · separate background from event

**French source**

> Le train roulait lentement. Au moment où nous approchions de la gare, il
> s'est arrêté. Le conducteur a annoncé une panne.

**Task:** Que faisait le train avant de s'arrêter ?

**Choices:** Le train roulait lentement. / Le train s'est arrêté. / Le conducteur a annoncé une panne.

**Answer:** Le train roulait lentement.

**Feedback:** *Roulait* décrit la situation ; *s'est arrêté* est l'événement.

### 7. Rewrite · report the setting

**French source**

> La rue est déserte quand le bus arrive.

**Task:** Mets le cadre à l'imparfait : « La rue est déserte. »

**Typed answer:** La rue était déserte

**Feedback:** *Était* décrit le cadre dans lequel le bus est arrivé.

### 8. Word in context · understand a relation

**French source**

> Au moment où le rideau s'est levé, le public parlait encore.

**Task:** Que relie « au moment où » ici ?

**Choices:** Deux actions qui se passent en même temps. / Une cause et sa conséquence. / Deux lieux différents.

**Answer:** Deux actions qui se passent en même temps.

**Feedback:** Le rideau se lève pendant que le public parle encore.

## Review questions

Please judge the cards as learner-facing material: source length, difficulty,
whether the task feels natural, how much feedback helps, and whether optional
tap glosses would be enough for unfamiliar words. The two typed rewrites test
whether the answer is short and constrained enough for reliable checking. The
number of cards here is a review-set size, not a proposed module size.
