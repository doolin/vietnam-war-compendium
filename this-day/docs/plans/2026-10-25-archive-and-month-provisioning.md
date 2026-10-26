# Session plan — 2026-10-25

Reference archive, content audit, and a month-provisioning proof of
concept for This Day in Viet Nam. Written at session start; checked
off as work lands. Deploys after each numbered increment so the live
site shows progress.

## Increments

1. **Reference archive library.** `ThisDay::Archive` fetches each
   reference URL with per-domain politeness, stores the bytes under
   `archive/cache/` (gitignored), uploads to
   `s3://inventium-backups/this-day/references/`, and records a row in
   `data/archive/index.yaml` (committed): url, sha256, bytes,
   content type, fetched_at, s3_key, status, page title. Rake tasks
   `refs:archive` and `refs:audit`. Specs.
2. **Archive status on the page.** Seed joins the index; the
   references table gains `archived_at`. The event page marks each
   reference as archived or unverified. **Deploy.**
3. **Audit the existing 352 events.** Run `refs:audit`; record every
   failed fetch and every page whose title does not match its label.
   Rewrite or drop the flagged landmark and 1975 references.
4. **Month review page.** `/this-day-in-vietnam-war/review/10` lists
   every day of a month with its events, bodies, references, archive
   status, and draft/approved status. Events gain an optional `status`
   field (default approved for existing). **Deploy.**
5. **October provisioning.** For each of the 23 uncovered October
   days, draw a dated event from a fetchable, archivable source;
   write the event with `status: draft` and a `source_text` excerpt
   for review. **Deploy.**
6. **November provisioning.** Same for the 15 uncovered days.
   **Deploy.**
7. **Marp deck** on the implementation, grown through the session.
8. **Lessons** appended as they occur in `docs/LESSONS.md`.

## Progress

- [x] 1. Archive library, `refs:archive`, `refs:audit`, 17 specs. Deployed (7579932).
- [x] 2. Archive status on the page. Deployed (7579932).
- [x] 3. Audit run: 7 dead links, 1 bot wall misresolution, 4 invented ISBNs. Findings in `docs/LESSONS.md`.
- [x] 4. Month review page with status, source excerpt, credit. Deployed (ac89a06).
- [ ] 4b. Added mid-session: resummarize every event from its archived source with a credited model (`docs/SUMMARY_STYLE.md`).
  - [x] HistoryNet 1975 (12). Deployed (2b1bd35).
  - [x] Dereliction of Duty (31). Deployed (2b1bd35).
  - [x] Medal of Honor (264): 261 rewritten, 3 legacy kept (no citation).
  - [x] SOG Kontum, Forsaken Warriors, Laotian Panhandle (31).
  - [x] Landmark (12): re-sourced from public documents and rewritten (Claude Opus 5.5).
  - [ ] NARA DCAS (2): rewrite from the DCAS record after review items 4 and 5.
- Open questions for the operator: `docs/REVIEW_QUEUE.md`.
- [x] 5. October: 23 drafts, every day now has an event.
- [x] 6. November: 15 drafts, every day now has an event.
- [x] 6b. Dead references: Wayback fallback in the archiver; 9 of 14 failing URLs rescued. Open Library (61 book references) and one Texas Tech PDF remain.
- [~] 7. Deck growing in `docs/slides/`.
- [~] 8. Lessons growing in `docs/LESSONS.md`.

## Review loop (for the operator on a phone)

Open the review page for the month. For each day, the page shows the
title, body, the verbatim source excerpt the body was written from,
and each reference with its archive status. Reply in chat with
approvals or rejections by date ("approve Oct 3, Oct 4; reject Oct
7"). Approved events get `status: approved`; rejected ones are
removed or re-sourced.

## Coverage at session start

| Month | Days covered | Missing |
|---|---|---|
| October | 8 of 31 | 1, 3–11, 13, 16, 18–20, 23–30 |
| November | 15 of 30 | 2–4, 6, 11, 15–17, 21–24, 27, 28, 30 |
