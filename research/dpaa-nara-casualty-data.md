# DPAA and NARA Casualty Data Sources

Research into publicly available Vietnam War MIA/POW and fatal casualty data.

## DPAA (Defense POW/MIA Accounting Agency)

- ~1,584 Vietnam War personnel still unaccounted-for
- No API, no bulk download; search is Salesforce-powered at dpaa.mil
- Fields: name, rank, branch, date of loss, country of loss, status
- **Access options**:
  1. FOIA request for structured data (legitimate, slow)
  2. Browser automation scraping (fragile, gray-area on .mil)
- FOIA-released data is public domain, no redistribution restrictions

## NARA DCAS Vietnam Conflict Extract Data File

- **NAID**: 2240992
- **Records**: 58,220 U.S. military fatal casualties (6/8/1956 – 5/28/2006)
- **Download**: National Archives Catalog or AAD (aad.archives.gov)
- **Formats**: Excel, DAT text, pipe-delimited/CSV
- **Fields**: name, rank, branch, occupation, demographics (birth date, gender, race, ethnicity), home location, marital status, religion, casualty category, death date, unit, incident details, aircraft type, body recovery status, Vietnam Wall row/panel
- **Casualty categories**: Killed in Action (40,934), Accident (9,107), Died of Wounds (5,299), Declared Dead (1,201), Illness (938), Self-Inflicted (382), Homicide (236), Presumed Dead/remains recovered (32), Presumed Dead/remains not recovered (91)
- **MIA limitation**: No MIA/POW category. "Declared Dead" and "Presumed Dead" entries may include former MIA reclassified, but original MIA status is not preserved. The ~1,584 still-unaccounted-for are NOT in this file.
- Public domain, no restrictions

## CACRAF (Combat Area Casualties Returned Alive File)

- Covers POWs/MIAs who returned alive
- Available via NARA AAD, some fields privacy-masked
- Separate from DCAS fatal casualty file

## Key URLs

- NARA catalog: https://catalog.archives.gov/id/2240992
- AAD search: https://aad.archives.gov/aad/fielded-search.jsp?dt=2513&tf=F
- FAQ (PDF): https://aad.archives.gov/aad/content/aad_docs/rg330_dcas_faq_vn.pdf
- Electronic records overview: https://www.archives.gov/research/military/vietnam-war/electronic-records.html
- Duke mirror: https://library.duke.edu/data/sources/dcas-casualties
- DCAS live system: https://dcas.dmdc.osd.mil/dcas/app/conflictCasualties/vietnam
