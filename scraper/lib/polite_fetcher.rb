#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# PoliteFecher — fetch URLs with per-domain rate limiting
# =============================================================================
#
# Design principles:
#   - One request at a time per domain (never parallel within a domain)
#   - Multiple domains fetched in parallel via threads
#   - Configurable delay between same-domain requests (default 3s)
#   - Raw HTML cached locally — never re-fetches a cached page
#   - User-Agent identifies the project and provides contact
#
# Usage:
#   fetcher = PoliteFetcher.new(cache_dir: "scraper/cache", delay: 3)
#   html = fetcher.fetch("https://example.com/page1")
#   html = fetcher.fetch("https://example.com/page2")  # waits 3s first
#
#   # Parallel across domains:
#   results = fetcher.fetch_all([
#     "https://army.mil/page1",
#     "https://army.mil/page2",
#     "https://navy.mil/page1",
#   ])
#   # army.mil pages fetched sequentially with delay;
#   # navy.mil page fetched in parallel with army.mil

require "net/http"
require "uri"
require "fileutils"
require "digest"

class PoliteFetcher
  USER_AGENT = "VietnamWarCompendium/1.0 (historical research; one-time archive)"

  attr_reader :cache_dir, :delay

  def initialize(cache_dir:, delay: 3)
    @cache_dir = cache_dir
    @delay = delay
    @domain_timestamps = {}
    @mutex = Mutex.new
    FileUtils.mkdir_p(@cache_dir)
  end

  # Fetch a single URL. Returns the HTML body as a string.
  # Uses cache if available; otherwise fetches with rate limiting.
  def fetch(url)
    cached = read_cache(url)
    return cached if cached

    wait_for_domain(url)
    html = http_get(url)
    write_cache(url, html)
    html
  end

  # Fetch multiple URLs. Groups by domain, fetches each domain's URLs
  # sequentially with delay, but different domains run in parallel.
  # Returns a Hash of { url => html }.
  def fetch_all(urls)
    by_domain = urls.group_by { |u| URI.parse(u).host }
    results = {}
    results_mutex = Mutex.new

    threads = by_domain.map do |_domain, domain_urls|
      Thread.new do
        domain_urls.each do |url|
          html = fetch(url)
          results_mutex.synchronize { results[url] = html }
        end
      end
    end

    threads.each(&:join)
    results
  end

  # List all cached files for a given domain (or all if nil).
  def cached_urls(domain: nil)
    Dir.glob(File.join(@cache_dir, "*.html")).filter_map do |path|
      meta_path = path.sub(/\.html$/, ".meta")
      next unless File.exist?(meta_path)

      url = File.read(meta_path).strip
      if domain.nil? || URI.parse(url).host == domain
        { url: url, path: path }
      end
    end
  end

  private

  def cache_key(url)
    Digest::SHA256.hexdigest(url)[0, 16]
  end

  def cache_path(url)
    File.join(@cache_dir, "#{cache_key(url)}.html")
  end

  def meta_path(url)
    File.join(@cache_dir, "#{cache_key(url)}.meta")
  end

  def read_cache(url)
    path = cache_path(url)
    return nil unless File.exist?(path)

    $stderr.puts "  cache hit: #{url}"
    File.read(path)
  end

  def write_cache(url, html)
    File.write(cache_path(url), html)
    File.write(meta_path(url), url)
  end

  def wait_for_domain(url)
    domain = URI.parse(url).host
    @mutex.synchronize do
      last = @domain_timestamps[domain]
      if last
        elapsed = Time.now - last
        if elapsed < @delay
          sleep_time = @delay - elapsed
          $stderr.puts "  politeness delay: #{sleep_time.round(1)}s for #{domain}"
          sleep(sleep_time)
        end
      end
      @domain_timestamps[domain] = Time.now
    end
  end

  def http_get(url, redirect_limit: 5)
    raise "Too many redirects for #{url}" if redirect_limit == 0

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    if http.use_ssl?
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      cert_file = ENV["SSL_CERT_FILE"] || "/etc/ssl/cert.pem"
      http.ca_file = cert_file if File.exist?(cert_file)
    end
    http.open_timeout = 15
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = USER_AGENT
    request["Accept"] = "text/html"

    $stderr.puts "  fetching: #{url}"
    response = http.request(request)

    case response
    when Net::HTTPSuccess
      response.body
    when Net::HTTPRedirection
      location = response["location"]
      # Handle relative redirects
      location = URI.join(url, location).to_s unless location.start_with?("http")
      $stderr.puts "  redirect: #{location}"
      http_get(location, redirect_limit: redirect_limit - 1)
    else
      raise "HTTP #{response.code} for #{url}: #{response.message}"
    end
  end
end
