#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# fetch.rb — CLI for polite web fetching
# =============================================================================
#
# Usage:
#   ruby scraper/fetch.rb URL [URL ...]          # fetch and cache
#   ruby scraper/fetch.rb --list [DOMAIN]        # list cached pages
#   ruby scraper/fetch.rb --delay 5 URL [URL ...]  # custom delay
#
# Fetches URLs politely (per-domain rate limiting) and caches raw HTML
# in scraper/cache/. Multiple domains are fetched in parallel; requests
# to the same domain are sequential with a configurable delay.

require_relative "lib/polite_fetcher"

CACHE_DIR = File.join(__dir__, "cache")

delay = 3
urls = []
list_mode = false
list_domain = nil

args = ARGV.dup
while (arg = args.shift)
  case arg
  when "--delay"
    delay = args.shift.to_i
  when "--list"
    list_mode = true
    list_domain = args.shift unless args.empty? || args.first.start_with?("-")
  else
    urls << arg
  end
end

fetcher = PoliteFetcher.new(cache_dir: CACHE_DIR, delay: delay)

if list_mode
  entries = fetcher.cached_urls(domain: list_domain)
  if entries.empty?
    puts "No cached pages#{list_domain ? " for #{list_domain}" : ""}."
  else
    entries.each { |e| puts "#{e[:path]}  #{e[:url]}" }
  end
  exit
end

if urls.empty?
  $stderr.puts "Usage: ruby scraper/fetch.rb [--delay N] URL [URL ...]"
  $stderr.puts "       ruby scraper/fetch.rb --list [DOMAIN]"
  exit 1
end

results = fetcher.fetch_all(urls)
puts "Fetched #{results.size} page(s)."
results.each do |url, html|
  puts "  #{url} (#{html.bytesize} bytes)"
end
