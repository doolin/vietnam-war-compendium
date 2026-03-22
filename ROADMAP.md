# Vietnam War Compendium — Roadmap

## Current State (March 2026)

- **88 events** across 7 event files, spanning 1945–1975
- **5 Kindle highlight files** (4 fully processed into events, 1 unprocessed)
- **Scraper** operational with army.mil MOH citations cached
- **App** deployed on Lambda with date-based routing and prev/next navigation

## Structural Issues

### ~~1. File extension inconsistency~~
Resolved. All YAML files now use `.yaml`.

### 2. Timeline top-level key naming
Four different conventions across timeline files:
- `the_war_years:` — ia-drang-pimlott.yaml, starlite-pimlott.yaml
- `timeline:` — kindle-highlights-timeline.yaml, vietminh-timeline.yaml
- `Starlite:` — starlite.yaml (stub, see #4)
- `blocks:` — blocks.yaml
- bare array — tet-bigstory.yaml

Pick one and enforce it.

### ~~3. Empty URL strings in book-sourced events~~
Resolved. All book-sourced events now have Goodreads URLs. The process-highlights skill has been updated to use Goodreads as the default book URL.

### ~~4. starlite.yaml is a stub~~
Resolved. Deleted; real data is in `starlite-pimlott.yaml`.

### ~~5. No seed validation~~
Resolved. `db/seed.rb` validates required fields, date ranges (month 1-12, day 1-31, year 1940-1980), and reference completeness. Invalid events are skipped with warnings; build aborts if any errors found.

### ~~6. sample.yaml naming is ambiguous~~
Resolved. Renamed to `landmark-events.yaml`.

## Redundancy

### 7. Two parallel data paths
- **Timelines pipeline**: `kindle-highlights/*.yaml` → `extract_timeline.rb` → `timelines/kindle-highlights-timeline.yaml` → SVG
- **This-day pipeline**: `kindle-highlights/*.yaml` → manual/skill extraction → `this-day/data/events/*.yaml` → SQLite

Both consume the same highlights but produce different formats with no shared intermediate step. Fine for now but worth noting.

### 8. Highlight metadata unused downstream
`quality`, `tags`, and `status` fields in kindle-highlights are only used during processing — the event pipeline discards them entirely.

## Content Pipeline

### ~~Unprocessed highlights~~
Resolved. All Kindle highlight files processed. `war-for-ho-chi-minh-trail.yaml` contained 12 analytical/background highlights with no event candidates.

### MOH bulk extraction
- army.mil A-L and M-Z pages cached in `scraper/cache/`. Parser extracts ~260 recipients with dates, units, locations, citations. Two Marine events created as proof of concept. Remainder available for bulk extraction.

## Priorities

1. ~~Fix empty URLs~~ — resolved, all events now have Goodreads or source URLs
2. ~~Rename `sample.yaml`~~ — resolved, renamed to `landmark-events.yaml`
3. ~~Delete `starlite.yaml` stub~~ — resolved, deleted
4. Pick one timeline key and enforce it
5. ~~Add basic validation to `seed.rb`~~ — resolved, validates required fields, date ranges, reference completeness
6. ~~Process remaining MOH citations into events~~ — resolved, all 264 extracted
7. ~~Process `war-for-ho-chi-minh-trail.yaml` highlights~~ — resolved, all 12 processed; no event candidates (year-only dates, analytical/background material)
8. ~~Add disclaimer to the web page~~ — resolved, added to event template
9. Add SVG favicon of Vietnam country outline

## Scraper Infrastructure

A polite web scraper (`scraper/`) is in place for acquiring events from public domain government sources:

- **`scraper/lib/polite_fetcher.rb`** — per-domain rate limiting, parallel across domains, local HTML cache
- **`scraper/fetch.rb`** — CLI entry point for fetching and caching pages
- **`scraper/parsers/moh_army_mil.rb`** — parser for army.mil Medal of Honor citation pages (A-L and M-Z cached)
- **`scraper/parsers/moh_navy.rb`** — parser stub for Navy History site (blocked by SSL cert issue)
- **`scraper/cache/`** — gitignored; raw HTML cached locally to avoid re-fetching

### Active sources
- army.mil MOH citations: ~260 Vietnam War recipients with exact dates, units, locations, and full citation narratives.

### Future sources
- Navy History MOH pages (needs SSL workaround or curl-based fetch)
- VVMF Wall of Faces
- FRUS document collections
- Pentagon Papers
- DPAA unaccounted-for personnel (~1,584 Vietnam War records) — requires FOIA request; no API or bulk download exists. See `research/dpaa-nara-casualty-data.md`
- NARA DCAS Vietnam Conflict Extract (58,220 fatal casualties including 1,085 MIA, 116 POW, 124 MSG incident records) — downloaded to `research/nara-dcas/`, codebook in repo, `.dat` file gitignored. **TODO: archive `.dat` to S3 (`inventium-backups`)**

## Database Backup

S3-based backup and restore for the SQLite database, modeled on the `dbb` project's approach but without attestation reports or blockchain anchoring. The database is currently fully rebuildable from YAML source files via `rake db:build`, but as the schema grows some tables may not remain rebuildable from source alone. Backup increases optionality.

### Design

- **Bucket:** `inventium-backups`
- **Key structure:** `this-day/backups/{YYYYMMDD}/{HHMMSS}.sql.gz`
- **Format:** gzipped SQL dump via `sqlite3 <db> .dump`, not binary `.sqlite3` copy
- **Checksum:** SHA-256 of the compressed artifact, printed to console

### Rake tasks (in existing Rakefile)

- `rake db:backup` — dump, gzip, upload to S3
- `rake db:restore` — download from S3, decompress, restore into local SQLite
- `rake db:backup_round_trip` — backup → upload → download → restore to temp DB → checksum both SQL dumps → pass/fail to console

### Implementation notes

- Use AWS SDK (`aws-sdk-s3`) directly, same credentials/profile as the existing deploy tasks
- Restore should accept an optional S3 key argument; default to the most recent backup
- Round-trip verification compares SHA-256 of the original and restored plaintext SQL dumps (not binary DB files)
- Console output only — no PDF reports, no Solana anchoring

## Two Goals the Data Supports

### Timelines
SVG timeline visualizations generated from YAML data in `timelines/`. Supports level-of-detail tiers (0-3) and time-range blocks for zoom-based rendering.

### This Day in Viet Nam
Daily history page served by a Roda app on AWS Lambda with bundled SQLite3. Events sourced from `this-day/data/events/*.yaml`, built into the database via `rake db:build`, deployed via `rake deploy:all`. Date-based routing at `/this-day-in-vietnam-war/:month/:day` with prev/next day navigation.
