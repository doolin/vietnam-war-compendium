# Summary style — This Day in Viet Nam

The brief for anyone, human or model, writing or rewriting an event
body. An event that breaks one of these rules is a draft, not an
event.

## Source discipline

1. **Write only from the archived source.** The body may contain no
   fact, name, number, place, or unit that does not appear in the
   source text attached to the event. Background from memory is
   forbidden, even when it is true.
2. **Carry the source excerpt.** `source_text` holds the verbatim
   passage the body was written from. For a public-domain document
   (a Medal of Honor citation, a government report) that is the full
   passage. For a copyrighted book it is the highlight or quotation
   actually consulted, with its location.
3. **Credit the summarizer.** `summarized_by` names the model or
   person that wrote the body, as the product name ("Claude Fable
   5.1"). `summarized_at` is the ISO 8601 timestamp. A body with no
   credit is a legacy body and is shown as "unattributed" until it is
   rewritten.
4. **Reference the archive, not a storefront.** Every reference URL
   must have an archived copy in `data/archive/index.yaml`. Amazon
   and Goodreads pages are not sources. A book is cited by author,
   title, publisher, year, and ISBN, with an open-catalog URL.

## Form

5. **Open with the date.** The first sentence begins "On <Month>
   <day>, <year>, ..." using the event's own month, day, and year.
   Spell the month; no ordinal suffix; no leading zero.
6. **Past tense, third person, no editorializing.** Report what the
   source says happened. No "heroically", "tragically", "iconic", no
   judgments about significance the source does not make.
7. **One to three short paragraphs** in `<p>` tags. Aim for 80 to
   180 words. The first paragraph is the event. A second paragraph
   may give outcome or consequence stated in the source. A third is
   rare.
8. **Plain words.** No bafflegab (see the operator's banned-words
   list: no "richer", "exactly", "honest", "cleanly", "spine",
   "load-bearing", "settles"). No manufactured antithesis ("not X but
   Y"), no self-labeled insight ("importantly", "the key point"), no
   argument from absence.
9. **Names and ranks as the source gives them.** Keep the source's
   rank, unit designation, and place spelling. Expand an abbreviation
   on first use only when the source itself expands it somewhere.
10. **Title**: short, active, specific. "Johnson rejects JCS bombing
    plan", not "Decision about bombing". For a Medal of Honor event:
    "<Rank> <Name> earns Medal of Honor", with " (posthumous)"
    appended when the award was posthumous.

## Medal of Honor citations in particular

- The citation is public domain and is the whole source. The body
  summarizes the action in the citation: what the unit was doing,
  what happened, what the recipient did, and the outcome the citation
  states (wounded, killed, position held, men evacuated).
- Do not reproduce the citation's formula ("conspicuous gallantry and
  intrepidity at the risk of his life above and beyond the call of
  duty") as the body. Say what he did.
- Where the citation covers more than one day, the event date is the
  first day, and the body says the action continued.
