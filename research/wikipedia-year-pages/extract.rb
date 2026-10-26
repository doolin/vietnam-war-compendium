#!/usr/bin/env ruby
# frozen_string_literal: true

# Fetch Wikipedia "YEAR in the Vietnam War" pages (1955-1975) via the
# MediaWiki API, cache the raw wikitext in cache/, and extract every
# entry with a day-level date as a candidate for "This Day in Viet Nam".
#
# Pages already in cache/ are not fetched again, so candidates.json is
# reproducible from the committed cache; each candidate carries the
# revision id and a permalink to that revision. Delete a cache file to
# pick up a newer revision.
#
# Writes candidates.json (sorted by month, day, year) and report.json
# (per-page revision and counts, plus entries whose label gives no day).
#
# Usage: ruby research/wikipedia-year-pages/extract.rb [--fetch-only]

require 'json'
require 'net/http'
require 'uri'
require 'fileutils'
require 'cgi'
require 'date'

DIR = __dir__
CACHE_DIR = File.join(DIR, 'cache')
OUT_FILE = File.join(DIR, 'candidates.json')
REPORT_FILE = File.join(DIR, 'report.json')
API = 'https://en.wikipedia.org/w/api.php'
USER_AGENT = 'VietnamWarCompendium/1.0 (historical research; https://clubstraylight.com/this-day-in-vietnam-war)'
YEARS = (1955..1975).to_a
MONTHS = {
  'January' => 1, 'February' => 2, 'March' => 3, 'April' => 4,
  'May' => 5, 'June' => 6, 'July' => 7, 'August' => 8,
  'September' => 9, 'October' => 10, 'November' => 11, 'December' => 12
}.freeze
TARGET_MONTHS = (1..12).to_a.freeze
MONTH_RE = MONTHS.keys.join('|')

FileUtils.mkdir_p(CACHE_DIR)

$last_request = nil

def polite_get(params)
  if $last_request
    wait = 2.0 - (Time.now - $last_request)
    sleep(wait) if wait.positive?
  end
  uri = URI(API)
  uri.query = URI.encode_www_form(params)
  req = Net::HTTP::Get.new(uri)
  req['User-Agent'] = USER_AGENT
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
  $last_request = Time.now
  raise "HTTP #{res.code} for #{uri}" unless res.is_a?(Net::HTTPSuccess)

  JSON.parse(res.body)
end

def cache_path(page)
  File.join(CACHE_DIR, "#{page}.json")
end

# Returns the cached API response hash (parse result or error).
def fetch_page(page)
  path = cache_path(page)
  return JSON.parse(File.read(path)) if File.exist?(path)

  data = polite_get(action: 'parse', page: page, prop: 'wikitext|revid',
                    redirects: 1, format: 'json', formatversion: 2)
  File.write(path, JSON.pretty_generate(data))
  data
end

# ---------- wikitext helpers ----------

# Find matching closing "}}" for a template starting at idx (pointing at "{{").
def template_end(str, idx)
  depth = 0
  i = idx
  while i < str.length - 1
    if str[i, 2] == '{{'
      depth += 1
      i += 2
    elsif str[i, 2] == '}}'
      depth -= 1
      i += 2
      return i if depth.zero?
    else
      i += 1
    end
  end
  str.length
end

# Remove all {{...}} templates (nesting-aware), optionally keeping some.
def strip_templates(str)
  out = +''
  i = 0
  while i < str.length
    if str[i, 2] == '{{'
      j = template_end(str, i)
      out << template_text(str[i...j])
      i = j
    else
      out << str[i]
      i += 1
    end
  end
  out
end

