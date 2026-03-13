# Process Kindle Highlights

You are processing Kindle highlights from a Vietnam War book to extract dates, tags, and identify event candidates for "This Day in Viet Nam."

## Input format

Highlights live in `kindle-highlights/<book-slug>.yaml` with this structure:

```yaml
---
book:
  title: 'Book Title'
  authors: Last, First
  asin: ''
  citation: ''
  url: https://www.goodreads.com/book/show/BOOK_ID
  source_file: <book-slug>.html
highlights:
- id: 1
  type: highlight
  section: 'Chapter or section title'
  page: 10
  location: 107
  color: yellow
  text: The highlighted passage text...
  kindle_url: ''
  note: ''
  context: ''
  tags: []
  cross_refs: []
  dates: []
  quality: null
```

## What to do

Process the entire highlight file in one pass. For each highlight:

### 1. Extract dates

Fill in the `dates` field ONLY when the highlight text explicitly states a date. Use ISO 8601 format: `YYYY-MM-DD`, `YYYY-MM`, or `YYYY`. The `section` field (chapter/section title) in the highlight record is valid source data for resolving the year when the text states a month/day but not a year. Do NOT infer dates from general knowledge or external sources. If no date appears in the text, leave `dates: []`.

### 2. Extract tags

Fill in the `tags` field with terms that appear in or are directly described by the highlight text. Use lowercase kebab-case. Examples: `nsc`, `jcs`, `mcnamara`, `rolling-thunder`, `tonkin-gulf`. Only tag what the text actually mentions — do not add interpretive or thematic tags.

### 3. Score quality

Assign a `quality` score (1-5) to each highlight indicating completeness and usefulness:

- **5**: Complete sentence(s), explicit date, clear event described, strong event candidate
- **4**: Complete sentence(s), has date or strong tags, useful as-is
- **3**: Readable and meaningful but missing date or is analytical/background rather than event
- **2**: Fragment, mid-sentence clip, or truncated — meaning is unclear without surrounding text
- **1**: Orphan fragment (e.g., "fighting.", "deterrent impact and their menace.") — needs original text to be useful

Add or update the `quality` field on each highlight. This allows filtering to find highlights that need human attention.

### 4. Identify event candidates

A highlight is an event candidate when it:
- Contains an explicit date in the text
- Describes a specific occurrence (not analysis, opinion, or background)

### 5. Create events from candidates

Events cover the date range 1940-1980 (all three Indochina wars). Event scale ranges from the highest level strategic events (e.g., Nixon flying to China) to the smallest, most intimate (e.g., a single named soldier wounded in a firefight). Do not filter by perceived importance. Any concentration of dates reflects the current state of research, not a problem to solve.

For event candidates, create entries in `this-day/data/events/` following this format:

```yaml
- month: 3
  day: 2
  year: 1965
  title: "Short descriptive title"
  body: "<p>Paragraph closely paraphrasing the highlight text. Past tense.</p>"
  photo_url:
  photo_alt:
  references:
    - label: "Source Book Title by Author"
      url: "https://www.goodreads.com/book/show/BOOK_ID"
```

Event writing guidelines:
- **Title**: Short, active, specific. "Johnson rejects JCS bombing plan" not "Decision about bombing".
- **Body**: Must be grounded in what the highlight text actually says. Do not add facts, claims, or context from outside the source text. Past tense, no editorializing. The body text MUST include the full date (e.g., "On March 2, 1965, ..."). When leading with the date would be awkward, work it naturally into the text elsewhere.
- **References**: ONLY the source book. Do NOT fabricate corroborating sources or URLs. The user will add additional references themselves. For the `url` field, use the `url` from the highlight file's `book:` metadata. If no `url` is present, look up the book on Goodreads; do not guess or fabricate a URL.
- **File placement**: Create a new file named after the source book (e.g., `dereliction-of-duty.yaml`). Keep events sorted by date within each file.

## Do NOT do the following

- Do NOT fill in `context` or `cross_refs` fields.
- Do NOT invent or guess dates. If the highlight text doesn't contain an explicit date, it gets `dates: []`.
- Do NOT fabricate references, URLs, or corroborating sources.
- Do NOT add information to event bodies beyond what is in the highlight text.

## Workflow

1. Read the user's specified highlight file (or ask which one).
2. Process the entire file: extract dates, extract tags, score quality, identify event candidates, and write all updates.
3. After processing, present a summary: how many highlights got dates, tags, events created, and quality distribution (count per score).
4. Flag highlights scoring 1-2 that the user may want to revisit with the original text. Also flag any that hint at a date but don't state one explicitly.

## Important notes

- Most highlights will have NO dates and produce NO events. That's expected and correct.
- Preserve the existing YAML structure exactly. Do not reformat or reorder fields.
- Do not touch fields you are not updating.
- Run `perl -pi -e 's/\r\n/\n/g'` on any files you write to ensure Unix line endings.
