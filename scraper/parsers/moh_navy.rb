#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# MOH Navy/Marine Corps parser
# =============================================================================
#
# Parses the Navy History and Heritage Command's Vietnam War MOH page.
# Extracts individual recipient links, then parses each recipient page
# for citation details (name, rank, unit, date, place, citation text).
#
# Usage:
#   parser = MohNavyParser.new
#   links = parser.extract_recipient_links(index_html)
#   event = parser.parse_citation(citation_html, source_url: url)

require "nokogiri"
require "date"

class MohNavyParser
  INDEX_URL = "https://www.history.navy.mil/browse-by-topic/heritage/awards/decorations/medal-of-honor/vietnam-war-medal-of-honor-recipients.html"

  # Extract links to individual recipient pages from the index page.
  # Returns an array of { name:, url: } hashes.
  def extract_recipient_links(index_html, base_url: INDEX_URL)
    doc = Nokogiri::HTML(index_html)
    base_uri = URI.parse(base_url)

    links = []
    doc.css("a").each do |a|
      href = a["href"]
      text = a.text.strip
      next if href.nil? || text.empty?

      # Match links that point to individual MOH recipient pages
      if href.include?("medal-of-honor") && href != base_url && !href.end_with?("vietnam-war-medal-of-honor-recipients.html")
        full_url = if href.start_with?("http")
                     href
                   else
                     URI.join(base_uri, href).to_s
                   end
        links << { name: text, url: full_url } unless links.any? { |l| l[:url] == full_url }
      end
    end

    links
  end

  # Parse a single recipient citation page.
  # Returns a hash with :name, :rank, :unit, :date, :place, :citation, :source_url
  # or nil if parsing fails.
  def parse_citation(html, source_url: nil)
    doc = Nokogiri::HTML(html)

    # Try to extract structured data from the page
    # Navy pages typically have the citation in the main content area
    content = doc.css(".field-item, .body, article, .content, main").first
    return nil unless content

    text = content.text.strip
    return nil if text.empty?

    result = {
      source_url: source_url,
      raw_text: text
    }

    # Extract name from page title or heading
    title = doc.css("h1, .page-title, title").first
    result[:name] = title&.text&.strip

    # Extract date from citation text
    # Common patterns: "on 18 September 1966", "September 18, 1966", "18 September 1966"
    date = extract_date(text)
    result[:date] = date if date

    # Extract rank and unit from text
    rank_match = text.match(/(?:Private|Corporal|Sergeant|Lieutenant|Captain|Major|Colonel|General|Specialist|Lance Corporal|Gunnery Sergeant|Staff Sergeant|Private First Class|Hospital Corpsman)[^,.]*/i)
    result[:rank_info] = rank_match[0].strip if rank_match

    result[:citation] = extract_citation_text(text)

    result
  end

  # Convert a parsed citation into the event YAML format.
  def to_event(parsed)
    return nil unless parsed && parsed[:date]

    date = parsed[:date]
    name = parsed[:name]&.gsub(/\s*[-—]\s*Medal of Honor.*$/i, "")&.strip || "Unknown"
    citation_summary = summarize_citation(parsed[:citation] || parsed[:raw_text])

    {
      "month" => date.month,
      "day" => date.day,
      "year" => date.year,
      "title" => "#{name} earns Medal of Honor",
      "body" => "<p>#{citation_summary}</p>",
      "photo_url" => nil,
      "photo_alt" => nil,
      "references" => [
        {
          "label" => "Medal of Honor Citation — #{name}",
          "url" => parsed[:source_url] || ""
        }
      ]
    }
  end

  private

  def extract_date(text)
    # "18 September 1966" or "September 18, 1966" or "on 18 September 1966"
    months = "January|February|March|April|May|June|July|August|September|October|November|December"

    if (m = text.match(/(\d{1,2})\s+(#{months})\s+(\d{4})/i))
      Date.new(m[3].to_i, month_number(m[2]), m[1].to_i) rescue nil
    elsif (m = text.match(/(#{months})\s+(\d{1,2}),?\s+(\d{4})/i))
      Date.new(m[3].to_i, month_number(m[1]), m[2].to_i) rescue nil
    end
  end

  def month_number(name)
    Date::MONTHNAMES.index(name.capitalize)
  end

  def extract_citation_text(text)
    # Look for the actual citation, often starts with "For conspicuous gallantry"
    # or "The President of the United States"
    if (idx = text.index(/For conspicuous gallantry/i))
      text[idx..].split(/\n\n/).first&.strip
    elsif (idx = text.index(/distinguished himself/i))
      text[idx..].split(/\n\n/).first&.strip
    else
      nil
    end
  end

  def summarize_citation(text)
    return "" unless text

    # Take first two sentences as summary
    sentences = text.split(/(?<=[.!])\s+/)
    sentences[0..1].join(" ").strip
  end
end
