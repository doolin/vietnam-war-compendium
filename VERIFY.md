# Manual Verification Checklist

Human review tasks that cannot be automated. Check the box and note findings when done.

## MOH Citation Processing

### Date accuracy
- [ ] Spot-check 10 random MOH events against source citations on army.mil
- [ ] Verify COOK (date range "31 December 1964 to 8 December, 1967") — parser returns 1967-12-08 (second date). Confirm which date is correct for the event
- [ ] Verify McCLOUGHAN (year-range "1969-1970", date from citation "May 13-15, 1969") — confirm May 13 is the right start date
- [ ] Verify ASHLEY (ordinal range "6th and 7th February 1968") — confirm Feb 6 is correct
- [ ] Verify CREEK (period typo "13 February. 1969") — confirm date is accurate despite source typo

### Name formatting
- [ ] Review all 25 suffix names (Jr., III) in generated events for correctness
- [ ] Check PITSENBARGER (no comma in source: "PITSENBARGER WILLIAM H.") — verify name renders correctly
- [ ] Check DE LA GARZA — multi-word name capitalization

### Rank extraction (new-format entries)
- [ ] Verify INGRAM — no rank extracted, confirm what rank should be
- [ ] Verify PITSENBARGER — no rank extracted, confirm what rank should be
- [ ] Spot-check 5 new-format entries where rank was extracted from citation text

### Citation summaries
- [ ] Read 10 event bodies and confirm they are coherent (summarize truncation didn't cut mid-thought)
- [ ] Check events where citation was nil (BENAVIDEZ, CRANDALL, WETZEL) — confirm body text is acceptable

### Source URLs
- [ ] Confirm A-L/M-Z URL assignment is correct (recipients in A-L file get citations25 URL, M-Z get citations26)
