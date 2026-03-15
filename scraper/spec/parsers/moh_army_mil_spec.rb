# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  enable_coverage :branch
  command_name "moh_parser"
  root File.expand_path("../..", __dir__)
end

require "rspec"
require_relative "../../parsers/moh_army_mil"

RSpec.describe MohArmyMilParser do
  subject(:parser) { described_class.new }

  def build_html(*entries)
    body = entries.map { |e| "<h3>#{e[:heading]}</h3><p>#{e[:text]}</p>" }.join
    "<html><body>#{body}</body></html>"
  end

  # ---------------------------------------------------------------------------
  # parse_index
  # ---------------------------------------------------------------------------
  describe "#parse_index" do
    context "basic field extraction" do
      # Real example: DONLON — standard format with all structured fields
      it "extracts name, rank, organization, place, date, and citation" do
        html = build_html(
          heading: "DONLON, ROGER HUGH C.",
          text: "Rank and organization: Captain, U.S. Army. Place and date: " \
                "Near Nam Dong, Republic of Vietnam, 6 July 1964. " \
                "Entered service at: Fort Benning, Ga. Born: 30 January 1934. " \
                "Citation: For conspicuous gallantry and intrepidity."
        )

        r = parser.parse_index(html).first
        expect(r[:name]).to eq("DONLON, ROGER HUGH C.")
        expect(r[:rank]).to eq("Captain")
        expect(r[:organization]).to eq("U.S. Army")
        expect(r[:place]).to eq("Near Nam Dong, Republic of Vietnam")
        expect(r[:date]).to eq(Date.new(1964, 7, 6))
        expect(r[:citation]).to include("conspicuous gallantry")
        expect(r[:posthumous]).to be false
      end

      it "marks posthumous recipients (asterisk prefix)" do
        html = build_html(
          heading: "* ANDERSON, JAMES, JR.",
          text: "Rank and organization: Private First Class, U.S. Marine Corps. " \
                "Place and date: Republic of Vietnam, 28 February 1967. " \
                "Entered service at: Los Angeles, Calif. " \
                "Citation: For conspicuous gallantry."
        )
        r = parser.parse_index(html).first
        expect(r[:posthumous]).to be true
        expect(r[:name]).to eq("ANDERSON, JAMES, JR.")
      end

      it "marks non-posthumous recipients (no asterisk)" do
        html = build_html(
          heading: "ADAMS, WILLIAM E.",
          text: "Rank and organization: Major, U.S. Army. Place and date: " \
                "Kontum Province, Republic of Vietnam, 25 May 1971. " \
                "Entered service at: Kansas City. Citation: For gallantry."
        )
        r = parser.parse_index(html).first
        expect(r[:posthumous]).to be false
      end
    end

    context "skipping non-recipient entries" do
      it "skips entries with 'Additional Medal of Honor' in heading" do
        html = build_html(
          { heading: "SMITH, JOHN", text: "Rank and organization: Private, U.S. Army. Place and date: Vietnam, 1 March 1968. Entered service at: X. Citation: Test." },
          { heading: "Additional Medal of Honor Resources", text: "Links and resources." }
        )
        expect(parser.parse_index(html).size).to eq(1)
      end

      it "skips entries with 'Additional Medal of Honor' in body text" do
        html = build_html(
          heading: "RESOURCES",
          text: "Additional Medal of Honor Resources and links."
        )
        expect(parser.parse_index(html)).to be_empty
      end

      it "skips entries with empty body text" do
        html = "<html><body><h3>EMPTY, TEST</h3><h3>NEXT, ONE</h3><p>Rank and organization: Private, U.S. Army. Place and date: Vietnam, 1 March 1968. Entered service at: X. Citation: Test.</p></body></html>"
        results = parser.parse_index(html)
        expect(results.size).to eq(1)
        expect(results.first[:name]).to eq("NEXT, ONE")
      end
    end

    # -------------------------------------------------------------------------
    # Rank and organization extraction
    # -------------------------------------------------------------------------
    context "rank and organization extraction" do
      # Real pattern: 241 entries like ADAMS — "Captain, U.S. Army, 1st Battalion"
      it "splits rank and organization on first comma" do
        html = build_html(
          heading: "ADAMS, WILLIAM E.",
          text: "Rank and organization: Major, U.S. Army, A/227th Assault Helicopter Company. " \
                "Place and date: Kontum Province, 25 May 1971. " \
                "Entered service at: Kansas City. Citation: For gallantry."
        )
        r = parser.parse_index(html).first
        expect(r[:rank]).to eq("Major")
        expect(r[:organization]).to eq("U.S. Army, A/227th Assault Helicopter Company")
      end

      # Edge case: rank without comma (no organization split)
      # Real example: 21 new-format entries use extract_rank_from_citation instead,
      # but this tests the branch where Rank and organization has no comma
      it "assigns rank only when no comma separates rank and organization" do
        html = build_html(
          heading: "SOLO, RANK",
          text: "Rank and organization: Private. " \
                "Place and date: Vietnam, 1 March 1968. " \
                "Entered service at: X. Citation: For gallantry."
        )
        r = parser.parse_index(html).first
        expect(r[:rank]).to eq("Private")
        expect(r[:organization]).to be_nil
      end

      # Real example: ALVARADO — new-format, no "Rank and organization:" field
      # Rank extracted from citation text via extract_rank_from_citation
      it "extracts rank from citation text for new-format entries" do
        html = build_html(
          heading: "ALVARADO, LEONARD L.",
          text: "For conspicuous gallantry and intrepidity at the risk of his life. " \
                "Specialist Four Leonard L. Alvarado distinguished himself on August 12, 1969."
        )
        r = parser.parse_index(html).first
        expect(r[:rank]).to eq("Specialist Four")
        expect(r[:organization]).to be_nil
      end

      # Real examples: INGRAM, PITSENBARGER — new-format with no matching rank
      it "leaves rank nil when no rank pattern matches in citation" do
        html = build_html(
          heading: "WETZEL, GARY GEORGE",
          text: "The President of the United States of America awards the Medal of Honor " \
                "to Gary George Wetzel for service on 8 January 1968."
        )
        r = parser.parse_index(html).first
        expect(r[:rank]).to be_nil
      end
    end

    # -------------------------------------------------------------------------
    # Place and date extraction (extract_place_and_date)
    # -------------------------------------------------------------------------
    context "Place and date field: delimiter variants" do
      # Real: 242 entries use "Place and date:"
      it "handles standard colon delimiter (Place and date:)" do
        html = build_html(
          heading: "ADAMS, WILLIAM E.",
          text: "Rank and organization: Major, U.S. Army. Place and date: " \
                "Kontum Province, Republic of Vietnam, 25 May 1971. " \
                "Entered service at: Kansas City. Citation: For gallantry."
        )
        r = parser.parse_index(html).first
        expect(r[:date]).to eq(Date.new(1971, 5, 25))
        expect(r[:place]).to eq("Kontum Province, Republic of Vietnam")
      end

      # Real: DICKEY — "Place and dale:" typo on army.mil
      it "handles 'dale' typo (Place and dale:)" do
        html = build_html(
          heading: "DICKEY, DOUGLAS E.",
          text: "Rank and organization: Private First Class, U.S. Marine Corps. " \
                "Place and dale: Republic of Vietnam, 26 March 1967. " \
                "Entered service at: Cincinnati, Ohio. Citation: For gallantry."
        )
        r = parser.parse_index(html).first
        expect(r[:date]).to eq(Date.new(1967, 3, 26))
      end

      # Real: DOLBY — "Place and date." (period instead of colon)
      it "handles period delimiter (Place and date.)" do
        html = build_html(
          heading: "DOLBY, DAVID CHARLES",
          text: "Rank and organization. Sergeant, U.S. Army. " \
                "Place and date. Republic of Vietnam, 21 May 1966. " \
                "Entered service at: Philadelphia. G.O. No.: 45. " \
                "Citation: For gallantry."
        )
        r = parser.parse_index(html).first
        expect(r[:date]).to eq(Date.new(1966, 5, 21))
      end
    end

    context "Place and date field: date format variants" do
      # Real: 238 entries like ADAMS — "DD Month YYYY" (day-first)
      it "parses day-first date (25 May 1971)" do
        html = build_html(
          heading: "ADAMS, WILLIAM E.",
          text: "Rank and organization: Major, U.S. Army. Place and date: " \
                "Kontum Province, Republic of Vietnam, 25 May 1971. " \
                "Entered service at: Kansas City. Citation: For gallantry."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1971, 5, 25))
      end

      # Real: SABO — "Month DD, YYYY" (month-first, American style)
      it "parses month-first date (May 10, 1970)" do
        html = build_html(
          heading: "SABO, LESLIE H., JR.",
          text: "Rank and organization: Specialist Four, U.S. Army. " \
                "Place and date: Se San, Cambodia, May 10, 1970. " \
                "Entered service at: Ellwood City, Pa. Citation: For gallantry."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1970, 5, 10))
      end

      # Real: CREEK — "13 February. 1969" (period instead of space before year)
      it "parses date with period before year (13 February. 1969)" do
        html = build_html(
          heading: "CREEK, THOMAS E.",
          text: "Rank and organization: Corporal, U.S. Army. " \
                "Place and date: Near Cam Lo, Republic of Vietnam, 13 February. 1969. " \
                "Entered service at: Amarillo, Texas. Born 7 April 1950. " \
                "Citation:: For gallantry."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1969, 2, 13))
      end

      # Real: ASHLEY — "6th and 7th February 1968" (ordinal range)
      it "parses ordinal date range, uses first date (6th and 7th February 1968)" do
        html = build_html(
          heading: "ASHLEY, EUGENE, JR.",
          text: "Rank and organization: Sergeant, U.S. Army. " \
                "Place and date: Near Lang Vei, Republic of Vietnam, 6th and 7th February 1968. " \
                "Entered service at: New York. Citation: For gallantry."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1968, 2, 6))
      end

      # Real: COOK — "31 December 1964 to 8 December, 1967" (date range)
      # The "Month DD, YYYY" pattern matches "8 December, 1967" at end of string
      # before the "to" branch is tried, so this returns the second date.
      it "parses date range with 'to' (31 December 1964 to 8 December, 1967)" do
        html = build_html(
          heading: "COOK, DONALD GILBERT",
          text: "Rank and organization: Colonel, U.S. Marine Corps. " \
                "Place and date: Vietnam, 31 December 1964 to 8 December, 1967. " \
                "Entered Service at: Brooklyn, New York. Citation: For gallantry."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1967, 12, 8))
      end

      # Test the "to" branch specifically: only fires when text after "to" is NOT
      # a parseable date at end of string (otherwise the first DD Month YYYY$ branch wins)
      it "hits the 'to' branch when text after 'to' is not a trailing date" do
        html = build_html(
          heading: "RANGE, TEST",
          text: "Rank and organization: Captain, U.S. Army. " \
                "Place and date: Vietnam, 31 December 1964 to his release. " \
                "Entered Service at: Brooklyn. Citation: For gallantry."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1964, 12, 31))
      end

      # Real: McCLOUGHAN — "1969-1970" (year range only, no specific date)
      it "returns nil date for year-range-only entries (1969-1970)" do
        html = build_html(
          heading: "McCLOUGHAN, JAMES C.",
          text: "Rank and organization: Specialist Five, U.S. Army. " \
                "Place and date: Republic of Vietnam, 1969-1970. " \
                "Entered service at: Fort Knox, KY. Born: 30 April 1946. " \
                "Citation: For conspicuous gallantry from May 13 - 15, 1969."
        )
        r = parser.parse_index(html).first
        # Date comes from citation fallback, not from Place and date field
        expect(r[:date]).to eq(Date.new(1969, 5, 13))
        expect(r[:place]).to eq("Republic of Vietnam, 1969-1970")
      end

      # Real: JOEL — trailing comma after date "8 November 1965,"
      it "handles trailing comma after date (8 November 1965,)" do
        html = build_html(
          heading: "JOEL, LAWRENCE",
          text: "Rank and organization: Specialist Six, U.S. Army. " \
                "Place and date: Republic of Vietnam, 8 November 1965, " \
                "Entered service at: New York City. G.O. No.: 15. " \
                "Citation: For gallantry."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1965, 11, 8))
      end

      # Terminator variants: "Entered", "Born", "G.O."
      it "terminates on 'Born' instead of 'Entered'" do
        html = build_html(
          heading: "TEST, BORN",
          text: "Rank and organization: Private, U.S. Army. " \
                "Place and date: Vietnam, 5 June 1968. " \
                "Born: 1 January 1940. Citation: For gallantry."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1968, 6, 5))
      end

      it "terminates on 'G.O.' instead of 'Entered'" do
        html = build_html(
          heading: "TEST, GO",
          text: "Rank and organization: Private, U.S. Army. " \
                "Place and date: Vietnam, 5 June 1968. " \
                "G.O. No.: 45, 20 October 1967. Citation: For gallantry."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1968, 6, 5))
      end
    end

    # -------------------------------------------------------------------------
    # Citation-fallback date extraction (extract_date_from_citation)
    # -------------------------------------------------------------------------
    context "citation-fallback date extraction" do
      # Real: BIRDWELL, CRANDALL, FREEMAN — "on DD Month YYYY"
      it "extracts 'on DD Month, YYYY' from citation (BIRDWELL: on 31 January, 1968)" do
        html = build_html(
          heading: "BIRDWELL, DWIGHT W.",
          text: "For conspicuous gallantry. Specialist Five Dwight W. Birdwell " \
                "distinguished himself on 31 January, 1968 while serving with C Troop."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1968, 1, 31))
      end

      # Real: ALVARADO, CONDE-FALCON — "on Month DD, YYYY"
      it "extracts 'on Month DD, YYYY' from citation (ALVARADO: on August 12, 1969)" do
        html = build_html(
          heading: "ALVARADO, LEONARD L.",
          text: "For conspicuous gallantry. Specialist Four Leonard L. Alvarado " \
                "distinguished himself on August 12, 1969 while serving as a Rifleman."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1969, 8, 12))
      end

      # Real: McCLOUGHAN — "May 13 - 15, 1969" (Month DD - DD, YYYY range)
      it "extracts 'Month DD - DD, YYYY' range, uses first date" do
        html = build_html(
          heading: "McCLOUGHAN, JAMES C.",
          text: "For conspicuous gallantry. Private First Class James C. McCloughan " \
                "distinguished himself from May 13 - 15, 1969, while serving."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1969, 5, 13))
      end

      # Real: DUFFY — "14 to 15 April 1972" (DD to DD Month YYYY range)
      it "extracts 'DD to DD Month YYYY' range, uses first date (DUFFY)" do
        html = build_html(
          heading: "DUFFY, JOHN J.",
          text: "Major John J. Duffy distinguished himself from 14 to 15 April 1972 " \
                "while serving as Senior Advisor."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1972, 4, 14))
      end

      # Real: ROSE — standalone "DD Month YYYY" without "on" prefix
      # ROSE's real text has only "14 September 1970" as a date
      it "extracts standalone DD Month YYYY without 'on' prefix (ROSE)" do
        html = build_html(
          heading: "ROSE, GARY M.",
          text: "For conspicuous gallantry. Sergeant Gary M. Rose distinguished " \
                "himself during operations near Laos, 14 September 1970."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1970, 9, 14))
      end

      # Also cover the "DD to DD Month YYYY" citation fallback path (FUJII)
      it "extracts 'DD to DD Month YYYY' from citation fallback (FUJII)" do
        html = build_html(
          heading: "FUJII, DENNIS M.",
          text: "For conspicuous gallantry. Specialist Five Dennis M. Fujii " \
                "distinguished himself during the period 18 to 22 February 1971."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1971, 2, 18))
      end

      # Standalone "Month DD, YYYY" without "on" prefix
      it "extracts standalone Month DD YYYY without 'on' prefix" do
        html = build_html(
          heading: "FALLBACK, MONTH",
          text: "For conspicuous gallantry. He was killed in action. " \
                "The action occurred near Saigon on or about March 15, 1968."
        )
        # "on or about" won't match "on\s+March" but "on" followed by " or" — hits "on Month DD"
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1968, 3, 15))
      end

      # Real: CRANDALL — new-format without "Citation:" or "For conspicuous gallantry"
      it "uses raw text (stripped of Born:) for entries without Citation: or For conspicuous" do
        html = build_html(
          heading: "CRANDALL, BRUCE P.",
          text: "Major Bruce P. Crandall distinguished himself by extraordinary heroism " \
                "in the Republic of Vietnam on 14 November 1965, while serving with " \
                "Company A, 229th Assault Helicopter Battalion."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1965, 11, 14))
      end

      it "does not extract dates from Born: field in raw text fallback" do
        html = build_html(
          heading: "NODATE, PERSON",
          text: "Major Person Nodate served with distinction. " \
                "Born: 30 April 1946, Somewhere, USA. No specific action date."
        )
        expect(parser.parse_index(html).first[:date]).to be_nil
      end

      # Branch: Rank and organization present but no place_date → early return
      it "returns nil date when structured format has no parseable Place and date" do
        html = build_html(
          heading: "NOPLACEDATE, TEST",
          text: "Rank and organization: Private, U.S. Army. " \
                "Entered service at: Somewhere. " \
                "Citation: For gallantry in an action."
        )
        expect(parser.parse_index(html).first[:date]).to be_nil
      end

      # Line 197: early return when Rank and organization present, no Citation/For conspicuous,
      # and no date from place_and_date — hits the `else return` branch
      it "returns early from citation fallback when structured entry has no citation text" do
        html = build_html(
          heading: "NOCITATION, TEST",
          text: "Rank and organization: Private, U.S. Army. " \
                "Place and date: Vietnam, 1969-1970. " \
                "Entered service at: Somewhere. " \
                "The award was presented by the President."
        )
        r = parser.parse_index(html).first
        expect(r[:date]).to be_nil
        expect(r[:citation]).to be_nil
      end
    end

    # -------------------------------------------------------------------------
    # Citation text extraction
    # -------------------------------------------------------------------------
    context "citation text extraction" do
      # Real: 241 entries — "Citation: For conspicuous gallantry..."
      it "extracts citation after 'Citation:' keyword" do
        html = build_html(
          heading: "STANDARD, CITATION",
          text: "Rank and organization: Private, U.S. Army. " \
                "Place and date: Vietnam, 1 March 1968. " \
                "Entered service at: X. " \
                "Citation: For conspicuous gallantry and intrepidity."
        )
        r = parser.parse_index(html).first
        expect(r[:citation]).to eq("For conspicuous gallantry and intrepidity.")
      end

      # Real: CREEK — double colon "Citation::" on army.mil
      it "handles double colon 'Citation::'" do
        html = build_html(
          heading: "CREEK, THOMAS E.",
          text: "Rank and organization: Corporal, U.S. Army. " \
                "Place and date: Near Cam Lo, 13 February 1969. " \
                "Entered service at: Amarillo. " \
                "Citation:: For conspicuous gallantry."
        )
        r = parser.parse_index(html).first
        expect(r[:citation]).to eq("For conspicuous gallantry.")
      end

      # Real: 20 entries — "For conspicuous gallantry..." (no Citation: prefix)
      it "extracts citation starting with 'For conspicuous gallantry'" do
        html = build_html(
          heading: "ALVARADO, LEONARD L.",
          text: "For conspicuous gallantry and intrepidity at the risk of his life. " \
                "Specialist Four Alvarado distinguished himself on August 12, 1969."
        )
        r = parser.parse_index(html).first
        expect(r[:citation]).to start_with("For conspicuous gallantry")
      end

      # Real: BENAVIDEZ, CRANDALL, WETZEL — neither Citation: nor "For conspicuous"
      it "leaves citation nil when neither Citation: nor For conspicuous present" do
        html = build_html(
          heading: "WETZEL, GARY GEORGE",
          text: "The President of the United States of America awards the Medal of Honor " \
                "to Gary George Wetzel for service on 8 January 1968."
        )
        r = parser.parse_index(html).first
        expect(r[:citation]).to be_nil
      end
    end

    # -------------------------------------------------------------------------
    # Branch detection
    # -------------------------------------------------------------------------
    context "branch detection" do
      # Real examples: USA (178), USMC (57), USAF (15), USN (14)
      it "detects Marine Corps" do
        html = build_html(heading: "A, B", text: "U.S. Marine Corps. Place and date: Vietnam, 1 March 1968. Entered service at: X. Citation: Test.")
        expect(parser.parse_index(html).first[:branch]).to eq("USMC")
      end

      it "detects Air Force" do
        html = build_html(heading: "C, D", text: "U.S. Air Force. Place and date: Vietnam, 1 March 1968. Entered service at: X. Citation: Test.")
        expect(parser.parse_index(html).first[:branch]).to eq("USAF")
      end

      it "detects Navy" do
        html = build_html(heading: "E, F", text: "U.S. Navy. Place and date: Vietnam, 1 March 1968. Entered service at: X. Citation: Test.")
        expect(parser.parse_index(html).first[:branch]).to eq("USN")
      end

      it "defaults to Army" do
        html = build_html(heading: "G, H", text: "U.S. Army. Place and date: Vietnam, 1 March 1968. Entered service at: X. Citation: Test.")
        expect(parser.parse_index(html).first[:branch]).to eq("USA")
      end
    end

    # -------------------------------------------------------------------------
    # Rank extraction from citation (extract_rank_from_citation)
    # -------------------------------------------------------------------------
    context "rank extraction from citation text" do
      # Real examples from new-format entries
      {
        "Specialist Four" => "ALVARADO",
        "Specialist Five" => "BIRDWELL",
        "Staff Sergeant" => "CONDE-FALCON",
        "Major" => "CRANDALL",
        "Captain" => "FREEMAN (after Major is checked)",
        "Sergeant First Class" => "RODELA",
        "Sergeant" => "GARCIA (bare Sergeant, not Staff/First/etc.)"
      }.each do |rank, note|
        it "extracts #{rank} (#{note})" do
          html = build_html(
            heading: "TEST, #{rank.upcase}",
            text: "#{rank} John Doe distinguished himself on 1 March 1968."
          )
          r = parser.parse_index(html).first
          expect(r[:rank]).to eq(rank)
        end
      end

      it "matches ranks in priority order (Specialist Four before Private)" do
        html = build_html(
          heading: "PRIORITY, TEST",
          text: "Specialist Four John Private distinguished himself on 1 March 1968."
        )
        expect(parser.parse_index(html).first[:rank]).to eq("Specialist Four")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # to_event
  # ---------------------------------------------------------------------------
  describe "#to_event" do
    let(:recipient) do
      {
        name: "KELLOGG, ALLAN JAY, JR.",
        posthumous: false,
        rank: "Gunnery Sergeant",
        organization: "Company G, 2d Battalion, 5th Marines",
        place: "Quang Nam Province, Republic of Vietnam",
        date: Date.new(1970, 3, 11),
        citation: "For conspicuous gallantry and intrepidity. He threw himself on a grenade.",
        branch: "USMC"
      }
    end

    it "generates an event hash with correct date fields" do
      event = parser.to_event(recipient, source_url: "https://army.mil/test")
      expect(event["month"]).to eq(3)
      expect(event["day"]).to eq(11)
      expect(event["year"]).to eq(1970)
    end

    it "formats the title with rank and name" do
      event = parser.to_event(recipient, source_url: "")
      expect(event["title"]).to eq("Gunnery Sergeant Allan Jay Kellogg, Jr. earns Medal of Honor")
    end

    it "marks posthumous in title" do
      recipient[:posthumous] = true
      event = parser.to_event(recipient, source_url: "")
      expect(event["title"]).to include("(posthumous)")
    end

    it "does not mark non-posthumous in title" do
      event = parser.to_event(recipient, source_url: "")
      expect(event["title"]).not_to include("posthumous")
    end

    it "wraps citation summary in <p> tags" do
      event = parser.to_event(recipient, source_url: "")
      expect(event["body"]).to start_with("<p>")
      expect(event["body"]).to end_with("</p>")
    end

    it "includes source URL in references" do
      event = parser.to_event(recipient, source_url: "https://army.mil/citations25.html")
      expect(event["references"].first["url"]).to eq("https://army.mil/citations25.html")
      expect(event["references"].first["label"]).to include("Allan Jay Kellogg")
    end

    it "returns nil when recipient has no date" do
      recipient[:date] = nil
      expect(parser.to_event(recipient)).to be_nil
    end

    it "uses 'Unknown rank' when rank is nil" do
      recipient[:rank] = nil
      event = parser.to_event(recipient, source_url: "")
      expect(event["title"]).to start_with("Unknown rank")
    end

    it "handles nil citation gracefully" do
      recipient[:citation] = nil
      event = parser.to_event(recipient, source_url: "")
      expect(event["body"]).to eq("<p></p>")
    end

    it "handles empty citation gracefully" do
      recipient[:citation] = ""
      event = parser.to_event(recipient, source_url: "")
      expect(event["body"]).to eq("<p></p>")
    end
  end

  # ---------------------------------------------------------------------------
  # format_name (private, tested via to_event)
  # ---------------------------------------------------------------------------
  describe "name formatting (via #to_event)" do
    def format_name_via_event(name)
      recipient = { name: name, posthumous: false, rank: "Private",
                     date: Date.new(1968, 1, 1), citation: "Test." }
      event = parser.to_event(recipient, source_url: "")
      event["title"].sub("Private ", "").sub(" earns Medal of Honor", "")
    end

    # Real: standard "LAST, FIRST MIDDLE"
    it "formats LAST, FIRST to First Last" do
      expect(format_name_via_event("SMITH, JOHN")).to eq("John Smith")
    end

    # Real: ANDERSON, JAMES, JR. — suffix Jr.
    it "formats name with Jr. suffix" do
      expect(format_name_via_event("ANDERSON, JAMES, JR.")).to eq("James Anderson, Jr.")
    end

    # Real: BAKER, JOHN F., JR.
    it "formats name with middle initial and Jr." do
      expect(format_name_via_event("BAKER, JOHN F., JR.")).to eq("John F. Baker, Jr.")
    end

    # Real: BARNES, JOHN ANDREW III
    it "formats name with III suffix" do
      expect(format_name_via_event("JONES, WILLIAM A., III")).to eq("William A. Jones, III")
    end

    # Edge: single name without comma (PITSENBARGER WILLIAM H.)
    it "handles name without comma (single-part)" do
      expect(format_name_via_event("PITSENBARGER")).to eq("Pitsenbarger")
    end

    # Real: DE LA GARZA — multi-word last name
    it "capitalizes multi-word first names" do
      expect(format_name_via_event("GARZA, EMILIO ALFONSO")).to eq("Emilio Alfonso Garza")
    end

    # Edge: empty string — exercises &. safe navigation nil branches
    it "handles empty string name gracefully" do
      recipient = { name: "", posthumous: false, rank: "Private",
                     date: Date.new(1968, 1, 1), citation: "Test." }
      event = parser.to_event(recipient, source_url: "")
      expect(event["title"]).to include("Medal of Honor")
    end
  end

  # ---------------------------------------------------------------------------
  # summarize (private, tested via to_event)
  # ---------------------------------------------------------------------------
  describe "summarize (via #to_event body)" do
    def body_for_citation(citation, max_len: 400)
      recipient = { name: "TEST, PERSON", posthumous: false, rank: "Private",
                     date: Date.new(1968, 1, 1), citation: citation }
      parser.to_event(recipient, source_url: "")["body"]
    end

    it "includes full citation when shorter than max_len" do
      body = body_for_citation("He was brave. He fought well.")
      expect(body).to eq("<p>He was brave. He fought well.</p>")
    end

    it "truncates to complete sentences within max_len" do
      short = "First sentence. " * 5  # ~80 chars
      long = short + "A" * 400
      body = body_for_citation(long)
      expect(body).to include("First sentence.")
      expect(body.length).to be <= 410  # <p></p> + ~400
    end

    # Edge: single sentence longer than max_len — fallback to text[0..max_len]
    it "falls back to truncation when a single sentence exceeds max_len" do
      long_sentence = "He " + "fought " * 100 + "bravely."
      body = body_for_citation(long_sentence)
      expect(body).to start_with("<p>He fought")
      expect(body).to end_with("</p>")
    end
  end

  # ---------------------------------------------------------------------------
  # parse_date (private, tested via parse_index)
  # ---------------------------------------------------------------------------
  describe "date parsing edge cases" do
    context "DD Month YYYY format (parse_date first branch)" do
      it "returns nil for unrecognized month name in DD Month YYYY" do
        html = build_html(
          heading: "BADMONTH, TEST",
          text: "Rank and organization: Private, U.S. Army. " \
                "Place and date: Vietnam, 15 Thermidor 1968. " \
                "Entered service at: X. Citation: Test."
        )
        expect(parser.parse_index(html).first[:date]).to be_nil
      end
    end

    context "Month DD YYYY format (parse_date second branch)" do
      # Real: SABO — "May 10, 1970" in Place and date field
      it "parses Month DD, YYYY via parse_date elsif branch" do
        html = build_html(
          heading: "SABO, LESLIE H., JR.",
          text: "Rank and organization: Specialist Four, U.S. Army. " \
                "Place and date: Se San, Cambodia, May 10, 1970. " \
                "Entered service at: Ellwood City, Pa. Citation: For gallantry."
        )
        expect(parser.parse_index(html).first[:date]).to eq(Date.new(1970, 5, 10))
      end

      # Exercise parse_date Month DD YYYY branch directly to ensure branch coverage
      it "exercises parse_date Month DD YYYY branch directly" do
        date = parser.send(:parse_date, "March 11, 1970")
        expect(date).to eq(Date.new(1970, 3, 11))
      end

      it "returns nil for unrecognized month in Month DD YYYY format" do
        date = parser.send(:parse_date, "Fructidor 15, 1968")
        expect(date).to be_nil
      end
    end

    context "DD Month YYYY format (parse_date first branch)" do
      it "returns nil for unrecognized month in DD Month YYYY format" do
        date = parser.send(:parse_date, "15 Thermidor 1968")
        expect(date).to be_nil
      end
    end

    context "no matching format (parse_date implicit nil)" do
      it "returns nil for completely unparseable date strings" do
        date = parser.send(:parse_date, "no date here")
        expect(date).to be_nil
      end
    end
  end

  # ---------------------------------------------------------------------------
  # filter_by_month / filter_by_branch
  # ---------------------------------------------------------------------------
  describe "#filter_by_month" do
    it "filters recipients by one or more months" do
      recipients = [
        { date: Date.new(1968, 1, 30) },
        { date: Date.new(1968, 3, 15) },
        { date: Date.new(1968, 1, 15) },
        { date: nil }
      ]
      result = parser.filter_by_month(recipients, 1, 3)
      expect(result.size).to eq(3)
    end

    it "excludes recipients with nil dates" do
      recipients = [{ date: nil }, { date: nil }]
      expect(parser.filter_by_month(recipients, 1)).to be_empty
    end
  end

  describe "#filter_by_branch" do
    it "filters recipients by branch" do
      recipients = [
        { branch: "USMC" },
        { branch: "USA" },
        { branch: "USMC" }
      ]
      expect(parser.filter_by_branch(recipients, "USMC").size).to eq(2)
    end

    it "returns empty when no matches" do
      recipients = [{ branch: "USA" }]
      expect(parser.filter_by_branch(recipients, "USAF")).to be_empty
    end
  end

  # ---------------------------------------------------------------------------
  # Integration test with cached HTML
  # ---------------------------------------------------------------------------
  describe "integration with cached HTML" do
    let(:cache_dir) { File.expand_path("../../cache", __dir__) }
    let(:metas) { Dir.glob(File.join(cache_dir, "*.meta")) }

    before do
      skip "No cached HTML files" if metas.empty?
    end

    it "parses all recipients with dates from both cached pages" do
      files = metas.map { |m| [File.read(m).strip, m.sub(".meta", ".html")] }.to_h

      al_file = files.find { |url, _| url.include?("citations25") }
      mz_file = files.find { |url, _| url.include?("citations26") }
      skip "Missing cached pages" unless al_file && mz_file

      al = parser.parse_index(File.read(al_file[1]))
      mz = parser.parse_index(File.read(mz_file[1]))
      all = al + mz

      expect(all.size).to be >= 260
      expect(all.select { |r| r[:date] }.size).to eq(all.size)

      all.each do |r|
        expect(r[:date].year).to be_between(1964, 1975),
          "#{r[:name]} has date #{r[:date]} outside 1964-1975"
      end
    end

    it "generates events for all recipients with dates" do
      files = metas.map { |m| [File.read(m).strip, m.sub(".meta", ".html")] }.to_h
      al_file = files.find { |url, _| url.include?("citations25") }
      mz_file = files.find { |url, _| url.include?("citations26") }
      skip "Missing cached pages" unless al_file && mz_file

      al = parser.parse_index(File.read(al_file[1]))
      mz = parser.parse_index(File.read(mz_file[1]))

      events = (al + mz).filter_map { |r| parser.to_event(r, source_url: "https://example.com") }
      expect(events.size).to eq(al.size + mz.size)
      events.each do |e|
        expect(e["month"]).to be_between(1, 12)
        expect(e["day"]).to be_between(1, 31)
        expect(e["title"]).to include("Medal of Honor")
        expect(e["body"]).to start_with("<p>")
        expect(e["references"]).not_to be_empty
      end
    end
  end
end
