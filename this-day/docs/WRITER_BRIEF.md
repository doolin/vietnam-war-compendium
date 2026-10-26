# Writer brief — month provisioning

The standing instructions for an agent that writes draft events from a
`rake provision:fetch` brief. The dispatching prompt names the month,
the days, and the output file; everything else is here. Paths are
relative to `this-day/`.

## Tools: Read and Write only

Do not use Bash, Grep, Glob, WebSearch, or WebFetch. Every call outside
Read and Write interrupts the operator with a permission prompt.
Everything needed has already been fetched and archived.

## Inputs

- `docs/SUMMARY_STYLE.md`: the binding style brief. Read it first.
- `tmp/provision-<month>/brief.md`: for each uncovered day, up to four
  ranked candidates. Each has the Wikipedia entry text (quoted), its
  revision permalink (archived), and the entry's own cited sources
  with archive status and a `Text:` path to the archived copy as plain
  text (with byte size). PDF text has `=== page N ===` markers (PDF
  page; the printed page number is usually the first line after the
  marker).
- Under each `Text:` line the brief lists "Lines naming <Month> <day>"
  with line numbers (and PDF page). To read a passage, Read the text
  file with `offset` about 40 lines before the listed line and `limit`
  about 120. Do not Read a large file whole. "none" means the date
  string was not found; the source may still cover the event under
  another date form, but treat it as weaker.
- A small `Text:` file that is only a page shell (an index or catalog
  page, an archive.org "details" page, a Google Books page) does not
  carry the event. Every candidate citing Birtle, *Advice and Support:
  The Middle Years*, points at an empty CMH catalog page.
- For an empty text file from a PDF (a scan), the original is at
  `archive/cache/<same key>.pdf`; Read it with `pages` (at most 20 per
  call). Mark such excerpts "transcribed from the scan".
- Pike, *The Viet Cong Strategy of Terror* (URL ending
  `2311404008c.pdf`) is part c of the scan, printed pp. 90–125; its
  incident chronology gives one sentence per incident.
- **Unreadable OCR:** quote OCR text as found. Never supply a word the
  scan does not show. If a needed word is unreadable in the text file,
  read the page image; if it is unreadable there too, write around it
  with words the source does print, and report it.

## Process per day

1. Choose the candidate whose archived source text covers the event;
   prefer a primary or official source, then a reputable secondary. A
   full account beats a one-sentence chronology entry. If no
   candidate's source covers it, choose the strongest candidate and
   write from its Wikipedia entry alone.
2. **One event per entry.** A Wikipedia entry often joins unrelated
   events; write about one. Do not join events with "The same day".
   One entry per day.
3. Write from the archived text. Where source and Wikipedia disagree
   (date, number, name, unit, outcome), follow the source and report
   it. If the source gives another year, set `year` to it and report
   it. **If the source gives another month or day, write the entry for
   the source's date** (set `month` and `day` to it), report it
   prominently, and write the assigned day from another candidate if
   one is usable; a date can carry several entries.

## Rules (SUMMARY_STYLE.md is binding)

- Every fact, name, number, place, and unit in the body appears in
  `source_text`. Nothing from memory, even if true.
- The body opens "On <Month> <day>, <year>, ", has 80–180 words (count
  them; 180 is a hard limit), 1–3 `<p>` paragraphs, past tense, no
  editorializing. Banned: richer, exactly, honest, cleanly, spine,
  load-bearing, settles, importantly; no "not X but Y". If the sources
  hold fewer than 80 words' worth, write what they support and report
  the count; do not pad.
- `source_text`: the verbatim passages written from, each prefixed
  with a bracketed locator, e.g. `[Futrell, The Advisory Years, p. 25]`
  or `[Wikipedia, 1965_in_the_Vietnam_War, rev 1370279555]`. Verbatim
  means copied from the text file. For copyrighted sources, only the
  passages used.
- `references`: the source written from first (label: author,
  "title", publisher or host, year, page), with the exact URL in the
  brief; then the Wikipedia permalink, labelled `Wikipedia, "<year> in
  the Vietnam War", revision <revid> (CC BY-SA 4.0)`. Only URLs whose
  archive status in the brief is ok. One to three references.
- `title`: short, active, specific. `status: draft`.
  `summarized_by: Claude Opus 5.5`. `summarized_at`: as given in the
  prompt. `photo_url: null`. `photo_alt: null`.

## Output

One YAML file, written with the Write tool to the path in the prompt:
an array, one event per entry, keys exactly `month, day, year, title,
body, photo_url, photo_alt, references` (list of `{label, url}`),
`status, source_text, summarized_by, summarized_at`. Quote strings
that contain colons. Read it back once.

Final report, short, flags not prose: per day, the candidate year
chosen, the source used (or "Wikipedia only" and why), the word count,
and every discrepancy between source and Wikipedia.
