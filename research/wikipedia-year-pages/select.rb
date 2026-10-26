# frozen_string_literal: true

# For a month, list the days with no served event in this-day/data/events
# and, for each, the top four candidates from candidates.json for a writer
# to choose from. Rejected events do not count as coverage.
#
# Score: a cited URL (+3), a .gov/.mil URL (+2), entry length 200-1500
# characters (+2) or 120-200 (+1), under 80 (-2), year 1960-1973 (+1),
# a single-day label (+1).
#
#   ruby research/wikipedia-year-pages/select.rb 12 /tmp/out.json
require "yaml"
require "json"
require "date"
require "fileutils"

month = Integer(ARGV.fetch(0))
out = ARGV.fetch(1)
CANDIDATES = File.join(__dir__, "candidates.json")
EVENTS = File.expand_path("../../this-day/data/events", __dir__)

covered = Dir["#{EVENTS}/*.yaml"].flat_map { |f| YAML.safe_load_file(f, permitted_classes: [Date]) || [] }
                                .select { |e| e["month"] == month && e["status"] != "rejected" }
                                .map { |e| e["day"] }.uniq
days_in_month = Date.new(2000, month, -1).day
missing = (1..days_in_month).to_a - covered

cands = JSON.parse(File.read(CANDIDATES)).select { |c| c["month"] == month }

def score(c)
  s = 0
  s += 3 if c["refs"].any? { |r| r["url"].to_s.start_with?("http") }
  s += 2 if c["refs"].any? { |r| r["url"].to_s.match?(%r{\.(gov|mil)/}) }
  len = c["text"].to_s.length
  s += 2 if len.between?(200, 1500)
  s += 1 if len.between?(120, 200)
  s -= 2 if len < 80
  s += 1 if c["year"].between?(1960, 1973)
  s += 1 unless c["day_label"].to_s.match?(%r{[–-]|/})
  s
end

selection = missing.map do |day|
  top = cands.select { |c| c["day"] == day }.sort_by { |c| -score(c) }.first(4)
  { "day" => day, "candidates" => top.map { |c| c.merge("score" => score(c)) } }
end

FileUtils.mkdir_p(File.dirname(out))
File.write(out, JSON.pretty_generate("month" => month, "missing_days" => missing, "days" => selection))
puts "month #{month}: #{missing.size} uncovered days: #{missing.inspect}"
selection.each do |d|
  best = d["candidates"].first
  next puts(format("  %2d: no candidates", d["day"])) unless best

  puts format("  %2d: %d candidates; best %d (score %d, %d chars, %s)", d["day"], d["candidates"].size,
              best["year"], best["score"], best["text"].length, best["refs"].any? { |r| r["url"] } ? "has url" : "no url")
end
