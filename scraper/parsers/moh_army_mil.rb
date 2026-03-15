#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# MOH Army.mil parser
# =============================================================================
#
# Parses the army.mil Vietnam MOH citations pages (citations25.html = A-L,
# citations26.html = M-Z). Each page lists all recipients with full
# inline citations.
#
# Usage:
#   parser = MohArmyMilParser.new
#   recipients = parser.parse_index(html)
#   events = recipients.map { |r| parser.to_event(r) }

require "nokogiri"
require "date"

class MohArmyMilParser
  MONTHS = %w[January February March April May June July August September October November December].freeze
  MONTH_RE = MONTHS.join("|")

  # Parse an index page and return an array of recipient hashes.
  # Each hash contains:
  #   :name, :posthumous, :rank, :organization, :place, :date,
  #   :entered_service, :born, :citation, :raw_text
  def parse_index(html)
    doc = Nokogiri::HTML(html)
    recipients = []

    doc.css("h3").each do |h3|
      name_raw = h3.text.strip
      next if name_raw.match?(/Additional Medal of Honor/i)

      node = h3.next
      text = ""
      until node.nil? || %w[h2 h3].include?(node.name)
        text += node.text
        node = node.next
      end

      raw = text.gsub(/\s+/, " ").strip
      next if raw.empty?
      next if raw.match?(/Additional Medal of Honor/i)

      posthumous = name_raw.start_with?("*")
      name = name_raw.sub(/^\*\s*/, "").strip

      recipient = {
        name: name,
        posthumous: posthumous,
        raw_text: raw
      }

      # Extract structured fields — handles "date" and "dale" (typo on army.mil)
      if (m = raw.match(/Rank and organization:\s*(.+?)(?:\.\s*Place|\s*Place)/i))
        rank_org = m[1].strip
        if (ro = rank_org.match(/\A(.+?),\s*(.+)/))
          recipient[:rank] = ro[1].strip
          recipient[:organization] = ro[2].strip
        else
          recipient[:rank] = rank_org
        end
      end

      extract_place_and_date(raw, recipient)

      # Fallback: extract date from citation text for new-format entries
      unless recipient[:date]
        extract_date_from_citation(raw, recipient)
      end

      # Extract citation text
      if (m = raw.match(/Citation:+\s*(.*)/i))
        recipient[:citation] = m[1].strip
      elsif (m = raw.match(/(For conspicuous gallantry.*)/i))
        recipient[:citation] = m[1].strip
      end

      # Extract branch
      recipient[:branch] = if raw.match?(/Marine Corps/i)
                               "USMC"
                             elsif raw.match?(/U\.S\. Navy|Navy/i)
                               "USN"
                             elsif raw.match?(/Air Force/i)
                               "USAF"
                             else
                               "USA"
                             end

      # Extract rank from new-format citations if not already found
      unless recipient[:rank]
        extract_rank_from_citation(raw, recipient)
      end

      recipients << recipient
    end

    recipients
  end

  # Filter recipients by month (1-12).
  def filter_by_month(recipients, *months)
    recipients.select { |r| r[:date] && months.include?(r[:date].month) }
  end

  # Filter by branch.
  def filter_by_branch(recipients, branch)
    recipients.select { |r| r[:branch] == branch }
  end

  # Convert a parsed recipient to the event YAML format.
  def to_event(recipient, source_url: "")
    return nil unless recipient[:date]

    name = format_name(recipient[:name])
    date = recipient[:date]
    posthumous = recipient[:posthumous] ? " (posthumous)" : ""
    rank = recipient[:rank] || "Unknown rank"

    # Build a concise body from the citation
    citation = recipient[:citation] || ""
    summary = summarize(citation, 400)

    unit = recipient[:organization] || ""
    place = recipient[:place] || "Vietnam"

    {
      "month" => date.month,
      "day" => date.day,
      "year" => date.year,
      "title" => "#{rank} #{name} earns Medal of Honor#{posthumous}",
      "body" => "<p>#{summary}</p>",
      "photo_url" => nil,
      "photo_alt" => nil,
      "references" => [
        {
          "label" => "Medal of Honor Citation — #{name} (army.mil)",
          "url" => source_url
        }
      ]
    }
  end

  private

  # TODO: Refactor extract_place_and_date — the cascading if/elsif regex chain is
  # brittle and order-dependent (e.g., COOK's date range hits the wrong branch because
  # "Month DD, YYYY" at end of string matches before the "to" branch). Consider:
  # - A DateExtractor class with named patterns and explicit priority
  # - Normalizing the place_date string first (strip trailing punctuation, collapse
  #   ordinals, normalize "to"/"and" ranges) then matching a single canonical form
  # - Extracting place and date as separate steps rather than splitting a combined field
  # Full branch coverage is in place (82 specs, 100% line+branch) to support safe refactoring.
  def extract_place_and_date(raw, recipient)
    # Match "Place and date:" or "Place and dale:" (typo) or "Place and date." (period instead of colon)
    m = raw.match(/Place and [Dd]a[lt]e[.:]\s*(.+?)(?:\.\s*Entered|\s*Entered|\s*Born|\s*G\.O\.)/i)
    return unless m

    place_date = m[1].strip.sub(/[.,]+\z/, "")

    # Try standard date patterns at end of string
    date = nil
    place = place_date

    # "25 May 1971" or "May 25, 1971"
    if (pd = place_date.match(/(.+?),?\s*(\d{1,2}\s+(?:#{MONTH_RE})\s+\d{4})\s*$/i))
      place = pd[1].strip.sub(/,\s*$/, "")
      date = parse_date(pd[2])
    elsif (pd = place_date.match(/(.+?),?\s*((?:#{MONTH_RE})\s+\d{1,2},?\s+\d{4})\s*$/i))
      place = pd[1].strip.sub(/,\s*$/, "")
      date = parse_date(pd[2])
    # "13 February. 1969" (period instead of comma)
    elsif (pd = place_date.match(/(.+?),?\s*(\d{1,2}\s+(?:#{MONTH_RE})[.,]?\s+\d{4})\s*$/i))
      place = pd[1].strip.sub(/,\s*$/, "")
      date = parse_date(pd[2].gsub(/[.,]/, " "))
    # "6th and 7th February 1968" — use first date
    elsif (pd = place_date.match(/(.+?),?\s*(\d{1,2})(?:st|nd|rd|th)\s+(?:and|to|-)\s+\d{1,2}(?:st|nd|rd|th)?\s+((?:#{MONTH_RE})\s+\d{4})/i))
      place = pd[1].strip.sub(/,\s*$/, "")
      date = parse_date("#{pd[2]} #{pd[3]}")
    # Date range "31 December 1964 to 8 December, 1967" — use first date
    elsif (pd = place_date.match(/(.+?),?\s*(\d{1,2}\s+(?:#{MONTH_RE})\s+\d{4})\s+to\s/i))
      place = pd[1].strip.sub(/,\s*$/, "")
      date = parse_date(pd[2])
    # Year range "1969-1970" — skip, too vague
    end

    recipient[:place] = place
    recipient[:date] = date if date
    recipient[:date_raw] = place_date if date
  end

  # TODO: Refactor extract_date_from_citation — similar cascading regex issue.
  # The citation-source selection (Citation: vs "For conspicuous" vs raw text) and
  # the date pattern matching are two distinct concerns tangled together. Consider
  # extracting a citation_text(raw) method and reusing the same date patterns as
  # extract_place_and_date. The "Born:" stripping is a workaround for the lack of
  # structured field boundaries in new-format entries.
  def extract_date_from_citation(raw, recipient)
    # Use only the citation portion to avoid grabbing "Born:" dates.
    # For new-format entries without structured fields, the entire text is
    # the citation — but strip any "Born:" section to avoid birthdate matches.
    citation = if (m = raw.match(/Citation:+\s*(.*)/i))
                 m[1]
               elsif (m = raw.match(/(For conspicuous gallantry.*)/i))
                 m[1]
               elsif !raw.match?(/Rank and organization/i)
                 raw.sub(%r{Born:.*}i, "")
               else
                 return
               end

    if (m = citation.match(/on\s+(\d{1,2}\s+(?:#{MONTH_RE}),?\s+\d{4})/i))
      recipient[:date] = parse_date(m[1])
    elsif (m = citation.match(/on\s+((?:#{MONTH_RE})\s+\d{1,2},?\s+\d{4})/i))
      recipient[:date] = parse_date(m[1])
    # "May 13 - 15, 1969" — use first date
    elsif (m = citation.match(/((?:#{MONTH_RE})\s+\d{1,2})\s*[-–]\s*\d{1,2},?\s+(\d{4})/i))
      recipient[:date] = parse_date("#{m[1]} #{m[2]}")
    # "during the period 10 to 15 May 1968" — use first date
    elsif (m = citation.match(/(\d{1,2})\s+(?:to|-)\s+\d{1,2}\s+((?:#{MONTH_RE})\s+\d{4})/i))
      recipient[:date] = parse_date("#{m[1]} #{m[2]}")
    # Standalone date: "14 November 1965"
    elsif (m = citation.match(/(\d{1,2}\s+(?:#{MONTH_RE}),?\s+\d{4})/i))
      recipient[:date] = parse_date(m[1])
    elsif (m = citation.match(/((?:#{MONTH_RE})\s+\d{1,2},?\s+\d{4})/i))
      recipient[:date] = parse_date(m[1])
    end
  end

  def extract_rank_from_citation(raw, recipient)
    ranks = [
      "Specialist Four", "Specialist Five", "Specialist Six",
      "Private First Class", "Staff Sergeant", "Sergeant First Class",
      "Master Sergeant", "First Sergeant", "Sergeant Major",
      "Command Sergeant Major", "Gunnery Sergeant",
      "Second Lieutenant", "First Lieutenant", "Lieutenant Colonel",
      "Brigadier General", "Major General",
      "Corporal", "Sergeant", "Lieutenant", "Captain", "Major",
      "Colonel", "General", "Private"
    ]
    ranks.each do |rank|
      if raw.match?(/\b#{Regexp.escape(rank)}\b/i)
        recipient[:rank] = rank
        return
      end
    end
  end

  # TODO: Refactor parse_date — consolidate with the date patterns in
  # extract_place_and_date and extract_date_from_citation. All three methods
  # duplicate month-name matching. A single DateParser with named patterns
  # would reduce the surface area for regex bugs.
  def parse_date(str)
    str = str.gsub(/[.,]/, " ").gsub(/\s+/, " ").strip
    if (m = str.match(/(\d{1,2})\s+(\w+)\s+(\d{4})/))
      mi = MONTHS.index(m[2])
      return nil unless mi
      Date.new(m[3].to_i, mi + 1, m[1].to_i) rescue nil
    elsif (m = str.match(/(\w+)\s+(\d{1,2})\s*(\d{4})/))
      mi = MONTHS.index(m[1])
      return nil unless mi
      Date.new(m[3].to_i, mi + 1, m[2].to_i) rescue nil
    end
  end

  def format_name(name)
    # "KELLOGG, ALLAN JAY, JR." → "Allan Jay Kellogg, Jr."
    parts = name.split(",").map(&:strip)
    last = parts[0]&.capitalize
    rest = parts[1..]&.map do |p|
      if p.match?(/\A(jr|sr|ii|iii|iv)\z/i)
        p.sub(/\A(jr|sr)\z/i) { $1.capitalize + "." }
          .sub(/\A(ii|iii|iv)\z/i, &:upcase)
      else
        p.split.map(&:capitalize).join(" ")
      end
    end
    if rest && rest.any?
      suffix_parts, name_parts = rest.partition { |p| p.match?(/\A(Jr\.|Sr\.|II|III|IV)\z/) }
      result = (name_parts + [last]).join(" ")
      result += ", #{suffix_parts.join(', ')}" if suffix_parts.any?
      result
    else
      last
    end
  end

  def summarize(text, max_len)
    return "" if text.nil? || text.empty?
    sentences = text.split(/(?<=[.!])\s+/)
    result = ""
    sentences.each do |s|
      break if (result + " " + s).length > max_len
      result = result.empty? ? s : "#{result} #{s}"
    end
    result.empty? ? text[0..max_len] : result
  end
end
