# Book 3 — *Nuances* (archived 2026-10-22)

The user archived Book 3 on 2026-10-22 after the strip-down pilot. It was removed
from the app (no shelf entry, no code, no bundled content). Nothing was
deleted; everything is here.

## What is here

| Path | Was |
|---|---|
| `app/Features/Nuance/` | `carambole/Features/Nuance/` (session view, attempt policy + tests) |
| `app/Models/Nuance.swift` | `carambole/Models/Nuance.swift` (card model, selector, mastery gate) |
| `app/Resources/Nuances/` | `carambole/Resources/Nuances/` (shipped 550-card package, 20 modules) |
| `app/Debug/` | `carambole/Debug/Book3Pilot*.swift` + `testbook_book3*.json` (Test book drafts) |
| `tools/nuances/` | `tools/nuances/` (packager, checks, migration tests; paths inside still point at the old locations) |
| `design/book3-pilot/` | strip-down pilot page, tile-alignment comparison, simulator shots |
| `docs/` | every `docs/plans/*book-3*` plan and handoff, oldest to newest |
| `restore-integration.patch` | the edits to shared app files that removed Book 3 |

Start with `docs/2026-10-22-book-3-strip-down-handoff.md` for the last state
and the user's decisions (5-second cards; goal is vocabulary + grammar).

## What stayed in the app

- The v6 migration in `CoreDataManager.migrate()` and its `nuance_card_log`
  table. Migrations are additive only, so existing installs keep the table and
  any Book 3 history; nothing reads it now.
- Saved settings under `settings.book_fr_nuances.*` and any `review_status`
  rows for Book 3 element IDs stay in the database, unused.

## Restore

1. Move the `app/` folders back to their `carambole/` paths (and `tools/nuances/`).
2. `git apply archive/book3-nuances/restore-integration.patch` from the repo
   root. It restores `BookKind.nuances`, `BookCatalog.nuances`, the loader, the
   session switch, settings, library model, module rows, DB helpers and the
   Test book rows.
3. Build for the simulator and check the shelf shows three books.
