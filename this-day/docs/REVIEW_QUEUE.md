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

## January drafts

16. **10 drafts, one per uncovered day (2026-10-26).** Two Claude
    Opus 5.5 writers, one event per entry, from archived copies of the
    candidates' cited sources; the Wikipedia entry is the second
    reference. Review at `/this-day-in-vietnam-war/review/1`.
    *Decision:* approve, reject, or re-source by date.
    - **Thin:** Jan 7 (42 words; the Time cover page carries only the
      cover title and credit) and Jan 16 (50 words, Wikipedia only; the
      cited CMH page is an empty catalog page). The writer offers the
      1965 fight near Huế for Jan 7, from Wikipedia alone but long
      enough for a full body.
    - **Weak source:** Jan 23 (Nixon announces the Paris agreement)
      rests on The History Place timeline; the other candidates'
      sources were empty page shells.
    - **Jan 4** is transcribed from a scanned after-action report with
      no text layer (checked against the scan). The place name, Ban Me
      Thuot East Airfield, comes from Wikipedia; the report gives grid
      coordinates only. The report says Viet Cong; Wikipedia says PAVN.
    - **Sources disagreed with Wikipedia** (bodies follow the source):
      Jan 3, the amendment "was passed" (Hartsook), not "signed into
      law"; Jan 19, 12,200 was MACV's strength in mid-1965 before
      reduction to 1,500, not a reduction target; Jan 20, Abrams's
      message went to CINCPAC, not to Washington; Jan 21, Westmoreland
      launched Niagara, not "the USAF", and the source gives 20,000 to
      25,000 North Vietnamese against about 5,700 Marines and 500
      Rangers; Jan 25, the speech offers withdrawal of "all U.S. and
      allied forces" and the international supervision applies to the
      election.

## February drafts

