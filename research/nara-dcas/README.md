# NARA DCAS Vietnam Conflict Extract: parser

Reader for the Defense Casualty Analysis System (DCAS) Vietnam Conflict
Extract Data File, National Archives NAID 2240992
(<https://catalog.archives.gov/id/2240992>). The "This Day in Viet Nam"
project uses it to find candidate events for a calendar day.

| File | What it is |
| --- | --- |
| `DCAS-vietnam.dat` | The extract (24 MB) |
| `DCAS-codebook.pdf` | The codebook (26 pages) |
| `dcas.rb` | Stdlib-only Ruby library: `DCAS.each_record` yields one Hash per record |
| `bin/dcas-day` | Command-line lookup by calendar day |

## Usage

```
ruby research/nara-dcas/bin/dcas-day 10 3          # every record with an incident on Oct 3, any year
ruby research/nara-dcas/bin/dcas-day 10 3 --json   # same records, full decoded hashes, as a JSON array
ruby research/nara-dcas/bin/dcas-day 10 --count    # per-day count table for October
ruby research/nara-dcas/bin/dcas-day 10 3 --file other.dat
```

The listing has one line per record, sorted by year and then name:

```
year | name | rank | service | unit | home of record | category / reason | recovered? | province, country [| prior status]
1971 | Robert Joseph Acalotto | SSG | Army | 1 AVN BDE | Greensburg, PA | DECLARED DEAD / HELICOPTER CRASH -- CREW (MC) | NOT recovered | Laos | MIA
```

The count table's columns are: total, hostile, non-hostile, records with
a prior status of MIA, POW, or MSG (missing), and records with remains
not recovered.

From Ruby:

```ruby
require_relative "research/nara-dcas/dcas"
DCAS.each_record { |r| p r.slice(:display_name, :incident_date, :casualty_category_name) }
```

## File layout

The codebook gives field names and code tables but no positions or
widths. I determined the layout from the data:

- The file is **pipe-delimited** (`|`). It is not fixed-width: line
  lengths vary (the first three lines are 398, 399, and 358 bytes).
- It has one record per line, LF line endings (no CR anywhere), and
  pure ASCII.
- It has no header row and no quoting, and no field contains a `|`.
- **Every one of the 58,220 lines splits into exactly 54 fields.** The
  last field is usually empty, so lines end in a run of pipes.
- The column order is the order in which the codebook lists its 54
  bold field headings, pp. 1-26. Every column was checked against its
  values. For example, column 5 holds only F/A/C/M/N (service, p. 1);
  column 27 holds only M1-M4 (military zones, p. 15); column 47 holds
  only Y/N (remains, p. 25); and column 52 holds only MIA/POW/MSG/WIA
  (p. 26).

| # | Codebook heading (page) | Key in `dcas.rb` | Notes |
| --- | --- | --- | --- |
| 1 | MEMBER COMPONENT CODE (1) | `member_component_code` | R/Y/V/G/blank; see "Not decoded" |
| 2 | PERSON TYPE NAME CODE (1) | `person_type_name_code` | Codebook: "No information available" |
| 3 | PERSON TYPE NAME (1) | `person_type_name` | ACTIVE - REGULAR, SELECTED SERVICE, ... |
| 4 | MEMBER NAME (1) | `member_name` | `SURNAME GIVEN MIDDLE [JR]` |
| 5 | MEMBER SERVICE CODE (1) | `member_service_code` -> `service` | |
| 6 | MEMBER SERVICE NAME (1) | `member_service_name` | |
| 7 | MEMBER RANK OR RATE (1-5) | `member_rank_or_rate` -> `rank` | Rank at death; see quirks |
| 8 | MEMBER PAYGRADE (5-6) | `member_paygrade` -> `paygrade_group` | |
| 9-10 | MEMBER OCCUPATION CODE / NAME (6) | `occupation` | MOS / rating |
| 11 | MEMBER BIRTHDATE (6) | `birth_date` | YYYYMMDD |
| 12 | MEMBER'S GENDER (6) | `gender` | |
| 13-14 | HOME OF RECORD CITY / COUNTY (6) | `home_city`, `home_county` | |
| 15 | HOME OF RECORD COUNTRY CODE (6-7) | `home_country` | |
| 16 | HOME OF RECORD STATE CODE (7-9) | `home_state_code` -> `home_state` | |
| 17 | STATE OR PROVINCE NAME (10) | `state_or_province_name` | Home state spelled out |
| 18 | MARITAL NAME (10) | `marital_name` | |
| 19-20 | RELIGION SHORT NAME / CODE (10-12) | `religion_short_name`, `religion_code` | The name column already spells out the code |
| 21-24 | RACE / ETHNIC fields (12-13) | as named | |
| 25 | CASUALTY CIRCUMSTANCES (13) | `casualty_circumstances` | Set in 40 records |
| 26 | CASUALTY CITY (13) | `province` | **Holds the province name** (KONTUM, QUANG TRI, OFFSHORE) |
| 27 | CASUALTY STATE OR PROVINCE CODE (13-16) | `zone_code` -> `zone` | M1-M4 military zone |
| 28 | CASUALTY COUNTRY/OVER WATER CODE (16-21) | `country_code` -> `country` | VS, VN, LA, CB, TH, CH |
| 29 | REGION NAME (21-22) | `region_name` | Always ASIA |
| 30 | COUNTRY/OVER WATER NAME (22) | `country_name` | |
| 31 | MEMBER UNIT (22) | `unit` | |
| 32 | DUTY CODE (22) | `duty` | |
| 33 | PROCESS DATE (22) | `process_date` | For declared-dead MIAs, the date of the death finding |
| 34 | INCIDENT OR DEATH DATE (22) | `incident_date` | **The date `dcas-day` matches on** |
| 35 | YEAR OF DEATH (22) | `year` | Always equals the year of column 34 |
| 36 | WAR OR CONFLICT CODE (22) | `war` | Always V |
| 37 | OPERATION INCIDENT TYPE CODE (22) | `operation_incident_type` | |
| 38-39 | OPERATION/INCIDENT NAME, LOCATION NAME (22) | as named | VIETNAM CONFLICT / SOUTHEAST ASIA |
| 40 | CLOSURE DATE (22) | `closure_date` | |
| 41 | AIRCRAFT TYPE (22) | `aircraft` | Set in 85 records |
| 42 | HOSTILE OR NON-HOSTILE DEATH INDICATOR (22-23) | `hostile`, `hostile_death` | |
| 43 | CASUALTY TYPE NAME (23) | `casualty_type` | Always DECEASED |
| 44 | CASUALTY CATEGORY (23) | `casualty_category_name` | KILLED IN ACTION, ACCIDENT, ... |
| 45 | CASUALTY REASON NAME (23-25) | `casualty_reason` | SMALL ARMS FIRE, DROWNING, ... |
| 46 | CASUALTY CAT. SHORT NAME (25) | | Always blank |
| 47 | REMAINS RECOVERED (25) | `remains`, `body_recovered` (true/false) | |
| 48 | CASUALTY CLOSURE NAME (25) | `closure` | |
| 49 | VIETNAM WALL ROW AND PANEL INDICATOR (25) | `wall_panel` | e.g. `05W 122` |
| 50 | INCIDENT CATEGORY (25-26) | `incident_status_category` | MISSING IN ACTION, CAPTURED, ... |
| 51 | INCIDENT CASUALTY CATEGORY DATE (26) | `incident_status_date` | |
| 52 | INCIDENT CASUALTY CAT. SHORT NAME (26) | `incident_status_code` -> `incident_status` | MIA / POW / MSG / WIA |
| 53 | INCIDENT HOSTILE OR INCIDENT NON-HOSTILE DEATH (26) | `incident_hostile` | |
| 54 | INCIDENT AIRCRAFT TYPE (26) | `incident_aircraft_type` | Set in 13 records |

## Decoding

Each record Hash holds two kinds of key:

- **Raw keys:** all 54 columns under the codebook-derived names in
  `DCAS::FIELDS`, stripped of surrounding whitespace.
- **Decoded keys:** for coded columns, the code is kept next to the
  decoded text (for example `service_code` and `service`, `rank_code`
  and `rank`, `incident_status_code` and `incident_status`). Dates are
  parsed into `Date`, with `incident_year`, `incident_month`, and
  `incident_day` derived from the incident date. `body_recovered` is
  true or false. `display_name` is "Given Middle Surname".

A decoded value is `nil` when the raw value is blank or is missing
from the codebook table. In this file the second case never happens:
every non-blank code in columns 5, 7, 8, 12, 15, 16, 27, 28, 32, 36,
37, 42, 47, and 52 is found in the transcribed tables.

The code tables come from these codebook pages:

- Service, p. 1
- Rank, pp. 1-5
- Paygrade, pp. 5-6
- Gender, p. 6
- Home country, pp. 6-7
- Home state, pp. 7-9
- Casualty state, province, and military zone, pp. 13-16
- Casualty country, pp. 16-21. Only the Southeast Asian and Pacific
  entries are transcribed, since the file uses six codes.
- Duty, war, operation type, and hostile, p. 22
- Remains, p. 25
- Incident status, p. 26

The name, category, reason, closure, marital, and religion columns
already hold their codebook text, so they are passed through.

## Counts

- **58,220 records.** This matches the figure in
  `research/dpaa-nara-casualty-data.md`.
- **Incident dates run from 1956-06-08 to 2006-05-28.** Every record
  has a valid YYYYMMDD incident date, so **no record lacks a usable
  date**. Every birth date is also valid.
- Hostile: 47,434. Non-hostile: 10,786.
- Categories:

  | Category | Records |
  | --- | --- |
  | Killed in action | 40,934 |
  | Accident | 9,107 |
  | Died of wounds | 5,299 |
  | Declared dead | 1,201 |
  | Illness | 938 |
  | Self-inflicted | 382 |
  | Homicide | 236 |
  | Presumed dead | 123 |

- Remains not recovered: 1,741, every one with closure NO REMAINS FOUND.
- Prior status (column 52):

  | Status | Records |
  | --- | --- |
  | WIA | 5,295 |
  | MIA | 1,085 |
  | MSG (missing) | 124 |
  | POW | 116 |

- Country of casualty:

  | Country | Records |
  | --- | --- |
  | South Vietnam | 55,661 |
  | North Vietnam | 1,120 |
  | Laos | 728 |
  | Cambodia | 523 |
  | Thailand | 178 |
  | China | 10 |

- Busiest years: 1968 (16,899), 1969 (11,780), and 1967 (11,363).

A full parse of the file takes about 1.5 s.

## Known quirks

- **No malformed rows.** All lines have 54 fields. `each_record` still
  raises `DCAS::MalformedRecord` on a short or long line, unless it is
  called with `skip_malformed: true`.
- **Column 34 is "incident OR death date".**
  - For declared-dead MIAs it is the **date of loss**. For example,
    Acalotto is 1971-02-20, while column 33 (process date) holds the
    death finding (1978-10-01).
  - For some died-of-wounds records it is the **date of death**. The
    seven records dated after 1975 (1987, 1990, 2004-2006) are all
    late deaths, most of them DIED OF WOUNDS. Their wound date is not
    in the file. For a "this day" event, check the category before
    calling column 34 the day something happened in Vietnam.
- **Rank is the rank at death.** For MIAs, that includes promotions
  made while missing. Acalotto is SSG here, but SP4 at loss.
- **Blank units: 17,090 records.** Most are Marine Corps: 13,283 of
  the 14,844 Marine records have no unit. Then Air Force 1,697,
  Navy 1,172, Army 938.
- **Blank province: 9,009 records.** Column 27 (the zone) is blank in
  9,161. No loss outside South Vietnam has a province: all records for
  North Vietnam, Laos, Cambodia, Thailand, and China have only the
  country. Within South Vietnam, 6,450 of 55,661 records have no
  province.
- **Blank home state: 117 records**, all with a foreign home of
  record. Most are Canada (56) and the Philippines (26). Their
  `home_country` is filled in.
- **Name order** is `SURNAME GIVEN MIDDLE [SUFFIX]`. `display_name`
  assumes a one-word surname, so compound surnames written with a
  space come out wrong. Use `member_name` for citation.
- **Remains column vs. narrative sources.** Column 47 records the
  current status. Crew lost together can differ: on the 1971-02-20
  Lam Son 719 helicopter, Reid and May have Y / REMAINS ACCEPTED, with
  a closure date of 2000-02-01, while Acalotto and Johnson have N.

## Not decoded

- **MEMBER COMPONENT CODE (column 1).** The codebook (p. 1) prints the
  same F/A/C/M/N list as for service. The file holds R, Y, V, G, or
  blank, which track column 3: R = ACTIVE - REGULAR (and the retired
  lists), Y = SELECTED SERVICE, V and G = ACTIVE - GUARD/RESERVE, and
  blank in 182 records. The codebook does not define these letters,
  so they are left raw. Column 3 carries the meaning.
- **PERSON TYPE NAME CODE (column 2)** and **MEMBER OCCUPATION CODE
  (column 9).** The codebook says "No information available" (pp. 1
  and 6). The matching name columns (3 and 10) spell them out.
- **CASUALTY CAT. SHORT NAME (column 46)** is blank in every record.
- **Paygrade.** The codebook decodes paygrade only to coarse groups
  (E1-E4, E5-E9, Officer). The finer grade is in the raw code (E06).

## Verification against `this-day/data/events/nara-dcas-mia.yaml`

**ACALOTTO ROBERT JOSEPH: matches on the date and the facts the event
relies on.**

| Field | Value in DCAS |
| --- | --- |
| Incident date | 1971-02-20 |
| Service and unit | Army, 1 AVN BDE |
| Home of record | Greensburg, Westmoreland County, PA |
| Country | Laos |
| Category | Hostile, DECLARED DEAD |
| Reason | HELICOPTER CRASH -- CREW (MC) |
| Remains | N, NO REMAINS FOUND |
| Prior status | MIA, dated 1971-02-20 |
| Declared dead | 1978-10-01 |
| Rank | SSG E06 |

The event's "SP4" is his rank at loss; DCAS records his rank at death.
The YAML's "Randall L. Johnson" appears in DCAS as JOHNSON RANDOLPH
LEROY, SFC.

**LANE GLEN OLIVER: the date is off by three days.**

| Field | Value in DCAS |
| --- | --- |
| Incident date | **1968-05-23** (the YAML says May 20) |
| Rank | MSG E08 |
| Service | Army |
| Occupation | 11F INFANTRY OPERATIONS AND INTELLIGENCE SPECIALIST |
| Unit | SPECIAL FORCES |
| Home of record | Odessa, TX |
| Country | Laos |
| Category | Hostile, DECLARED DEAD |
| Reason | UNKNOWN |
| Remains | N, NO REMAINS FOUND |
| Prior status | MIA, dated 1968-05-23 |
| Declared dead | 1974-06-01 (matches the YAML) |

OWEN ROBERT DUVAL (Chatham, VA, SFC, RADIO OPERATOR) has the same
1968-05-23 incident date and a 1973-11-01 death finding, which also
matches the YAML.
