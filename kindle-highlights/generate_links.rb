#!/usr/bin/env ruby

# =============================================================================
# generate_links.rb — Fill kindle:// URLs in highlight YAML from ASIN + location
# =============================================================================
#
# Usage:
#   ruby generate_links.rb sog-kontum.yaml
#   ruby generate_links.rb --all
#
# Reads the YAML, fills kindle_url for each highlight using book.asin + location.
# Writes back in-place. Skips files with no ASIN set.
#
# Note: The kindle:// URL scheme reportedly does not navigate to a specific
# location on iOS (only opens the book). macOS/Android behavior may differ.

require "yaml"

def kindle_url(asin, location)
  return "" if asin.to_s.empty? || location.nil?
  "kindle://book?action=open&asin=#{asin}&location=#{location}"
end

def main
  files = []

  if ARGV.delete("--all")
    dir = File.dirname(__FILE__)
    files = Dir.glob(File.join(dir, "*.yaml")).reject { |f| f.end_with?(".yaml.new") }
  else
    files = ARGV.dup
  end

  if files.empty?
    warn "Usage: ruby generate_links.rb <file.yaml> [...]"
    warn "       ruby generate_links.rb --all"
    exit 1
  end

  files.each do |yaml_path|
    unless File.exist?(yaml_path)
      alt = File.join(File.dirname(__FILE__), yaml_path)
      yaml_path = alt if File.exist?(alt)
    end

    unless File.exist?(yaml_path)
      warn "File not found: #{yaml_path}"
      next
    end

    data = YAML.load_file(yaml_path)
    asin = data.dig("book", "asin").to_s

    if asin.empty?
      puts "#{File.basename(yaml_path)}: no ASIN set — skipping"
      next
    end

    count = 0
    (data["highlights"] || []).each do |h|
      url = kindle_url(asin, h["location"])
      unless url.empty?
        h["kindle_url"] = url
        count += 1
      end
    end

    File.write(yaml_path, data.to_yaml)
    puts "#{File.basename(yaml_path)}: updated #{count} kindle URLs (ASIN: #{asin})"
  end
end

main