17. **7 drafts, one per uncovered day (2026-10-26).** One Claude Opus
    5.5 writer, same process as January. Review at
    `/this-day-in-vietnam-war/review/2`.
    *Decision:* approve, reject, or re-source by date.
    - **Feb 29 is 30 words**, Wikipedia only; it was the day's only
      candidate.
    - **Wikipedia only:** Feb 14 (An Luu raid) and Feb 17 (Church's
      Senate speech). Birtle's *Advice and Support: The Middle Years*
      again archived as an empty catalog page. For Feb 17 the writer
      chose the Church speech over the Nui Lac San ridge fight in the
      same entry.
    - **Feb 3** rests on a 2002 Texas Tech symposium paper (Peoples),
      a secondary source.
    - **Sources disagreed with Wikipedia** (bodies follow the source):
      Feb 3, Diem "formally launched" the program and Nhu "commanded"
      it; Feb 8, Admiral Felt activated MACV on February 8 (Kennedy had
      approved the terms in early January) and McNamara, not Taylor,
      nominated Harkins (Cosmas); Feb 27, the 2 killed and 74 wounded
      were the total of five attacks on Bien Hoa that year, not this
      attack (Nalty).
    - **Feb 12:** the af.mil article contradicts itself (54 flights
      between February 12 and April 4 in a caption; flights "through
      late March" in the text). The body follows the caption, which
      agrees with Wikipedia.

## March drafts

18. **5 drafts, one per uncovered day (2026-10-26).** One Claude Opus
    5.5 writer. Review at `/this-day-in-vietnam-war/review/3`.
    *Decision:* approve, reject, or re-source by date.
    - **Mar 18** (1960 Washington conference) is Wikipedia only, at the
      80-word floor; the cited Spector history archived as an empty
      catalog page.
    - **Mar 27: Wikipedia's date is wrong for the battle it names.**
      Le Gro (*Vietnam from Ceasefire to Capitulation*) has the NVA
      attack on Duc Hue on 27 March 1974 and the ARVN sweep into Svay
      Rieng beginning 27 April. The entry is about the Duc Hue attack.
    - **Mar 29** (Duc Duc, 1971): the year is from the chapter context
      of the Marine history; the passage does not print it. The writer
      chose Duc Duc over the Calley verdict, whose source is an undated
      UPI audio transcript.
    - **Mar 7** (SILVER CITY): the source names no province (Wikipedia:
      Biên Hòa); "353 Viet Cong" in the source, not "PAVN/VC".
    - **Not used, reported:** the Aviation Safety Network record for the
      C-123 crash Wikipedia puts on March 4, 1968 gives 6 March, a
      Vietnam Air Force aircraft, and 49 dead (Wikipedia: USAF, 44).

## April drafts

19. **13 drafts, one per uncovered day (2026-10-26).** Two Claude
    Opus 5.5 writers. Review at `/this-day-in-vietnam-war/review/4`.
    *Decision:* approve, reject, or re-source by date.
    - **Thin:** Apr 9 (29 words; Pike's one-sentence chronology entry
      on the Phu Binh refugee center, the only usable source) and
      Apr 27 (56 words, Wikipedia only; the 25th Division artillery
      report Wikipedia cites has no 27 April action, so the citation
      does not support the entry).
    - **Apr 23:** the Time cover itself rests on Wikipedia; the Air
      Force biography supports the rest of the body but never mentions
      the cover.
    - **Apr 18:** the source says only "The first launch occurred on
      18 April" (Wolk, footnote); Wikipedia's "first successful",
      Fan Song target, and F-100F are not in it. The writer read the
      OCR "caruled" as "carried"; a word after "Fan Song fire control"
      is unreadable, so the body says "Fan Song targets".
    - **Sources disagreed with Wikipedia** (bodies follow the source):
      Apr 3, Ford "authorized" Babylift (Ford Library), not
      "announced"; Apr 7, Le Gro says "all nine" died in the narrative
      but "7 killed" in his own table, and names no PAVN shooter;
      Apr 12, 84 U.S. citizens evacuated (287 in all), not 82; Apr 17,
      the draft estimate said the war "at best will be protracted and
      costly"; Apr 22, Wheeler recommended a South Vietnamese attack on
      the Parrot's Beak, and U.S. troops were the choice of Bunker,
      Abrams and the Joint Chiefs; Apr 28, "territorial forces", not
      Regional Forces.
    - **Apr 29:** Tran contradicts himself on the task forces (325,
      318, 333 on p. 42; 318, 225, 333 on p. 54); the body follows the
      detailed account on p. 54.

## May drafts

20. **11 drafts, one per uncovered day, plus one for April 30
    (2026-10-26).** Two Claude Opus 5.5 writers. Review at
    `/this-day-in-vietnam-war/review/5` (and `/review/4` for April 30).
    *Decision:* approve, reject, or re-source by date.
    - **Moved to April 30.** The Cambodian border action Wikipedia lists
      on May 1, 1966 is dated 30 April in Carland (*Stemming the Tide*,
      p. 308), so it is filed under April 30, as Dec 20 was moved to
      Dec 19. May 1 is instead the 1964 Tam Bang attack, written by the
      main session from the Wikipedia entry alone (its cited Birtle
      page is empty).
    - **Thin:** May 22 (55 words) and May 31 (29 words), each one
      sentence in Pike's chronology. May 22 was read from the scan
      image because the OCR scrambled two columns; checked against the
      page.
    - **Wikipedia only:** May 1 and May 3 (the House M16 subcommittee;
      the second reference is a Google Books record used only for the
      report's title, date, and length).
    - **Sources disagreed with Wikipedia** (bodies follow the source):
      May 5, the operational report gives no U.S. death toll (Wikipedia:
      11), names A/1/77 at LZ Peanuts, and supports neither "5 km
      southwest of Khe Sanh" nor the 1/5 Cavalry companies; May 9, the
      crowd at the Lincoln Memorial "swelled to about 30" (Wikipedia:
      50); May 11, "Jefferson National Cemetery"; May 23, Futrell
      describes two MIGs downed near Kep and none of Wikipedia's power
      plant strikes or five MiGs; May 28, the League's members are
      relatives of many kinds, not "a group of wives"; May 30, claimed
      sightings of the abducted missionaries continued to 1970.

## June drafts

21. **11 drafts, one per uncovered day (2026-10-26).** Two Claude Opus
    5.5 writers. Review at `/this-day-in-vietnam-war/review/6`.
    *Decision:* approve, reject, or re-source by date.
    - **Thin:** June 12 (34 words, one Pike sentence) and June 24 (38
      words, Wikipedia only; no candidate cites a URL).
    - **Wikipedia only:** June 3 and June 4 (1965); every 1965 candidate
      cites the empty Birtle catalog page.
    - **June 22: Wikipedia misreports the source.** Wikipedia says
      North Vietnam "admitted that it had troops" in the South. The
      President's Daily Brief of 22 June 1968 reports that the Liberation
      Front's representative in Budapest, Dinh Ba Thi, said on 19 June
      that the Viet Cong received "all-around" assistance from "brothers
      in the North"; no admission about troops. The entry follows the
      brief. Transcribed from the scan (no text layer); checked against
      the page.
    - **June 20** was read from the page image of the MACV 1972–73
      chronology (OCR garbled); checked against the page. Wikipedia
      dates Abrams's appointment as Chief of Staff June 20; the
      chronology has June 21.
    - **June 1:** the scan's figures for enemy killed and U.S. killed
      are unreadable in the last digit, so the body leaves them out;
      the source says 10,724 "detained", not "captured".
    - **June 25:** Shulimson gives 23 Marines dead and 82 enemy bodies
      for June 25–28 (Wikipedia: 475 PAVN and 24 Marines, presumably
      for the whole operation).

## July drafts

22. **14 drafts, one per uncovered day, plus Nam Dong on July 7 and
    the Australian training team on August 3 (2026-10-26).** Two
    Claude Opus 5.5 writers, from the committed `docs/WRITER_BRIEF.md`.
    Review at `/this-day-in-vietnam-war/review/7` (and `/review/8`).
    *Decision:* approve, reject, or re-source by date.
    - **Moved by the source's date.** Nam Dong (Wikipedia: July 5,
      1964) is filed under July 7: Whitlow, *The Advisory and Combat
      Assistance Era*, p. 157, has the attack "shortly after midnight on
      7 July" (the VVAA calendar dates Conway's death 6 July). The
      Australian Army Training Team's arrival (Wikipedia: July 31, 1962)
      is filed under August 3, the Australian War Memorial's date.
    - **Thin:** Jul 5 (73 words), Jul 13 (45), Jul 14 (48, one Pike
      sentence), Jul 20 (60), Jul 26 (36), Jul 31 (48).
    - **Wikipedia only:** Jul 5, 10, 13, 20, 26, 31. The Jul 10 body
      keeps Wikipedia's "Varic Oriental River", which may be garbled.
    - **Weak source:** Jul 17 (Schlesinger's Cambodia testimony) rests
      on The History Place timeline.
    - **Sources disagreed with Wikipedia** (bodies follow the source):
      Jul 7, 55 South Vietnamese killed (Wikipedia: 57); Jul 9, the
      convoy was sent out as bait; Jul 14, a prison in Quang Nam
      province (Wikipedia: Hội An); Jul 16, the 7th Marines (Wikipedia:
      1st Marine Division); Jul 17, the Senate Armed Services Committee
      (Wikipedia: Congress); Jul 21, 209 "enemy" by body count, not VC;
      Jul 25, the Guam remarks never say "Nixon Doctrine"; Jul 29,
      Futrell describes two MIG-21s downed, not the other events in the
      entry.
    - **Dead source:** the dcbsoftware MACV 1966 chronology archive is
      now a spam page; every candidate citing it is unusable.

## August drafts

23. **16 drafts, one per uncovered day, plus August 3 from July
    (2026-10-26).** Two Claude Opus 5.5 writers. Review at
    `/this-day-in-vietnam-war/review/8`.
    *Decision:* approve, reject, or re-source by date.
    - **Thin:** Aug 8 (40 words), Aug 13 (44, one Pike sentence),
      Aug 14 (49), Aug 22 (76).
    - **Wikipedia only:** Aug 5, 8, 14, 16, 22, 23, 31. Aug 16 repairs
      Wikipedia's garbled "Twelve demonstrators issued subpoenas" as
      "had been issued subpoenas"; check the reading.
    - **Weak or uncertain sources:**
      - Aug 10 (first herbicide test, 1961) rests on a History Channel
        Australia classroom page. It also puts Dak To "in the Mekong
        Delta region", which the body leaves out.
      - Aug 15: FRUS does not date Sau Ha's arrest. Loan reported it
        on 18 August, so the August 15 date rests on Wikipedia.
      - Aug 1: Shulimson contradicts himself. His chronology has the
        Korean Marine advance echelon at Chu Lai on 1 August; his
        narrative has the "first echelons" arriving on 18 August.
    - **Sources disagreed with Wikipedia** (bodies follow the source):
      - Aug 17: the "enemy" sank the SS Green Bay with a "Viet Cong
        mine" (Wikipedia: VC sappers).
      - Aug 27: "terrorists" and a Revolutionary Development team
        (Wikipedia: VC, CORDS team), and "Ten die" with no mention of
        civilians.
      - Aug 29: the "more than 30" VC killed was the village chief's
        unconfirmed report, not later intelligence.
      - Aug 30: Fox's caption ("Two of the five 420,000 gallon fuel
        tanks destroyed") is quoted rather than turned into a count.

## September drafts

24. **18 drafts, one per uncovered day (2026-10-26).** Three Claude
    Opus 5.5 writers. Review at `/this-day-in-vietnam-war/review/9`.
    *Decision:* approve, reject, or re-source by date.
    - **Thin:** Sep 8 (43 words), Sep 19 (36), Sep 24 (23, one Pike
      sentence), Sep 27 (64).
    - **Wikipedia only:**
      - Sep 8: the FRUS document Wikipedia cites is an October telegram
        that does not mention the triumvirate.
      - Sep 19, 27, 28.
    - **Sep 23** (Kissinger takes office as Secretary of State): the
      State Department biography says nothing about Vietnam. Keep it?
      The biography also contradicts itself: "from September 23, 1973"
      in the text, "Entry on Duty: September 22" in its table.
    - **Sep 3** is transcribed from the scanned Camp Radcliff
      after-action report; checked against the scan. The report names
      no attacker (Wikipedia: VC).
    - **Sources disagreed with Wikipedia** (bodies follow the source):
      - Sep 9: Futrell calls DeBellevue "the Air Force's second ace of
        the war" and its leading MiG killer, not "the last" ace.
      - Sep 11: Wheeler's paper went to Clifford, not to Johnson.
      - Sep 13: Wikipedia's totals cover THAYER I, IRVING and THAYER
        II together.
      - Sep 16: "Over 100 enemy were killed" (Wikipedia: over 600 PAVN,
        70 ARVN).
      - Sep 22: the 26th Regiment of the B3 Front (Wikipedia: 320th
        Division), and the three tanks were destroyed two days later.
      - Sep 25: the Katum casualty line may cover August 18 to
        September 25, not the 25th alone.
      - Sep 29: the embassy was "dedicated" (Wikipedia: opened).

## Texas Tech letters and documents

14. **Letters from the Virtual Vietnam Archive (2026-10-26).** Letters
    home sit inside donor collections in the Texas Tech catalog
    (vva.vietnam.ttu.edu). Eleven records are saved with the tools to
    fetch more in `research/texas-tech-letters/` (README there). The
    catalog search is closed to scripts, so records come from known ids.
    *Decision (later, per operator):* which collections to read, and
    whether a dated letter can be a day's event.

15. **Pike, *Viet Cong Strategy of Terror*, can now be archived.** The
    PDF cited by Wikipedia (www.vietnam.ttu.edu/reports/...) never
    fetched; the same file downloads from the catalog host
    (vva.vietnam.ttu.edu/images.php?img=/images/231/2311404008a.pdf).
    It is the source behind Oct 20 and Nov 30 (item 11).
    *Decided 2026-10-26 (operator): yes.* Done. The scan is three
    files; the chronology Wikipedia cites (pp. 93–115) is in part c
    (pp. 90–125), not part a (to p. 51), so Oct 20 and Nov 30 now cite
    part c, pp. 96 and 102. Pike dates the Saigon grenade attack
    October 20, 1962, as Wikipedia does, so the October 26 date in the
    unattributed reprint (item 11) is not supported. Both entries stay
    short (26 and 20 words): the chronology gives one sentence per
    incident. Every Texas Tech report URL is now cited and archived at
    the catalog host (`lib/this_day/archive/mirrors.rb`), including the
    Jan 4 after-action report.

## Infrastructure

7. **Official-history hosts block automated fetches.**
   history.army.mil, marines.mil, and usmcu.edu return "Access
   Denied" to the archiver. The landmark re-sourcing agent is trying
   other hosts.
   *Decision:* none yet; noted because it limits which public-domain
   sources can carry an archived copy.
