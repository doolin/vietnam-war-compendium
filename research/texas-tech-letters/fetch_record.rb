# frozen_string_literal: true

# Fetch Virtual Vietnam Archive catalog records (vva.vietnam.ttu.edu) and
# keep each one: raw HTML under records/, and the fields a later pass needs
# (title, item number, collection, dates, citation, permalink) in
# records.yaml.
#
# The host times out on about one request in three, so each record is
# tried up to three times. A record whose HTML is already saved is parsed
# from the saved copy, not fetched again.
#
#   ruby research/texas-tech-letters/fetch_record.rb resources/2366 digital_objects/407268
#   ruby research/texas-tech-letters/fetch_record.rb --reparse
require "yaml"
require "cgi"
require "fileutils"
require_relative "../../this-day/lib/this_day/archive/fetcher"

BASE = "https://vva.vietnam.ttu.edu/repositories/2/"
DIR = __dir__
INDEX = File.join(DIR, "records.yaml")
FileUtils.mkdir_p(File.join(DIR, "records"))

def text(s) = s && CGI.unescapeHTML(s.gsub(/<[^>]+>/, " ")).gsub(/\s+/, " ").strip

# The record's fields are <dt>label</dt><dd>value</dd> pairs.
def parse(path, html, fetched_at)
  fields = html.scan(%r{<dt[^>]*>(.*?)</dt>\s*<dd[^>]*>(.*?)</dd>}m).to_h { |k, v| [text(k), text(v)] }
  {
    "url" => BASE + path,
    "title" => text(html[%r{<li class="breadcrumb-item active"[^>]*>(.*?)</li>}m, 1]),
    "item_number" => html[/Document Item Number:\s*(\d+)/, 1],
    "fields" => fields,
    "permalink" => html[%r{https://www\.vietnam\.ttu\.edu/virtualarchive/items\.php\?item=\d+}],
    # The scan itself; absent for copyrighted items (Reading Room only).
    "file_urls" => html.scan(%r{href='(https://vva\.vietnam\.ttu\.edu/images\.php\?img=[^'&]+)'}).flatten.uniq,
    "fetched_at" => fetched_at,
    "html" => "records/#{path.tr('/', '-')}.html"
  }.compact
end

records = File.exist?(INDEX) ? YAML.safe_load_file(INDEX) || {} : {}
paths = ARGV == ["--reparse"] ? records.keys : ARGV
fetcher = ThisDay::Archive::Fetcher.new(delay: 5)

paths.each do |path|
  file = File.join(DIR, "records", "#{path.tr('/', '-')}.html")
  if File.exist?(file)
    html = File.read(file)
    fetched_at = records.dig(path, "fetched_at") || File.mtime(file).utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  else
    result = nil
    3.times do
      result = fetcher.fetch(BASE + path)
      break if result.ok?
    end
    next puts("#{path}: #{result.code} #{result.error}") unless result.ok?

    html = result.body.to_s.encode("UTF-8", invalid: :replace, undef: :replace)
    next puts("#{path}: CAPTCHA page, not saved") if html.include?("User validation required")

    File.write(file, html)
    fetched_at = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  end
  records[path] = parse(path, html, fetched_at)
  File.write(INDEX, records.sort.to_h.to_yaml)
  puts "#{path}: #{records[path]['title']}"
end
