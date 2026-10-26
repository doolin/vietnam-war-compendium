# Wikipedia year pages: candidate index

Candidate events for "This Day in Viet Nam", taken from the 21
Wikipedia pages "1955 in the Vietnam War" through "1975 in the Vietnam
War". These pages are chronologies with one entry per date, and most
entries cite a source. They serve as an **index of candidates, not as
a source**. A draft written from an entry quotes it, cites the
revision permalink, and carries the entry's own cited source when that
source has a URL.

| File | What it is |
| --- | --- |
| `cache/<page>.json` | The MediaWiki API `action=parse` response (wikitext and revision id) for each page, as fetched on 2026-10-25 |
| `extract.rb` | Fetches any page missing from `cache/` and writes `candidates.json` and `report.json` |
| `candidates.json` | 2,770 entries with a day-level date, sorted by month, day, and year |
| `report.json` | Revision id and per-month counts for each page, plus 20 labels that give no day |
| `select.rb` | For one month, lists the days with no served event and the top four candidates for each |

## Usage

```
ruby research/wikipedia-year-pages/extract.rb                  # rebuild candidates.json from cache/
ruby research/wikipedia-year-pages/select.rb 12 /tmp/dec.json  # uncovered December days, ranked candidates
```

`extract.rb` makes no requests when every page is in `cache/`. To pick
up a newer revision of a page, delete its cache file; the script then
fetches it through the API, waiting two seconds between requests.

## A candidate

```json
{
  "year": 1962, "month": 10, "day": 1, "day_label": "1 October",
  "text": "Taylor was named by Kennedy to be Chairman of the Joint Chiefs of Staff.",
  "refs": [],
  "page": "1962_in_the_Vietnam_War", "revid": 1374503779,
  "permalink": "https://en.wikipedia.org/w/index.php?title=1962_in_the_Vietnam_War&oldid=1374503779"
}
```

`text` is the entry rendered to plain text. `refs` holds the entry's
`<ref>` citations. Named references are resolved to their first
definition, and `{{cite ...}}` fields (title, author, url, date, page)
are pulled out.

## Counts (revisions cached 2026-10-25)

- 2,770 candidates. 1,242 have at least one cited URL, and 56 have no
  citation at all.
- Every day of the year has at least one candidate. The fewest are in
  September (204 entries) and the most in April (272).
- Coverage is uneven by year. 1964 through 1972 account for most
  entries, while 1955 through 1960 and 1973 through 1974 have only a
  few per month.

## How October and November 2026 were provisioned

1. `select.rb 10` listed 23 uncovered October days, each with four
   ranked candidates.
2. A writer agent (Claude Fable 5.1) picked one candidate per day and
   wrote a body from the entry text only. It kept the entry verbatim
   as `source_text` and cited the permalink, plus the entry's own
   source where that source had a URL.
3. Each result went into `this-day/data/events/drafts-october-wikipedia.yaml`
   with `status: draft`. `rake refs:archive` then archived every new URL.
4. November followed the same steps (15 days).

The style rules are in `this-day/docs/SUMMARY_STYLE.md`. Drafts stay
drafts until the operator approves them on the month review page.

## Licence

Wikipedia text is CC BY-SA 4.0. Every candidate and every draft built
from one carries the revision permalink, which provides the attribution.
