# Texas Tech Virtual Vietnam Archive: letters

Starting point for using wartime letters from the Vietnam Center & Sam
Johnson Vietnam Archive (Texas Tech University) as sources. Saved
2026-10-26 so a later pass can begin from here. The operator plans to go
through the letters later.

## What the archive is

The Virtual Vietnam Archive (https://www.vietnam.ttu.edu/virtualarchive/)
is the archive's online catalog. The catalog itself runs on
vva.vietnam.ttu.edu. Letters are not a separate archive: they sit
inside donor collections, as items with titles like "Letters". Each
collection has a finding aid (`/repositories/2/resources/<id>`). Each
digitized item has a record (`/repositories/2/digital_objects/<id>`).

Item numbers encode the collection: item 25480101001 is collection
2548, box 01, folder 01; a finding aid's own number is the collection
number followed by zeros (29230000000).

## URLs

| What | Pattern |
|---|---|
| Item record | `https://vva.vietnam.ttu.edu/repositories/2/digital_objects/<id>` |
| Finding aid | `https://vva.vietnam.ttu.edu/repositories/2/resources/<id>` |
| Permalink (cite this) | `https://www.vietnam.ttu.edu/virtualarchive/items.php?item=<item number>` |
| Scan (PDF) | `https://vva.vietnam.ttu.edu/images.php?img=/images/<collection>/<item number>.pdf` |

Copyrighted items have a record but no downloadable scan; those are in
the Vietnam Reading Room (https://readingroom.vietnam.ttu.edu/), which
needs a registered account.

## How the host behaves (2026-10-26)

- **Certificate.** The server sends its own certificate without the
  intermediate (InCommon RSA Server CA 2). Browsers fetch the missing
  intermediate; Ruby and WebFetch fail with "unable to get local issuer
  certificate". The fetcher bundles the intermediate in
  `this-day/config/certs/` and still verifies to a system root.
  `cert_chain.rb` shows what a host presents; `get_intermediate.rb` is
  how the bundled certificate was obtained and checked.
- **Timeouts.** About one request in three ends in Net::OpenTimeout.
  `fetch_record.rb` tries each record three times.
- **Search is closed to scripts.** `/search` answers non-browser
  clients with a CAPTCHA ("User validation required"). Do not try to
  get around it. Records can be fetched only by a known id: from a web
  search, from a citation, or from the operator browsing the catalog.
- **Scans fetch.** The Pike *Viet Cong Strategy of Terror* PDF that
  failed at www.vietnam.ttu.edu/reports/images.php?img=/images/231/2311404008a.pdf
  downloads from `https://vva.vietnam.ttu.edu/images.php?img=/images/231/2311404008a.pdf`
  (200, application/pdf, 715,994 bytes).

## Files

- `fetch_record.rb`: fetch records by path (`resources/2366`,
  `digital_objects/596475`), save the HTML under `records/`, and write the
  title, item number, catalog fields, permalink and scan URLs to
  `records.yaml`. `--reparse` rebuilds `records.yaml` from the saved HTML
  without fetching.
- `records.yaml`, `records/`: the eleven records found on 2026-10-26.
  These are web-search hits for letter collections, not a survey.

| Record | Title | Scan |
|---|---|---|
| digital_objects/407268 | Letters Home: Words of a Nation at War (one page, 2002) | yes |
| digital_objects/596475 | Transcript of Letters from Kieth, Judy and Dad (13 pages) | yes |
| digital_objects/69011 | Letters, Allen Cates Collection (1998) | yes |
| digital_objects/69079 | Letters, Allen Cates Collection (1999) | yes |
| resources/2366 | Billy R. Whisenant Collection (2923) | finding aid |
| resources/3001 | Richard D.B. Shepherd Collection (3537) | finding aid |
| resources/2134 | Ralph M. Smith Collection (2607) | finding aid |
| resources/2294 | Robert T. Jordan Collection (2823) | finding aid |
| resources/705 | Lawrence Martin Collection (868) | finding aid |
| resources/3073 | Edward Voluntad Collection (3597) | finding aid |
| resources/1145 | Heyward MacDonald Collection (1531) | finding aid |

## Open questions for the operator

- Which collections to read, and whether letters become a source for
  day entries (a dated letter as the event).
- Letters written by private people may be under copyright even when
  the archive offers the scan. An entry would quote only the passages
  used, as for other copyrighted sources.
