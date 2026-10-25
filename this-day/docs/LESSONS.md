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

## 2026-10-25 — Line endings on committed files

AGENTS.md was committed with CRLF. The repo's `.gitattributes`
normalizes new commits but does not rewrite history, so the first
edit through the file tools turned a one-line change into a
whole-file diff. Normalize once, in the same commit as the edit,
and say so in the message.