# Plain-text rendering for a small set of inline templates; others vanish.
def template_text(tpl)
  inner = tpl[2..-3].to_s
  parts = split_params(inner)
  name = parts.first.to_s.strip.downcase
  args = parts[1..].to_a.reject { |p| p =~ /\A\s*\w+\s*=/ }.map(&:strip)
  case name
  when 'convert', 'cvt'
    [args[0], args[1]].compact.join(' ')
  when 'lang', 'lang-vi', 'transl'
    args.last.to_s
  when 'nowrap', 'nobr', 'small', 'sic', 'em', 'i', 'big'
    args.join(' ')
  when 'ndash', '–'
    '–'
  when 'mdash'
    '—'
  when 'nbsp'
    ' '
  when 'snd'
    ' – '
  when 'abbr'
    args[0].to_s
  when 'usd', 'us$'
    "US$#{args[0]}"
  when 'circa', 'c.'
    "c. #{args[0]}"
  when 'flagicon', 'flag', 'flagcountry'
    name == 'flagicon' ? '' : args[0].to_s
  when 'vtl', 'ill'
    args[0].to_s
  else
    ''
  end
end

# Split template inner text on top-level pipes.
def split_params(inner)
  parts = []
  buf = +''
  depth_t = 0
  depth_l = 0
  i = 0
  while i < inner.length
    two = inner[i, 2]
    if two == '{{'
      depth_t += 1; buf << two; i += 2; next
    elsif two == '}}'
      depth_t -= 1; buf << two; i += 2; next
    elsif two == '[['
      depth_l += 1; buf << two; i += 2; next
    elsif two == ']]'
      depth_l -= 1; buf << two; i += 2; next
    end
    if inner[i] == '|' && depth_t.zero? && depth_l.zero?
      parts << buf
      buf = +''
    else
      buf << inner[i]
    end
    i += 1
  end
  parts << buf
  parts
end

