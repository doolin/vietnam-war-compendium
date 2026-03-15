# frozen_string_literal: true

require "rspec"
require_relative "../../parsers/moh_army_mil"

RSpec.describe MohArmyMilParser do
  subject(:parser) { described_class.new }

  def build_html(*entries)
    body = entries.map { |e| "<h3>#{e[:heading]}</h3><p>#{e[:text]}</p>" }.join
    "<html><body>#{body}</body></html>"
  end

  describe "#parse_index" do
    it "extracts name, rank, organization, place, date, and citation" do
      html = build_html(
        heading: "DONLON, ROGER HUGH C.",
        text: "Rank and organization: Captain, U.S. Army. Place and date: " \
              "Near Nam Dong, Republic of Vietnam, 6 July 1964. " \
              "Entered service at: Fort Benning, Ga. Born: 30 January 1934. " \
              "Citation: For conspicuous gallantry and intrepidity."
      )

      recipients = parser.parse_index(html)
      expect(recipients.size).to eq(1)

      r = recipients.first
      expect(r[:name]).to eq("DONLON, ROGER HUGH C.")
      expect(r[:rank]).to eq("Captain")
      expect(r[:organization]).to eq("U.S. Army")
      expect(r[:place]).to eq("Near Nam Dong, Republic of Vietnam")
      expect(r[:date]).to eq(Date.new(1964, 7, 6))
      expect(r[:citation]).to include("conspicuous gallantry")
    end

    it "marks posthumous recipients" do
      html = build_html(heading: "* SMITH, JOHN", text: "Rank and organization: Private, U.S. Army. Place and date: Vietnam, 1 March 1968. Entered service at: Somewhere. Citation: For gallantry.")
      r = parser.parse_index(html).first
      expect(r[:posthumous]).to be true
      expect(r[:name]).to eq("SMITH, JOHN")
    end

    it "skips Additional Medal of Honor Resources entries" do
      html = build_html(
        { heading: "SMITH, JOHN", text: "Rank and organization: Private, U.S. Army. Place and date: Vietnam, 1 March 1968. Entered service at: X. Citation: Test." },
        { heading: "Additional Medal of Honor Resources", text: "Links and resources." }
      )
      expect(parser.parse_index(html).size).to eq(1)
    end

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

    it "handles period instead of colon (Place and date.)" do
      html = build_html(
        heading: "DOLBY, DAVID CHARLES",
        text: "Rank and organization. Sergeant, U.S. Army. " \
              "Place and date. Republic of Vietnam, 21 May 1966. " \
              "Entered service at: Philadelphia. Citation: For gallantry."
      )
      r = parser.parse_index(html).first
      expect(r[:date]).to eq(Date.new(1966, 5, 21))
    end

    it "handles ordinal date ranges like '6th and 7th February 1968'" do
      html = build_html(
        heading: "ASHLEY, EUGENE, JR.",
        text: "Rank and organization: Sergeant, U.S. Army. " \
              "Place and date: Near Lang Vei, Republic of Vietnam, 6th and 7th February 1968. " \
              "Entered service at: New York. Citation: For gallantry."
      )
      r = parser.parse_index(html).first
      expect(r[:date]).to eq(Date.new(1968, 2, 6))
    end

    it "handles date with period before year like '13 February. 1969'" do
      html = build_html(
        heading: "CREEK, THOMAS E.",
        text: "Rank and organization: Corporal, U.S. Army. " \
              "Place and date: Near Cam Lo, Republic of Vietnam, 13 February. 1969. " \
              "Entered service at: Amarillo, Texas. Citation: For gallantry."
      )
      r = parser.parse_index(html).first
      expect(r[:date]).to eq(Date.new(1969, 2, 13))
    end

    it "extracts date from citation text for new-format entries" do
      html = build_html(
        heading: "CRANDALL, BRUCE P.",
        text: "Major Bruce P. Crandall distinguished himself by extraordinary heroism " \
              "in the Republic of Vietnam on 14 November 1965, while serving with " \
              "Company A, 229th Assault Helicopter Battalion."
      )
      r = parser.parse_index(html).first
      expect(r[:date]).to eq(Date.new(1965, 11, 14))
    end

    it "extracts date from 'Month DD - DD, YYYY' range in citation" do
      html = build_html(
        heading: "McCLOUGHAN, JAMES C.",
        text: "For conspicuous gallantry and intrepidity in action. " \
              "Private First Class James C. McCloughan distinguished himself " \
              "from May 13 - 15, 1969, while serving in the Republic of Vietnam."
      )
      r = parser.parse_index(html).first
      expect(r[:date]).to eq(Date.new(1969, 5, 13))
    end

    it "does not extract dates from Born: field" do
      html = build_html(
        heading: "TEST, PERSON",
        text: "Rank and organization: Private, U.S. Army. " \
              "Place and date: Republic of Vietnam, 1969-1970. " \
              "Entered service at: Somewhere. Born: 30 April 1946. " \
              "Citation: For gallantry on a date unknown."
      )
      r = parser.parse_index(html).first
      expect(r[:date]).to be_nil
    end

    it "detects branch from text" do
      usmc = build_html(heading: "A, B", text: "U.S. Marine Corps. Place and date: Vietnam, 1 March 1968. Entered service at: X. Citation: Test.")
      usaf = build_html(heading: "C, D", text: "U.S. Air Force. Place and date: Vietnam, 1 March 1968. Entered service at: X. Citation: Test.")
      usn = build_html(heading: "E, F", text: "U.S. Navy. Place and date: Vietnam, 1 March 1968. Entered service at: X. Citation: Test.")
      usa = build_html(heading: "G, H", text: "U.S. Army. Place and date: Vietnam, 1 March 1968. Entered service at: X. Citation: Test.")

      expect(parser.parse_index(usmc).first[:branch]).to eq("USMC")
      expect(parser.parse_index(usaf).first[:branch]).to eq("USAF")
      expect(parser.parse_index(usn).first[:branch]).to eq("USN")
      expect(parser.parse_index(usa).first[:branch]).to eq("USA")
    end
  end

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

    it "generates an event hash with correct fields" do
      event = parser.to_event(recipient, source_url: "https://army.mil/test")
      expect(event["month"]).to eq(3)
      expect(event["day"]).to eq(11)
      expect(event["year"]).to eq(1970)
      expect(event["title"]).to include("Allan Jay Kellogg")
      expect(event["title"]).to include("Medal of Honor")
      expect(event["body"]).to start_with("<p>")
      expect(event["references"].first["url"]).to eq("https://army.mil/test")
    end

    it "marks posthumous in title" do
      recipient[:posthumous] = true
      event = parser.to_event(recipient, source_url: "")
      expect(event["title"]).to include("(posthumous)")
    end

    it "returns nil when recipient has no date" do
      recipient[:date] = nil
      expect(parser.to_event(recipient)).to be_nil
    end
  end

  describe "#filter_by_month" do
    it "filters recipients by month" do
      recipients = [
        { date: Date.new(1968, 1, 30) },
        { date: Date.new(1968, 3, 15) },
        { date: nil }
      ]
      result = parser.filter_by_month(recipients, 1)
      expect(result.size).to eq(1)
      expect(result.first[:date].month).to eq(1)
    end
  end

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

      # Every recipient should have a date in the Vietnam War era
      all.each do |r|
        expect(r[:date].year).to be_between(1964, 1975),
          "#{r[:name]} has date #{r[:date]} outside 1964-1975"
      end
    end
  end
end
