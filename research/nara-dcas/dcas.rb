# frozen_string_literal: true

# Reader for the NARA DCAS Vietnam Conflict Extract Data File
# (NAID 2240992), file DCAS-vietnam.dat.
#
# The file is pipe-delimited ("|"), one record per LF-terminated line,
# 54 fields per record, no header row, no quoting. Field order follows
# the order in which the codebook (DCAS-codebook.pdf, 26 pages) lists
# the field names. Code tables below are transcribed from that
# codebook; page numbers are noted on each table. See README.md.
#
# Stdlib only.
#
#   require_relative "dcas"
#   DCAS.each_record { |r| puts r[:display_name] if r[:incident_month] == 10 }

require "date"

module DCAS
  DEFAULT_PATH = File.expand_path("DCAS-vietnam.dat", __dir__)
  DELIMITER = "|"

  # The 54 fields, in file order, named after the codebook headings
  # (codebook pp. 1-26, headings in bold).
  FIELDS = %i[
    member_component_code
    person_type_name_code
    person_type_name
    member_name
    member_service_code
    member_service_name
    member_rank_or_rate
    member_paygrade
    member_occupation_code
    member_occupation_name
    member_birthdate
    member_gender
    home_of_record_city
    home_of_record_county
    home_of_record_country_code
    home_of_record_state_code
    state_or_province_name
    marital_name
    religion_short_name
    religion_code
    race_name
    ethnic_short_name
    race_omb_name
    ethnic_group_name
    casualty_circumstances
    casualty_city
    casualty_state_or_province_code
    casualty_country_code
    region_name
    country_name
    member_unit
    duty_code
    process_date
    incident_or_death_date
    year_of_death
    war_or_conflict_code
    operation_incident_type_code
    operation_incident_name
    location_name
    closure_date
    aircraft_type
    hostile_or_non_hostile
    casualty_type_name
    casualty_category
    casualty_reason_name
    casualty_category_short_name
    remains_recovered
    casualty_closure_name
    vietnam_wall_row_and_panel
    incident_category
    incident_casualty_category_date
    incident_casualty_category_short_name
    incident_hostile_or_non_hostile
    incident_aircraft_type
  ].freeze

  FIELD_COUNT = FIELDS.size # 54

  # Codebook p. 1. The codebook gives the same F/A/C/M/N list for
  # MEMBER COMPONENT CODE as for MEMBER SERVICE CODE, but the component
  # column in the file holds R/Y/V/G/blank instead, so only the service
  # column is decoded with it.
  SERVICE = {
    "F" => "Air Force", "A" => "Army", "C" => "Coast Guard",
    "M" => "Marine Corps", "N" => "Navy"
  }.freeze

  # Codebook pp. 1-5, MEMBER RANK OR RATE.
  RANK = {
    "ADM" => "Admiral", "AN" => "Airman", "AMN" => "Airman",
    "AA" => "Airman Apprentice", "AB" => "Airman Basic",
    "A1C" => "Airman First Class", "AR" => "Airman Recruit",
    "A2C" => "Airman Second Class", "A3C" => "Airman Third Class",
    "BGEN" => "Brigadier General", "BG" => "Brigadier General",
    "CADET" => "Cadet", "CPT" => "Captain", "CAPT" => "Captain",
    "CMSGT" => "Chief Master Sergeant",
    "CMSAF" => "Chief Master Sergeant of the Air Force",
    "CPO" => "Chief Petty Officer",
    "CWO2" => "Chief Warrant Officer", "CWO3" => "Chief Warrant Officer",
    "CWO-4" => "Chief Warrant Officer", "CWO4" => "Chief Warrant Officer",
    "CWO-2" => "Chief Warrant Officer",
    "CW2" => "Chief Warrant Officer W-2", "CW3" => "Chief Warrant Officer W-3",
    "CW4" => "Chief Warrant Officer W-4", "CW5" => "Chief Warrant Officer W-5",
    "COL" => "Colonel", "CSM" => "Command Sergeant Major",
    "CDR" => "Commander", "COMO" => "Commodore",
    "CN" => "Constructionman", "CA" => "Constructionman Apprentice",
    "CR" => "Constructionman Recruit", "CPL" => "Corporal",
    "DN" => "Dentalman", "ENS" => "Ensign", "FN" => "Fireman",
    "FA" => "Fireman Apprentice", "FR" => "Fireman Recruit",
    "1STLT" => "First Lieutenant", "1LT" => "First Lieutenant",
    "1STSGT" => "First Sergeant", "1SG" => "First Sergeant",
    "GEN" => "General", "GYSGT" => "Gunnery Sergeant",
    "HN" => "Hospital Corpsman", "HA" => "Hospital Corpsman Apprentice",
    "HR" => "Hospital Recruit", "LCPL" => "Lance Corporal",
    "LT" => "Lieutenant", "LTC" => "Lieutenant Colonel",
    "LTCOL" => "Lieutenant Colonel", "LCDR" => "Lieutenant Commander",
    "LTG" => "Lieutenant General", "LTGEN" => "Lieutenant General",
    "LTJG" => "Lieutenant Junior Grade", "MAJ" => "Major",
    "MAJGEN" => "Major General", "MG" => "Major General",
    "MCPO" => "Master Chief Petty Officer",
    "MCPON" => "Master Chief Petty Officer of the Navy",
    "MGYSGT" => "Master Gunnery Sergeant", "MSG" => "Master Sergeant",
    "MSGT" => "Master Sergeant", "MIDSHP" => "Midshipman",
    "OOP" => "Officer Programs", "PO1" => "Petty Officer First Class",
    "PO2" => "Petty Officer Second Class", "PO3" => "Petty Officer Third Class",
    "PSG" => "Platoon Sergeant", "PV2" => "Private",
    "PV1" => "Private (no insignia)", "PFC" => "Private First Class",
    "PVT" => "Private, PV-2 (Army), PVT (Air Force, Marine Corps)",
    "RADM" => "Rear Admiral", "SN" => "Seaman", "SA" => "Seaman Apprentice",
    "SR" => "Seaman recruit", "2LT" => "Second Lieutenant",
    "2NDLT" => "Second Lieutenant", "SRA" => "Senior Airman",
    "SCPO" => "Senior Chief Petty Officer",
    "SMSGT" => "Senior Master Sergeant", "SGT" => "Sergeant",
    "SFC" => "Sergeant First Class", "SGM" => "Sergeant Major",
    "SGTMAJ" => "Sergeant Major",
    "SMOFMC" => "Sergeant Major of the Marine Corps",
    "SPC" => "Specialist", "SP4" => "Specialist 4", "SP5" => "Specialist 5",
    "SP6" => "Specialist 6", "SSG" => "Staff Sergeant",
    "SSGT" => "Staff Sergeant", "TSGT" => "Technical Sergeant",
    "VADM" => "Vice Admiral", "WO" => "Warrant Officer",
    "WO-1" => "Warrant Officer", "WO1" => "Warrant Officer"
  }.freeze

  # Codebook pp. 5-6, MEMBER PAYGRADE. The codebook decodes each grade
  # only to a coarse group.
  PAYGRADE_GROUP = {
    "C00" => "Officer",
    "E01" => "E1-E4", "E02" => "E1-E4", "E03" => "E1-E4", "E04" => "E1-E4",
    "E05" => "E5-E9", "E06" => "E5-E9", "E07" => "E5-E9", "E08" => "E5-E9",
    "E09" => "E5-E9",
    "O01" => "Officer", "O02" => "Officer", "O03" => "Officer",
    "O04" => "Officer", "O05" => "Officer", "O06" => "Officer",
    "O07" => "Officer", "O08" => "Officer", "O09" => "Officer",
    "O10" => "Officer", "O11" => "Officer",
    "W01" => "Officer", "W02" => "Officer", "W03" => "Officer",
    "W04" => "Officer", "W05" => "Officer"
  }.freeze

  # Codebook p. 6.
  GENDER = { "F" => "Female", "M" => "Male" }.freeze

  # Codebook pp. 6-7, HOME OF RECORD COUNTRY CODE.
  HOME_COUNTRY = {
    "AR" => "Argentina", "AM" => "Armenia", "AS" => "Australia",
    "BG" => "Bangladesh", "BL" => "Bolivia", "BR" => "Brazil",
    "VI" => "British Virgin Islands", "CA" => "Canada", "CO" => "Colombia",
    "CS" => "Costa Rica", "DA" => "Denmark", "DR" => "Dominican Republic",
    "EC" => "Ecuador", "EG" => "Egypt",
    "FM" => "Federated States Of Micronesia", "FR" => "France",
    "GM" => "Germany", "HA" => "Haiti", "EI" => "Ireland", "IT" => "Italy",
    "JM" => "Jamaica", "JA" => "Japan", "MX" => "Mexico", "WA" => "Namibia",
    "NL" => "Netherlands", "NZ" => "New Zealand", "NU" => "Nicaragua",
    "NI" => "Nigeria", "PK" => "Pakistan", "PS" => "Palau", "PM" => "Panama",
    "PE" => "Peru", "RP" => "Philippines", "PL" => "Poland",
    "KS" => "Republic of Korea", "RO" => "Romania", "4R" => "Ross Sea",
    "SP" => "Spain", "SZ" => "Switzerland", "BF" => "The Bahamas",
    "TD" => "Trinidad and Tobago", "UK" => "United Kingdom",
    "US" => "United States", "VM" => "Vietnam"
  }.freeze

  # Codebook pp. 7-9, HOME OF RECORD STATE CODE.
  HOME_STATE = {
    "AL" => "Alabama", "AK" => "Alaska", "AS" => "American Samoa",
    "AZ" => "Arizona", "AR" => "Arkansas", "CA" => "California",
    "CZ" => "Canal Zone", "CO" => "Colorado", "CT" => "Connecticut",
    "DE" => "Delaware", "DC" => "District of Columbia", "FL" => "Florida",
    "FR" => "Foreign", "GA" => "Georgia", "GU" => "Guam", "HI" => "Hawaii",
    "ID" => "Idaho", "IL" => "Illinois", "IN" => "Indiana", "IA" => "Iowa",
    "KS" => "Kansas", "KY" => "Kentucky", "LA" => "Louisiana",
    "ME" => "Maine", "MD" => "Maryland", "MA" => "Massachusetts",
    "MI" => "Michigan", "MN" => "Minnesota", "MS" => "Mississippi",
    "MO" => "Missouri", "MT" => "Montana", "NE" => "Nebraska",
    "NV" => "Nevada", "NB" => "New Brunswick", "NH" => "New Hampshire",
    "NJ" => "New Jersey", "NM" => "New Mexico", "NY" => "New York",
    "NC" => "North Carolina", "ND" => "North Dakota",
    "MP" => "Northern Mariana Islands", "OH" => "Ohio", "OK" => "Oklahoma",
    "ON" => "Ontario", "OR" => "Oregon", "PA" => "Pennsylvania",
    "PR" => "Puerto Rico", "RI" => "Rhode Island", "SC" => "South Carolina",
    "SD" => "South Dakota", "TN" => "Tennessee", "TX" => "Texas",
    "UT" => "Utah", "VT" => "Vermont", "VI" => "Virgin Islands",
    "VA" => "Virginia", "WA" => "Washington", "WV" => "West Virginia",
    "WI" => "Wisconsin", "WY" => "Wyoming"
  }.freeze

  # Codebook pp. 13-16, CASUALTY STATE OR PROVINCE CODE. In this file
  # the column holds only the four Vietnam military zones (or blank).
  CASUALTY_STATE = HOME_STATE.reject { |k, _| %w[CZ NB ON MP].include?(k) }.merge(
    "NS" => "Nova Scotia", "ST" => "Scotland", "UM" => "US Minor Outlying Areas",
    "M1" => "Vietnam Conflict Military Zone 1",
    "M2" => "Vietnam Conflict Military Zone 2",
    "M3" => "Vietnam Conflict Military Zone 3",
    "M4" => "Vietnam Conflict Military Zone 4"
  ).freeze

  # Codebook pp. 16-21, CASUALTY COUNTRY/OVER WATER CODE. Only the
  # entries relevant to Southeast Asia and the Western Pacific are
  # transcribed; the file uses six codes (VS, VN, LA, CB, TH, CH), and
  # the next-but-one column (COUNTRY/OVER WATER NAME) carries the text.
  CASUALTY_COUNTRY = {
    "BM" => "Burma", "CB" => "Cambodia", "CH" => "China",
    "98" => "Classified location", "3E" => "East China Sea",
    "3T" => "Gulf of Siam", "HK" => "Hong Kong", "JA" => "Japan",
    "KS" => "Republic of Korea", "LA" => "Laos", "MY" => "Malaysia",
    "3A" => "North Pacific Ocean", "VN" => "North Vietnam",
    "3P" => "Philippine Sea", "RP" => "Philippines", "3U" => "South China Sea",
    "4A" => "South Pacific Ocean", "VS" => "South Vietnam", "TH" => "Thailand",
    "US" => "United States", "XX" => "Unknown", "VM" => "Vietnam"
  }.freeze

  # Codebook p. 22.
  DUTY = { "C" => "Call", "N" => "Off", "Y" => "On", "Z" => "Unknown" }.freeze

  # Codebook p. 22.
  WAR = {
    "G" => "Gulf War", "K" => "Korean War", "P" => "Peacetime",
    "V" => "Vietnam Conflict", "T" => "War on Terrorism"
  }.freeze

  # Codebook p. 22.
  OPERATION_INCIDENT_TYPE = {
    "C" => "Combat", "E" => "Other Event", "O" => "Other Ops", "T" => "Terrorist"
  }.freeze

  # Codebook pp. 22-23 and p. 26.
  HOSTILE = { "H" => "Hostile Death", "NH" => "Non-Hostile Death" }.freeze

  # Codebook p. 25.
  REMAINS = { "N" => "Body Remains Not Recovered", "Y" => "Body Remains Recovered" }.freeze

  # Codebook p. 26, INCIDENT CASUALTY CAT. SHORT NAME. This is the
  # status the member held before death was recorded (MIA, POW, ...).
  INCIDENT_STATUS = {
    "MSG" => "Missing", "MIA" => "Missing in action", "POW" => "Prisoner of war",
    "TER" => "Terrorist", "WIA" => "Wounded in action"
  }.freeze

  # A trailing lone "V" is left alone: in this file it is far more
  # likely a middle initial than "the Fifth".
  NAME_SUFFIXES = { "JR" => "Jr.", "SR" => "Sr.", "II" => "II", "III" => "III", "IV" => "IV" }.freeze

  module_function

  # Yields one Hash per record. Raises MalformedRecord on a line that
  # does not split into exactly 54 fields unless skip_malformed is set,
  # in which case the line is passed to the on_malformed callable.
  def each_record(path = DEFAULT_PATH, skip_malformed: false, on_malformed: nil)
    return enum_for(:each_record, path, skip_malformed: skip_malformed, on_malformed: on_malformed) unless block_given?

    File.open(path, "r:ASCII-8BIT") do |io|
      io.each_line.with_index(1) do |line, lineno|
        values = line.chomp.split(DELIMITER, -1)
        if values.size != FIELD_COUNT
          raise MalformedRecord, "line #{lineno}: #{values.size} fields, expected #{FIELD_COUNT}" unless skip_malformed

          on_malformed&.call(lineno, line)
          next
        end
        yield decode(values.map { |v| v.force_encoding(Encoding::UTF_8).strip }, lineno)
      end
    end
  end

  def records(path = DEFAULT_PATH, **opts)
    each_record(path, **opts).to_a
  end

  class MalformedRecord < StandardError; end

  # Builds the record Hash: every raw field under its codebook name,
  # then decoded convenience keys. Decoded values are nil when the raw
  # code is blank or absent from the codebook tables.
  def decode(values, lineno = nil)
    raw = FIELDS.zip(values).to_h
    incident = parse_date(raw[:incident_or_death_date])
    status = raw[:incident_casualty_category_short_name]

    raw.merge(
      line_number: lineno,

      # Identity
      display_name: display_name(raw[:member_name]),
      service_code: raw[:member_service_code],
      service: SERVICE[raw[:member_service_code]],
      rank_code: raw[:member_rank_or_rate],
      rank: RANK[raw[:member_rank_or_rate]],
      paygrade_code: raw[:member_paygrade],
      paygrade_group: PAYGRADE_GROUP[raw[:member_paygrade]],
      occupation: blank_nil(raw[:member_occupation_name]),
      gender: GENDER[raw[:member_gender]],
      birth_date: parse_date(raw[:member_birthdate]),
      unit: blank_nil(raw[:member_unit]),

      # Home of record
      home_city: blank_nil(raw[:home_of_record_city]),
      home_county: blank_nil(raw[:home_of_record_county]),
      home_state_code: raw[:home_of_record_state_code],
      home_state: HOME_STATE[raw[:home_of_record_state_code]] || blank_nil(raw[:state_or_province_name]),
      home_country_code: raw[:home_of_record_country_code],
      home_country: HOME_COUNTRY[raw[:home_of_record_country_code]],

      # When
      incident_date: incident,
      incident_year: incident&.year,
      incident_month: incident&.month,
      incident_day: incident&.day,
      year: blank_nil(raw[:year_of_death])&.to_i,
      process_date: parse_date(raw[:process_date]),
      closure_date: parse_date(raw[:closure_date]),

      # Where
      province: blank_nil(raw[:casualty_city]),
      zone_code: raw[:casualty_state_or_province_code],
      zone: CASUALTY_STATE[raw[:casualty_state_or_province_code]],
      country_code: raw[:casualty_country_code],
      country: CASUALTY_COUNTRY[raw[:casualty_country_code]] || blank_nil(raw[:country_name]),

      # What
      war: WAR[raw[:war_or_conflict_code]],
      duty: DUTY[raw[:duty_code]],
      operation_incident_type: OPERATION_INCIDENT_TYPE[raw[:operation_incident_type_code]],
      hostile_code: raw[:hostile_or_non_hostile],
      hostile: HOSTILE[raw[:hostile_or_non_hostile]],
      hostile_death: raw[:hostile_or_non_hostile] == "H",
      casualty_type: blank_nil(raw[:casualty_type_name]),
      casualty_category_name: blank_nil(raw[:casualty_category]),
      casualty_reason: blank_nil(raw[:casualty_reason_name]),
      aircraft: blank_nil(raw[:aircraft_type]) || blank_nil(raw[:incident_aircraft_type]),

      # Remains
      remains_recovered_code: raw[:remains_recovered],
      remains: REMAINS[raw[:remains_recovered]],
      body_recovered: { "Y" => true, "N" => false }[raw[:remains_recovered]],
      closure: blank_nil(raw[:casualty_closure_name]),
      wall_panel: blank_nil(raw[:vietnam_wall_row_and_panel]),

      # Prior status (MIA / POW / WIA ...)
      incident_status_code: blank_nil(status),
      incident_status: INCIDENT_STATUS[status],
      incident_status_category: blank_nil(raw[:incident_category]),
      incident_status_date: parse_date(raw[:incident_casualty_category_date]),
      incident_hostile: HOSTILE[raw[:incident_hostile_or_non_hostile]]
    )
  end

  # "ACALOTTO ROBERT JOSEPH" -> "Robert Joseph Acalotto". Heuristic:
  # the first token is taken as the surname, so compound surnames
  # written with a space ("VAN DYKE ...") come out wrong. The raw
  # :member_name is authoritative.
  def display_name(raw)
    tokens = raw.to_s.split
    return nil if tokens.empty?

    surname = tokens.shift
    suffix = NAME_SUFFIXES[tokens.last] if tokens.size > 1
    tokens.pop if suffix
    name = (tokens + [surname]).map { |t| titleize(t) }.join(" ")
    suffix ? "#{name} #{suffix}" : name
  end

  def titleize(token)
    token.split(/([-'])/).map { |p| p.match?(/[A-Z]/) ? p.capitalize : p }.join
         .gsub(/\AMc([a-z])/) { "Mc#{Regexp.last_match(1).upcase}" }
  end

  def parse_date(str)
    return nil unless str.is_a?(String) && str.match?(/\A\d{8}\z/)

    Date.new(str[0, 4].to_i, str[4, 2].to_i, str[6, 2].to_i)
  rescue Date::Error
    nil
  end

  def blank_nil(str)
    str.nil? || str.empty? ? nil : str
  end
end