def wiki_to_plain(str)
  s = str.dup
  s.gsub!(/<!--.*?-->/m, '')
  s.gsub!(%r{<ref[^>/]*/>}i, '')
  s.gsub!(%r{<ref[^>]*>.*?</ref>}im, '')
  s = strip_templates(s)
  # Files / images
  s.gsub!(/\[\[(?:File|Image):[^\[\]]*(?:\[\[[^\]]*\]\][^\[\]]*)*\]\]/i, '')
  # Internal links
  s.gsub!(/\[\[([^\]|]*)\|([^\]]*)\]\]/) { Regexp.last_match(2) }
  s.gsub!(/\[\[([^\]]*)\]\]/) { Regexp.last_match(1) }
  # External links
  s.gsub!(%r{\[(?:https?:)?//\S+\s+([^\]]*)\]}) { Regexp.last_match(1) }
  s.gsub!(%r{\[(?:https?:)?//\S+\]}, '')
  s.gsub!(/'{2,}/, '')
  s.gsub!(%r{<br\s*/?>}i, ' ')
  s.gsub!(%r{</?[a-z][^>]*>}i, '')
  s = CGI.unescapeHTML(s)
  s.gsub!('&nbsp;', ' ')
  s.gsub!(/\[\d+\]/, '')
  s.gsub!(/[ \t]+/, ' ')
  s.gsub!(/ +([,.;:])/, '\1')
  s.split(/\n+/).map(&:strip).reject(&:empty?).join("\n\n")
end

CITE_FIELDS = %w[title work website newspaper journal publisher author last first
                 author1 last1 first1 date year url archive-url access-date page pages].freeze

def parse_ref(raw_inner, raw_full, named_refs)
  ref = { 'raw' => raw_full }
  body = raw_inner.to_s
  if body.strip.empty?
    name = ref_name(raw_full[/<ref([^>]*)>/i, 1].to_s)
    ref['name'] = name if name
    body = named_refs[name].to_s if name && named_refs[name]
    ref['resolved_from_name'] = true if name && named_refs[name]
  end
  url = body[/https?:\/\/[^\s|\]}<]+/]&.sub(/[.,;:)'"]+\z/, '')
  ref['url'] = url if url
  tpl = body[/\{\{\s*(cite[^|}]*)/i, 1]
  if tpl
    ref['template'] = tpl.strip
    i = body.index('{{')
    inner = body[i + 2...template_end(body, i) - 2]
    split_params(inner)[1..].to_a.each do |p|
      k, v = p.split('=', 2)
      next unless v

      k = k.strip.downcase
      next unless CITE_FIELDS.include?(k)

      ref[k] = wiki_to_plain(v).strip
    end
  else
    plain = wiki_to_plain(body).strip
    ref['text'] = plain unless plain.empty?
  end
  ref
end

# Collect bodies of named refs so <ref name="x"/> reuses can be resolved.
def named_ref_bodies(wikitext)
  h = {}
  # Opening tags only: attrs must not end in "/" (self-closing reuse).
  wikitext.scan(%r{<ref\s+([^>]*[^/>])\s*>(.*?)</ref>}im) do |attrs, body|
    name = ref_name(attrs)
    h[name] ||= body if name
  end
  h
end

def ref_name(attrs)
  n = attrs[/name\s*=\s*"([^"]+)"/i, 1] || attrs[/name\s*=\s*'([^']+)'/i, 1] ||
      attrs[/name\s*=\s*([^\s"'\/>]+)/i, 1]
  n&.strip
end

def extract_refs(chunk, named)
  refs = []
  chunk.scan(%r{(<ref(?:\s[^>]*)?/>)|(<ref(?:\s[^>]*)?>(.*?)</ref>)}im) do |self_closing, full, inner|
    refs << if self_closing
              parse_ref('', self_closing, named)
            else
              parse_ref(inner, full, named)
            end
  end
  refs
end

# ---------- page parsing ----------

# Match a date label line; returns [label, first_day, month_name] or nil.
# Label text as written (plain), from a ";label" line.
def label_text(line)
  wiki_to_plain(line.sub(/\A;/, '')).strip.sub(/[\s:]+\z/, '')
end

# Parse a label; returns [first_day, month_name] or nil when no day is given
# (e.g. "October", "October–December", "late July").
def date_label(label, current_month_name)
  t = label.gsub(/\s*[-—–]\s*/, '–').gsub(/\s+to\s+/, '–').gsub(%r{(\d)/(\d)}, '\1–\2')
  # "3 October", "10–12 October", "12 October–31 January 1969", "27/8 October"
  m = t.match(/\A(\d{1,2})(?:–\d{1,2})?\s+(#{MONTH_RE})\b/)
  return [m[1].to_i, m[2]] if m
  # "30 September–2 October" (range starting in another month)
  m = t.match(/\A(\d{1,2})\s+(#{MONTH_RE})/)
  return [m[1].to_i, m[2]] if m
  # "November 1", "October 3–5"
  m = t.match(/\A(#{MONTH_RE})\s+(\d{1,2})\b/)
  return [m[2].to_i, m[1]] if m
  # Day-only within a month section: "28–31", "3"
  m = t.match(/\A(\d{1,2})(?:–\d{1,2})?\z/)
  return [m[1].to_i, current_month_name] if m && current_month_name

  nil
end

def heading_month(line)
  m = line.match(/\A(=+)\s*(.*?)\s*\1\s*\z/)
  return nil unless m

  title = wiki_to_plain(m[2]).strip
  mm = title.match(/\A(#{MONTH_RE})(?:\s+\d{4})?\z/)
  [m[1].length, mm ? MONTHS[mm[1]] : nil, title]
end

def parse_page(wikitext, year, page, revid, undated)
  named = named_ref_bodies(wikitext)
  lines = wikitext.split("\n")
  candidates = []
  current_month = nil
  current_month_level = nil
  entry = nil

  flush = lambda do
    next unless entry

    raw = entry[:lines].join("\n")
    text = wiki_to_plain(raw)
    if entry[:day].nil?
      if TARGET_MONTHS.include?(entry[:month])
        undated << { 'year' => year, 'section_month' => entry[:month], 'day_label' => entry[:label],
                     'text' => text[0, 200] }
      end
    elsif TARGET_MONTHS.include?(entry[:month])
      candidates << {
        'year' => year, 'month' => entry[:month], 'day' => entry[:day],
        'day_label' => entry[:label], 'text' => text,
        'refs' => extract_refs(raw, named),
        'page' => page, 'revid' => revid,
        'permalink' => "https://en.wikipedia.org/w/index.php?title=#{page}&oldid=#{revid}"
      }
    end
    entry = nil
  end

  lines.each do |line|
    if (h = heading_month(line))
      level, month, _title = h
      if month
        flush.call
        current_month = month
        current_month_level = level
        next
      elsif current_month_level && level <= current_month_level
        flush.call
        current_month = nil
        current_month_level = nil
        next
      else
        # Sub-heading inside a month (e.g. "Tet Offensive"): keep going
        next
      end
    end
    next unless current_month

    stripped = line.strip
    # Skip images at line level
    next if stripped =~ /\A\[\[(?:File|Image):/i

    if stripped.start_with?(';')
      flush.call
      label = label_text(stripped)
      dl = date_label(label, MONTHS.key(current_month))
      entry = if dl
                { label: label, day: dl[0], month: MONTHS[dl[1]], lines: [] }
              else
                { label: label, day: nil, month: current_month, lines: [] }
              end
      next
    end
    entry[:lines] << line if entry
  end
  flush.call
  candidates
end

# ---------- main ----------

report = []
all = []
undated = []
YEARS.each do |year|
  page = "#{year}_in_the_Vietnam_War"
  data = fetch_page(page)
  if data['error']
    report << { 'year' => year, 'page' => page, 'status' => 'missing', 'error' => data['error']['code'] }
    next
  end
  parse = data['parse']
  title = parse['title'].tr(' ', '_')
  revid = parse['revid']
  wikitext = parse['wikitext'].is_a?(Hash) ? parse['wikitext']['*'] : parse['wikitext']
  next if ARGV.include?('--fetch-only')

  cands = parse_page(wikitext, year, title, revid, undated)
  all.concat(cands)
  report << { 'year' => year, 'page' => title, 'requested' => page, 'revid' => revid,
              'redirected' => title != page,
              'by_month' => TARGET_MONTHS.to_h { |m| [m, cands.count { |c| c['month'] == m }] } }
end
exit if ARGV.include?('--fetch-only')

all.sort_by! { |c| [c['month'], c['day'], c['year']] }
File.write(OUT_FILE, JSON.pretty_generate(all))
File.write(REPORT_FILE, JSON.pretty_generate('pages' => report, 'undated_labels' => undated))

puts 'Pages (candidates per month, Jan..Dec):'
report.each do |r|
  if r['status'] == 'missing'
    puts format('  %d  MISSING (%s)', r['year'], r['error'])
  else
    puts format('  %d  rev %-10s %s%s', r['year'], r['revid'], r['by_month'].values.map { |n| format('%3d', n) }.join,
                r['redirected'] ? "  (title: #{r['page']})" : '')
  end
end

puts "\nDays with no candidate:"
TARGET_MONTHS.each do |m|
  ndays = Date.new(2000, m, -1).day
  bare = (1..ndays).reject { |d| all.any? { |c| c['month'] == m && c['day'] == d } }
  puts format('  %-9s %3d candidates; none on %s', MONTHS.key(m), all.count { |c| c['month'] == m },
              bare.empty? ? '-' : bare.join(', '))
end

with_url = all.count { |c| c['refs'].any? { |r| r['url'] } }
puts "\nCandidates: #{all.size}; with >=1 ref URL: #{with_url}; with no refs: #{all.count { |c| c['refs'].empty? }}"
puts "Labels with no day (not candidates): #{undated.size}"
empty = all.select { |c| c['text'].strip.empty? }
puts "Candidates with empty text: #{empty.size} #{empty.map { |c| "#{c['year']} #{c['day_label']}" }.first(10)}"
