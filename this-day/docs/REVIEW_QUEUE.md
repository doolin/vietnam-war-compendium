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

8. **Re-sourcing changed four stories.** Each landmark event now
   cites a fetched public source (FRUS at history.state.gov, the
   American Presidency Project, a 1969 USMC history on Project
   Gutenberg, the National Archives, Texas Tech). The sources moved
   the New Hampshire primary from March 11 to March 12, 1968; credit
   the 37th ARVN Ranger Battalion, not the Marines, with repelling
   the March 1, 1968 attack at Khe Sanh; and do not support the
   206,000-troop figure in the March 10 New York Times story. The
   bodies now follow the sources.
   *Decision:* approve the rewritten landmark set, or flag any event.

9. **5th Special Forces Group departure.** The source gives March 3,
   1971 in a one-line timeline entry; unfetched search results put
   the colors ceremony at Fort Bragg on March 5.
   *Decision:* keep March 3 unless you know otherwise.

## October and November drafts

10. **38 drafts, one per uncovered day.** Written only from the
    Wikipedia year-page entry for that day, which is quoted in each
    draft's source excerpt, with the entry's own cited source as a
    second reference when it had a URL. Review on the phone at
    `/this-day-in-vietnam-war/review/10` and `/review/11`. Since
    2026-10-26 the day page serves only reviewed (approved) entries,
    chosen at random when a date has several; drafts appear only on
    the review pages.
    *Decision:* approve, reject, or re-source by date ("approve Oct
    3, 4; reject Nov 11").

11. **Thin or single-source drafts (re-sourced 2026-10-26).** Eleven
    drafts rested on a one- or two-sentence Wikipedia entry. A
    research agent (Claude Opus 5.5) rewrote eight from a fetched and
    archived source; Wikipedia stays as the second reference. The
    sources disagreed with Wikipedia on these points, and the bodies
    now follow the sources:
    - **Oct 8: year moved from 1962 to 1963.** Hoffman, *The Path to
      War* (USMC History Division, 2014), p. 76: HMM-361 relieved
      HMM-261 on 2 October 1963 and lost two UH-34Ds on 8 October.
      Wikipedia lists it under 1962. Hoffman says they "crashed almost
      simultaneously" and that Lt. Col. Ross concluded hostile fire
      brought them down; Wikipedia says "shot down".
      *Decision:* confirm 1963.
    - Oct 1: 20 killed and 36 seriously injured (Kiland, USNI
      *Proceedings*, 2012), against Wikipedia's 19 and 10.
    - Oct 13: Feinstein was the "third and final USAF ace" (Futrell,
      *Aces and Aerial Victories*), not the "fifth and last U.S. ace";
      the fight was near Kep airfield.
    - Oct 7: Nixon made five proposals (cease-fire in place, an
      Indochina Peace Conference, a withdrawal timetable, a political
      settlement, release of all prisoners), from the speech text.
    - Nov 6: "five hundred enemy casualties" per South Vietnamese
      intelligence, not 500 killed.
    - Nov 15: UPI gives crowds of "250 to 500,000"; Wikipedia says
      more than 500,000.
    - Nov 16: Farm Gate became operationally ready on the 16th; the
      last aircraft arrived a week later. The unit was Detachment 2A,
      4400th Combat Crew Training Squadron ("Jungle Jim").

    Three could not be re-sourced and remain thin:
    - **Oct 19 (1964).** The only source is Birtle, *Advice and
      Support: The Middle Years*; no fetchable copy was found.
    - **Oct 20 (1962).** Pike's *Viet Cong Strategy of Terror*
      (Texas Tech) does not archive. One unattributed reprint of 1962
      news text dates a grenade attack in Saigon (six dead, 38
      wounded) to **October 26, 1962**, so Wikipedia's October 20 may
      be wrong. Not used, because the site is not a reputable source.
    - **Nov 23 (1970).** FRUS 1969-76 vol. VII, doc. 76 (a November
      24 memo) confirms North Vietnam refused to attend the November
      25 session, but gives no announcement date and does not mention
      the PRG. The November 23 date is unsupported.
    *Decision:* reject these three, or keep them as drafts until a
    source is found. Rejecting one leaves its day empty again.

    November 30 is full length but cites the same Texas Tech PDF,
    which still fails to archive. November 11 repeats Wikipedia's "in
    reality" judgment about MACV's strength estimate.

## December drafts

12. **19 drafts, one per uncovered day (2026-10-26).** Written by
    three Claude Opus 5.5 writers from archived copies of each
    candidate's cited source, with the Wikipedia entry as the second
    reference. Review at `/this-day-in-vietnam-war/review/12`.
    *Decision:* approve, reject, or re-source by date.
    - **Wikipedia only** (no cited source had usable text): Dec 10,
      12, 13, 24, 25, 28. Six 1964 candidates cite Birtle's
      *Advice and Support: The Middle Years*, which has no fetchable
      copy.
    - **Dec 28 is 36 words**, under the 80-word floor; no candidate
      had more text.
    - **Dec 20 moved to Dec 19** (operator, 2026-10-26: a date can
      carry many entries, kept separate). Shulimson, *An Expanding
      War, 1966*, has 3/26 Marines setting up their CP on 19 December;
      the body was rewritten for that date from the same passages,
      dropping the writer's "in its second day" inference. December
      20 has no event again.
    - **Dec 22.** The conviction date rests on the Wikipedia entry;
      Weber (Tulsa Law Review) says only that the trial was "right
      before Christmas 1965".
    - **Sources disagreed with Wikipedia** (bodies follow the
      source): Dec 4, 137 injured (FRUS), not 175; Dec 5, 42 VC
      killed in all, a platoon of Company C; Dec 7, 668 enemy killed,
      not 670; Dec 9, every figure differs (Hoffman: 70 enemy killed,
      8 ARVN killed); Dec 16, nine CIDG killed, not ten; Dec 19, the
      first Army elements arrived at Vung Tau, not "deployed into
      combat"; Dec 26, 26 missing and one body recovered, not 29
      killed.
    - **Dec 7** is transcribed from a scanned after-action report
      with no text layer; `source_text` marks it as transcribed.

## One event per entry

13. **Seventeen combined drafts split into 39 entries (2026-10-26).**
    Operator's rule: a date can carry many entries, each its own
    event. Drafts that joined unrelated events with "The same day,
    ..." are split (Oct 4, 9, 11, 20, 24, 25, 26; Nov 2, 4, 11, 22,
    24, 27, 28, 30; Dec 10, 11). Each piece carries only its own
    source passages; the Wikipedia entry's cited source goes on the
    piece whose sentence it follows in the wikitext.
    - **28 of the 39 are under 80 words**, most resting on a single
      Wikipedia sentence (the Kennedy assassination entry is 19
      words). *Decision:* approve thin entries as they are, or hold
      them for re-sourcing.
    - **Oct 24:** the source does not say which "action" Taylor
      objected to, so the Taylor piece no longer ties it to the
      C-123 shootdown.
    - **Nov 2:** the release of aid funds to "the new Government" may
      read better rejoined to the coup entry.
    - **Nov 11:** a third event (the VC handing three POWs to Tom
      Hayden) was inside the Gallup paragraph; it is now its own
      entry.

## Infrastructure

7. **Official-history hosts block automated fetches.**
   history.army.mil, marines.mil, and usmcu.edu return "Access
   Denied" to the archiver. The landmark re-sourcing agent is trying
   other hosts.
   *Decision:* none yet; noted because it limits which public-domain
   sources can carry an archived copy.
