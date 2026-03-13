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
  # Parse an index page and return an array of recipient hashes.
  # Each hash contains:
  #   :name, :posthumous, :rank, :organization, :place, :date,
  #   :entered_service, :born, :citation, :raw_text
  def parse_index(html)
    doc = Nokogiri::HTML(html)
    recipients = []

    doc.css("h3").each do |h3|
      name_raw = h3.text.strip
      node = h3.next
      text = ""
      until node.nil? || %w[h2 h3].include?(node.name)
        text += node.text
        node = node.next
      end

      raw = text.strip
      next if raw.empty?

      posthumous = name_raw.start_with?("*")
      name = name_raw.sub(/^\*\s*/, "").strip

      recipient = {
        name: name,
        posthumous: posthumous,
        raw_text: raw
      }

      # Extract structured fields
      if (m = raw.match(/Rank and organization:\s*(.+?)(?:\.\s*Place|\s*Place)/mi))
        rank_org = m[1].strip
        if (ro = rank_org.match(/\A(.+?),\s*(.+)/))
          recipient[:rank] = ro[1].strip
          recipient[:organization] = ro[2].strip
        else
          recipient[:rank] = rank_org
        end
      end

      if (m = raw.match(/Place and [Dd]ate:\s*(.+?)(?:\.\s*Entered|\s*Entered|\s*Born|\s*G\.O\.)/mi))
        place_date = m[1].strip.gsub(/\s+/, " ")
        # Split on the date portion
        if (pd = place_date.match(/(.+?),?\s*(\d{1,2}\s+\w+\s+\d{4}|\w+\s+\d{1,2},?\s+\d{4})\s*$/))
          recipient[:place] = pd[1].strip.sub(/,\s*$/, "")
          recipient[:date] = parse_date(pd[2])
          recipient[:date_raw] = pd[2].strip
        else
          recipient[:place] = place_date
        end
      end

      # Extract citation text
      if (m = raw.match(/(Citation:\s*)(.*)/mi))
        recipient[:citation] = m[2].strip.gsub(/\s+/, " ")
      elsif (m = raw.match(/(For conspicuous gallantry.*)/mi))
        recipient[:citation] = m[1].strip.gsub(/\s+/, " ")
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

  def parse_date(str)
    # "25 May 1971" or "March 11, 1970"
    months = %w[January February March April May June July August September October November December]
    if (m = str.match(/(\d{1,2})\s+(\w+)\s+(\d{4})/))
      mi = months.index(m[2])
      return nil unless mi
      Date.new(m[3].to_i, mi + 1, m[1].to_i) rescue nil
    elsif (m = str.match(/(\w+)\s+(\d{1,2}),?\s+(\d{4})/))
      mi = months.index(m[1])
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
