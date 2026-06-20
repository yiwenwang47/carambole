# Progress + History Tracker — Design

Date: 2026-06-19
Branch: `progress-history-tracker` (off `main`)

## Goal

Three additions, scoped to the current book:

1. **Daily progress line** — in the book home "Aujourd'hui" panel, show how many
   elements were **learned** and **reviewed today** (work *done*, distinct from the
   existing "X new · Y due" which is work *remaining*).
2. **Réviser round size** — an inline `10 · 20 · 50` toggle that caps how many
   problems a single Réviser tap presents. Layers on top of the existing
   `reviewTarget` soft pool.
3. **History page** — a separate, pushed page showing per-day learned/reviewed
   counts for the current book.

## Definitions (confirmed)

- **learned(day)** = elements whose `first_seen_date` falls on that calendar day.
- **reviewed(day)** = elements with a review logged on that day **minus** elements
  first-seen that same day (genuine re-grades only; no overlap with learned).
- Both are scoped to the current book by intersecting with `book.allElements` ids.
  The global `newPerDay` budget logic (`countNewIntroduced`) is left untouched.

## Data model

`first_seen_date` is a permanent per-element stamp → learned-per-day is fully
reconstructable from `review_status`. `last_review_date` keeps only the *latest*
review → past reviewed-per-day is **not** reconstructable; reviews need an event log.

### Migration → `user_version` 2 (additive, new block; never edit v1, never DROP)

```sql
CREATE TABLE IF NOT EXISTS review_log (
  element_id TEXT NOT NULL,
  day_start  REAL NOT NULL,            -- local startOfDay epoch (Calendar.startOfDay)
  PRIMARY KEY (element_id, day_start)  -- distinct element-per-day, INSERT OR IGNORE
);
```

Backfill once at migration so existing installs aren't all-zeros:
```sql
INSERT OR IGNORE INTO review_log (element_id, day_start)
SELECT element_id, <startOfDay(last_review_date)> FROM review_status
WHERE last_review_date IS NOT NULL;
```
(`startOfDay` bucketing done in Swift over a fetched list, then bulk-inserted — keeps
timezone logic in `Calendar.current`, consistent with `countNewIntroduced`.)

**Limitation:** reviewed-per-day before this migration is forward-only — backfill
seeds only the *latest* review day per element. Learned-per-day is fully historical.
Note in `HistoryView` footer + docs.

### Write path

`upsertReviewStatus` (the single grade write path) also does, when
`status.lastReviewDate != nil`:
```sql
INSERT OR IGNORE INTO review_log (element_id, day_start) VALUES (?, ?);
```
with `day_start = Calendar.current.startOfDay(for: lastReviewDate)`. The Apprendre
introduction grade writes a row too, but that day is subtracted out by the
`reviewed = reviewed − firstSeen` rule, so it never double-counts.

### New reads (`DataManager`)

- `fetchElementIDsFirstSeen(on day: Date) -> Set<String>` — first_seen within day window.
- `fetchElementIDsReviewedLogged(on day: Date) -> Set<String>` — review_log rows in day window.
- `fetchFirstSeenByElement() -> [String: Date]` — for history bucketing.
- `fetchReviewLog() -> [(elementID: String, dayStart: Date)]` — for history bucketing.

Day-tracker counts (today) use the two `…on:` set fetches; the history page uses the
two bulk fetches and buckets in Swift.

## App layer

### Settings — round size

`StudySettings.reviewRoundSize: Int`, allowed `{10, 20, 50}`, default **20**. Clamped
to the nearest allowed value on init (invalid persisted values never stored).
Persisted in `StudySettingsStore` (new key `settings.reviewRoundSize`). Self-test the
clamp + round-trip alongside the existing ones.

### Réviser queue slice

`BookViewModel.reviewSessionElements()` returns the existing due+overflow queue
`.prefix(reviewRoundSize)`. `reviewTarget` still bounds the overflow top-up, so the
round is `min(roundSize, due + overflow-toward-target)`. Tap Réviser → up to N → ends
→ panel refreshes on dismiss (already wired) → tap again for the next round.

### BookViewModel — today counts

Add `@Published var learnedToday: Int` / `reviewedToday: Int`, computed in `refresh()`
off-main alongside the existing due/new work:
```
let bookIDs = Set(book.allElements.map(\.id))
let firstSeen = DataManager.shared.fetchElementIDsFirstSeen(on: Date())
let reviewed  = DataManager.shared.fetchElementIDsReviewedLogged(on: Date())
learnedToday  = firstSeen.intersection(bookIDs).count
reviewedToday = reviewed.subtracting(firstSeen).intersection(bookIDs).count
```

### BookView — today panel + toggle

- Under the `X new · Y due` row, a lighter progress line:
  `N appris · M révisés` in graphite `uppercaseLabel` style.
- The whole progress line is a button with a trailing chevron → pushes `HistoryView`.
- A thin segmented `10 · 20 · 50` control beneath the Apprendre/Réviser buttons,
  labeled "Révision par tour", writing `reviewRoundSize` to the store.

### HistoryView (new, separate page)

- Pushed via `NavigationLink`/`navigationDestination` from the today progress line.
  `BookView` already lives in a nav stack (pushed from `LibraryView`).
- A small history VM loads `fetchFirstSeenByElement()` + `fetchReviewLog()`, intersects
  with `book.allElements`, buckets both by `Calendar.startOfDay`, and produces
  `[DayActivity { day: Date, learned: Int, reviewed: Int }]` sorted newest-first.
- Rendered as editorial day rows ("Le Cahier" style): `19 juin · 3 appris · 17 révisés`
  with a light proportional bar per row. Footer note on the reviewed-history limitation.
- Empty state when no activity yet.

## Verification

- Build gate: `xcodebuild build -project carambole.xcodeproj -scheme carambole
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO` → EXIT 0.
- `#if DEBUG` self-tests: settings clamp/round-trip; (pure-logic) day bucketing if
  factored out.
- Screenshot: today panel (with progress line + segmented toggle) and HistoryView.
- Spec-compliance + code-quality review per task before marking done.

## Out of scope / YAGNI

- Multi-book switching (only one live book; design is per-book-ready via `book.allElements`).
- Streaks, charts beyond a simple per-row bar, weekly rollups.
- Exposing `reviewTarget`/`masteryThreshold` (separate follow-ups).
