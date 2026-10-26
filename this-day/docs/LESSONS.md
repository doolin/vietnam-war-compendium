# Lessons Learned — This Day in Viet Nam

Running log. Newest at the bottom. Each entry: what happened, what it
cost, what to do instead. Dated so a later reader can line it up with
git history.

## 2026-10-25 — Audit before adding

Three LLM generations wrote the first 352 events. Reading them back
sorted into tiers: the Medal of Honor citations are sound but
truncated by the parser; the four Kindle-sourced files are honest but
thin (Goodreads URL, no page or location); the 24 "landmark" and 1975
events were written from model memory with Amazon product pages and
unverified .gov links as references. The honest-but-thin tier came
from a process-highlights rule that forbade adding anything beyond
the highlight text. The rule prevented hallucination and guaranteed
shallow bodies. Both failure modes come from the same missing piece:
no record of what source was actually consulted.

Lesson: a reference is not a URL. It is an archived copy plus a
hash plus a fetch date. Build that first, then audit, then add.

## 2026-10-25 — Permission shape, not permission scope

A long remote session tempts you to widen the allowlist. The
operator's rule is narrow prefixes only. The right speed-up is to
put recurring work behind `bundle exec rake` tasks and `ruby`
scripts, which the project already allows, and to fetch with Ruby
rather than curl.

## 2026-10-25 — A 200 is not a source

First archive run over the 32 unique reference URLs: 7 of the
"official-looking" links in the hallucinated tier returned 404
(two archives.gov pages, a Marine Corps University page, an Army
CMH publication, a Defense.gov PDF, an LBJ Library transcript).
Goodreads returned 503 to a polite fetcher. Amazon returned 200
with a bot-wall page titled "Amazon.com", so the fetch "succeeded"
and proved nothing. One Amazon ISBN link labeled *Decent Interval
by Frank Snepp* resolved to a book about a 1741 New York slave
conspiracy. The model had invented the ISBN.

Lesson: the archiver must compare the fetched page's title to the
label. A 200 with the wrong title is worse than a 404 because it
looks verified. Book references need a bibliographic record
(ISBN resolved through an open catalog), not a storefront URL.

## 2026-10-25 — ISBNs are a hallucination surface

Resolving the fourteen Amazon ISBN links through Open Library:
five were correct, four pointed at unrelated books (a Czech
detective novel for *Lyndon Johnson's War*, Old English poems for
*Pleiku*, a Royal Navy ship list for *Forsaken Warriors*, a novel
for Appy's oral history), and the rest could not be resolved. A
ten-digit number looks like a citation and costs nothing to invent.

Lesson: an ISBN is only a citation once something has resolved it
and returned the expected title. Open Library's `/isbn/<n>` and
`/works/<id>` pages are fetchable, archivable, and carry author,
publisher, and year, so they replace storefront links as the book
reference target.

## 2026-10-25 — Thirteen agents at once hit two different limits

Running eight Medal of Honor rewriters, two Kindle rewriters, a
HistoryNet rewriter, and three research agents in parallel tripped
the account's session limit; six agents stopped mid-task until
credits were added, then resumed from their transcripts by message.
Separately, about thirty polite requests to Open Library in twenty
minutes earned a "Human Verification" page, then connection resets.
The archiver had recorded the verification page as a successful
archive because it was a 200 with a title.

Lessons: budget the wave, not the agent, and expect to resume rather
than restart. Treat any 200 whose title reads like a robot check as
a failure (`bot-wall` status) so it is retried and never counted as
verified. Fetch catalog metadata once and cache it before fanning
out agents that all want it.

## 2026-10-25 — Re-sourcing is where the corrections come from

Rewriting a body from its old text fixes prose. Rewriting it from a
newly fetched primary source fixes facts. The twelve "landmark"
events, re-sourced from FRUS, presidential papers, and a 1969 USMC
history, changed in four places: a wrong date (the New Hampshire
primary), a wrong actor (ARVN Rangers, not Marines, at Khe Sanh on
March 1, 1968), an unsupported figure, and an unsupported
"five days after". The casualty file did the same to the MIA
events. None of these were visible from the old text alone.

Lesson: budget for a source-finding pass separate from the writing
pass, and give the writer only the fetched passages.

## 2026-10-25 — Wikipedia year pages as a candidate index

The 21 "YEAR in the Vietnam War" pages yielded 449 dated October and
November entries, at least three for every day, each with its
revision id and the citations attached to it. They work as an index
of candidates, not as the source: a draft quotes the entry, cites the
permalink, and carries the entry's own cited source when it has a
URL (FRUS, Army CMH, Nixon Library). About a third of entries have no
URL citation; those drafts are single-source and marked for review.

## 2026-10-25 — Line endings on committed files

AGENTS.md was committed with CRLF. The repo's `.gitattributes`
normalizes new commits but does not rewrite history, so the first
edit through the file tools turned a one-line change into a
whole-file diff. Normalize once, in the same commit as the edit,
and say so in the message.

## 2026-10-26 — A dead link is usually still in the Wayback Machine

Fourteen cited URLs would not archive: ten dead government and
university pages (404s, retired hosts such as afhso.af.mil and
usno.navy.mil, a 403) and four Open Library pages behind a bot wall.
The Wayback Machine had a 200 capture of nine of the ten, including
four full PDFs (two Futrell Air Force histories, Cosmas's MACV
volume, the 1971 typhoon report) totalling about 95 MB. The archiver now falls back to the latest such capture, keeps
the cited URL as the key, and records `via: wayback`, the snapshot
URL, the capture date, and the live failure. The page links the
Wayback copy beside the dead link.

Use the CDX API, not the availability API. The availability API
answered 429 on the first request of the session and returns the
closest capture whatever its status, which for a dead page is often
a capture of the 404. CDX takes `filter=statuscode:200`. The `id_`
flag in the snapshot URL returns the original bytes without the
Wayback toolbar, so the hash is the document's.

Open Library has no 200 captures of the pages cited: it is a
dynamic site that the Wayback Machine mostly records as redirects.

## 2026-10-26 — Merging index entries kept stale fields

`Index#upsert` merged each new fetch into the old entry. A fetch
that succeeded through Wayback kept the old `Net::OpenTimeout`
note, and fifteen bot-wall entries kept the hash and S3 key of the
robot page stored before bot-wall detection existed. Each entry is
one complete fetch, so it now replaces the old one. A record of what
was consulted is only as good as its least-recent field.

## 2026-10-26 — The process lived in the scratchpad

Asked whether the URLs found during research were being saved, the
answer was "the cited ones". The candidate index (449 October and
November entries), the 21 cached year pages, the selector, the
sources the landmark agent found, and every dead end existed only in
the session scratchpad under /private/tmp, which is cleared on
reboot. The proof-of-concept was shipping its output while losing
the process that made it. They now live in
`research/wikipedia-year-pages/` (extended to all twelve months:
2,770 candidates) and `research/sources.yaml` (hosts and how they
answer, documents worth reusing).

Lesson: a script that produced committed data is part of the
provenance. Commit it with the first data it produced.
