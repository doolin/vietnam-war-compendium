---
marp: true
theme: default
paginate: true
size: 16:9
header: "This Day in Viet Nam — implementation"
footer: "vietnam-war-compendium / this-day"
style: |
  section { font-family: Georgia, "Times New Roman", serif; font-size: 26px; }
  h1, h2 { color: #3a3a3a; }
  h1 { border-bottom: 2px solid #8b7355; }
  code { font-size: 0.85em; }
  table { font-size: 0.8em; }
  section.lead { text-align: center; }
  section.lead h1 { border: none; font-size: 2em; }
---

<!-- _class: lead -->

# This Day in Viet Nam

## How a one-page daily history site is built, fed, and verified

Ruby · Roda · SQLite · AWS Lambda · CloudFront

---

# What it does

- One URL. One date. One event from the Indochina wars, 1940–1980.
- `GET /this-day-in-vietnam-war/10/25` → a page for October 25.
- The root URL serves today's date.
- Several events on a date? One is chosen at random per request.
- No date? A fallback page says so, with prev/next links.
- Self-contained HTML. No external CSS, JS, or fonts.

---

# Architecture in one picture

```
  YAML events ──► db/seed.rb ──► this_day.sqlite3
                                        │
                   zip (app + db + vendored gems)
                                        │
   browser ──► CloudFront ──► Lambda function URL ──► lamby ──► Roda
```

- The database is **built out of band** and shipped inside the zip.
- Lambda opens it read-only on cold start. No network calls to serve a page.
- CloudFront fronts the function URL for TLS, the custom domain, and caching.

---

# Why this shape (ADR-001)

| Concern | Choice | Reason |
|---|---|---|
| Runtime | Ruby on Lambda, zip package | Operator's language; near-zero idle cost |
| Framework | Roda + ERB | Small, routing-tree style, no magic |
| Data | SQLite file bundled with the zip | Read-only, no DB service, no cold-start fetch |
| Bridge | lamby | Rack → Lambda event translation |
| Edge | CloudFront | Custom domain, TLS, invalidation on deploy |

Trade-off accepted: every content change is a redeploy.

---

# The request path

```ruby
r.on "this-day-in-vietnam-war" do
  r.get String, String do |month, day|
    date = Date.new(Date.today.year, month.to_i, day.to_i)
    serve_date(date)
  end
end
```

1. Parse month/day; invalid dates fall to a 404 view.
2. `Database#event_for_date(month, day)` runs one indexed query.
3. `rows.sample` picks the event; a second query loads its references.
4. ERB renders `event.erb` or `fallback.erb` inside `layout.erb`.
5. The footer prints the build SHA from `version.json`.

---

# Data model

```sql
events     (id, month, day, year, title, body, photo_url, photo_alt)
references (id, event_id, position, label, url)
index idx_events_month_day on events(month, day)
```

- `body` is HTML paragraphs, authored in YAML.
- References are ordered, 1–3 per event by PRD.
- Year lives on the event, not the lookup key: the page heading takes
  its year from whichever event was chosen.

---

# Source files: YAML, one file per source

```yaml
- month: 3
  day: 8
  year: 1965
  title: "U.S. Marines land at Da Nang"
  body: "<p>On March 8, 1965, ...</p>"
  photo_url:
  photo_alt:
  references:
    - label: "U.S. Marines in Vietnam: The Landing and the Buildup, 1965"
      url: "https://www.usmcu.edu/..."
```

- `db/seed.rb` validates every event (fields, ranges 1940–1980,
  reference label+url) and aborts the build on any error.
- Files are named after their source: `medal-of-honor.yaml`,
  `dereliction-of-duty.yaml`, `nara-dcas-mia.yaml`.

---

# Build and deploy pipeline

```
rake db:build        YAML → validate → SQLite
rake deploy:build    copy app → Docker (SAM ruby3.3 image) bundle install
                     for x86_64-linux → write version.json → zip
rake deploy:push     aws s3 cp → lambda update-function-code → wait
rake deploy:invalidate   CloudFront invalidation on /this-day-in-vietnam*
rake deploy:all      all four
```

- Build dir is `/tmp/this-day-build` because Docker Desktop on macOS
  does not share the home directory by default.
- SAM's own build hangs on this machine; the direct Docker call does not.

---

# Where the content came from (first 352 events)

| Source | Events | How |
|---|---|---|
| army.mil Medal of Honor pages | 264 | Polite scraper + Nokogiri parser |
| Kindle highlights (4 books) | 62 | HTML export → YAML → `/process-highlights` |
| HistoryNet "Final Fiasco" | 12 | Hand-written from the article |
| "Landmark" events | 12 | Written from model memory |
| NARA DCAS casualty file | 2 | Database record + secondary page |

The scraper enforces one request at a time per domain with a delay,
caches raw HTML locally, and identifies itself in the User-Agent.

---

# The Kindle pipeline

```
Kindle notebook export (.html)
  └─ convert_html.rb ──► kindle-highlights/<book>.yaml
        └─ /process-highlights
              ├─ dates:  only when the text states one
              ├─ tags:   only what the text names
              ├─ quality: 1–5 (fragment … complete dated event)
              └─ events: quality-5 candidates → this-day/data/events/<book>.yaml
```

- The rule "add nothing beyond the highlight" stopped hallucination.
- It also produced bodies like *"RT New York was inserted in Target
  Area Tango-7."* True, sourced, and empty.

---

# What the audit found (Oct 2026)

- **Sound but truncated.** MOH bodies cut mid-sentence at 400 chars.
  Parser bug, not a model bug.
- **Honest but thin.** 62 Kindle events cite a Goodreads page. No
  page, no location. The highlight file *has* the location.
- **Hallucinated.** 24 events written from memory. Amazon product
  pages and plausible .gov URLs nobody fetched.
- **The model to copy.** The two DCAS events: primary record, named
  secondary source, detail in the body.

Common cause: nothing recorded what was actually consulted.

---

# Reference archive (this session)

A reference is not a URL. It is:

```yaml
- url: https://www.army.mil/medalofhonor/citations25.html
  sha256: 9f2c…
  bytes: 412903
  content_type: text/html
  title: "Medal of Honor Recipients - Vietnam War (A-L)"
  fetched_at: 2026-10-25T18:02:11Z
  s3_key: this-day/references/2a6f…/9f2c….html
  status: ok
```

- Fetched with the polite fetcher, cached locally, uploaded to the
  backups bucket, indexed in a committed YAML file.
- `rake refs:archive` fills the index. `rake refs:audit` reports
  every URL that failed or whose page title contradicts its label.

---

# First archive run: 32 URLs, 373 references

| Result | URLs | What it meant |
|---|---|---|
| 200, right title | 14 | army.mil, NARA catalog, HistoryNet, POW Network, SOG site |
| 200, wrong page | 15 | Amazon bot walls; one ISBN resolved to a 1741 slave-conspiracy book |
| 404 | 7 | "official" .gov/.mil links written from memory |
| 503 | 1 | Goodreads refuses polite fetchers |

Through Open Library, 4 of 14 cited ISBNs belonged to unrelated
books. A 200 with the wrong title is worse than a 404.

---

# Rewrite pass: every body from its archived source

| Tier | Events | Source text carried | Model |
|---|---|---|---|
| Medal of Honor | 264 | full citation (public domain) | Claude Fable 5.1, 8 parallel agents |
| Kindle books | 62 | the highlights consulted, with locations | Claude Fable 5.1, 2 agents |
| HistoryNet 1975 | 12 | the sentences relied on | Claude Fable 5.1 |
| Landmark | 12 | re-sourced from public-domain documents | pending |

Every rewritten event: opens "On <Month> <day>, <year>, ",
80–180 words, `summarized_by` and `summarized_at` set,
reference URL archived. Validator script enforces the opening,
the word count, and the key set before merge.

---

# Month provisioning (proof of concept)

Goal: at least one event for every day of October, then November.

1. List uncovered days from the YAML.
2. Draw candidates from fetchable, archivable sources.
3. Write each event with `status: draft` and a verbatim
   `source_text` excerpt the body was written from.
4. Archive every reference before the event is committed.
5. Deploy. Review on the phone at `/review/10`.
6. Approve or reject by date in chat; status flips in YAML.

---

# Review page

`/this-day-in-vietnam-war/review/10`

For each day of the month:

- every event's title, year, body
- the source excerpt it was written from
- each reference with archive status and fetch date
- draft / approved badge

Built for a phone screen: one column, no tables wider than the text.

---

# Lessons so far

- Audit before adding. Three model generations, three failure modes,
  one missing record.
- A citation standard is a tool, not a sentence in a README.
- Narrow allowlists stay narrow. Put recurring work behind rake tasks.
- Normalize line endings in the commit that touches the file.

*(grows through the session; see `docs/LESSONS.md`)*

---

# Agents in the loop

| Job | Model | Why that class |
|---|---|---|
| Rewrite a body from a citation | Fable 5.1 | Faithful compression; judgment on what to leave out |
| Find and verify a public-domain source | Opus 5.5 | Search, fetch, read, reject |
| Build a parser from a codebook PDF | Opus 5.5 | Read spec, test against known records |
| Merge, validate, deploy | main loop | Deterministic scripts |

- Each agent gets one brief: the committed style guide plus its inputs.
- A validator script checks every batch before merge: opening,
  word count, key set.
- Agents report flags, not prose. Flags go to `docs/REVIEW_QUEUE.md`.

---

# Two limits nobody planned for

- **Account session limit.** Thirteen agents at once stopped mid-task.
  Resume by message from the saved transcript; never restart.
- **Host rate limits.** Open Library: "Human Verification" after
  ~30 requests. history.army.mil, usmcu.edu: Akamai "Access Denied"
  to any non-browser client.
- The archiver now classifies a 200 robot page as `bot-wall`, not
  `ok`. Fourteen index entries were reclassified.

---

# Cross-checking sources against each other

The DCAS casualty file (58,220 records, pipe-delimited, 54 fields)
was parsed to check the two existing MIA events:

| Claim in event | DCAS record |
|---|---|
| ST Idaho lost May 20, 1968 | incident date May 23, 1968 |
| UH-1C crew: no remains recovered | Reid and May: remains recovered, 2000 |
| Crew chief "Randall L. Johnson" | "Johnson, Randolph Leroy" |

A second primary source turns a confident paragraph into three
review items.

---

<!-- _class: lead -->

# Status

| Deploy | SHA | What changed |
|---|---|---|
| 1 | 7579932 | Archive markers on every reference |
| 2 | ac89a06 | Month review page, status, credit fields |
| 3 | 2b1bd35 | 1975 and Dereliction bodies rewritten, credited |
