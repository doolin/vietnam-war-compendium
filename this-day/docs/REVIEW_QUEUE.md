# Review queue — decisions for the operator

Questions raised by the rewrite and research agents that the sources
alone do not answer. Each item says what was found, what was done in
the meantime, and what decision is needed. Reply by item number.

Opened 2026-10-25.

## Medal of Honor

1. **Posthumous flag disagrees with the citation.** The army.mil
   pages mark posthumous awards with an asterisk; the parser reads
   that mark. Five citations say the recipient died but carry no
   asterisk: Leslie H. Sabo, Jr. and Ardie R. Copas (batch 8, titled
   posthumous by the agent), Hammett L. Bowen, Jr. and Leonard L.
   Alvarado (batch 7) and Felix M. Conde-Falcon (batch 6, titled
   without it). Gary M. Rose and Bruce P. Crandall carry the asterisk
   but neither citation text describes a death.
   *Interim:* at merge, titles follow the citation where it states
   the death plainly; Rose follows the asterisk.
   *Decision:* is the citation text or the asterisk authoritative?

2. **Multi-day actions dated on the last day.** The style guide says
   a multi-day action is dated on its first day. The parser took the
   date the army.mil page prints, which is sometimes the last:
   Modrzejewski (15–18 Jul 1966), Estocin (20 and 26 Apr 1967),
   Newlin (3–4 Jul 1967), Bennett (9–11 Feb 1969), Littrell (4–8 Apr
   1970), Rose (11–14 Sep 1970), Cavaiani (4–5 Jun 1971), Norris
   (10–13 Apr 1972). Bodies already say the action spanned the days.
   *Decision:* move these to the first day, or keep the printed date?

3. **No citation text.** Bruce P. Crandall, Gary George Wetzel, and
   Roy P. Benavidez have no citation the parser could read on the
   archived pages, so no body was written. Their old
   truncated events remain in place, unattributed.
   *Decision:* source these from the Army's individual recipient
   pages later, or drop them?

## NARA DCAS casualty events

4. **Lane loss date.** The DCAS record for MSG Glen Oliver Lane and
   SFC Robert Duval Owen gives the incident date as May 23, 1968. The
   existing event, sourced from the SOG site, dates the insertion to
   May 20. Both may be right (insertion versus date of loss).
   *Decision:* which date carries the event?

5. **Remains recovered.** The February 20, 1971 UH-1C event says no
   remains of the four crew have been recovered. DCAS lists WO Jon E.
   Reid and 1LT David M. May with remains recovered (closure
   2000-02-01). DCAS also spells the crew chief "Randolph Leroy
   Johnson", where the event has "Randall L. Johnson".
   *Interim:* none yet; the event still states the old claims.
   *Decision:* confirm the rewrite from the DCAS record.

## Kindle books

6. **Thin Dereliction of Duty events.** Fourteen rewritten events
   stay under 80 words because each rests on a one-sentence
   highlight. Examples: NSAM 273 (31 words), JCS memo of January 22,
   1964 (24), Mayflower pause (36).
   *Decision:* keep them thin, or re-read those passages in the book
   and add highlights?

## Landmark events

7. **Official-history hosts block automated fetches.**
   history.army.mil, marines.mil, and usmcu.edu return "Access
   Denied" to the archiver. The landmark re-sourcing agent is trying
   other hosts.
   *Decision:* none yet; noted because it limits which public-domain
   sources can carry an archived copy.
