# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "aws-sdk-s3"
require_relative "../../../lib/this_day/archive/archiver"

RSpec.describe ThisDay::Archive::Archiver do
  let(:tmp) { Dir.mktmpdir }
  let(:index) { ThisDay::Archive::Index.new(File.join(tmp, "index.yaml")) }
  let(:cache_dir) { File.join(tmp, "cache") }
  let(:s3_client) { instance_double(Aws::S3::Client, put_object: true) }
  let(:clock) { -> { Time.utc(2026, 10, 25, 18, 0, 0) } }
  let(:html) { "<html><head><title>  Rolling Thunder\n 1965 </title></head><body>x</body></html>" }

  after { FileUtils.rm_rf(tmp) }

  def fetcher_returning(code:, body:, content_type:, final_url: nil, error: nil)
    instance_double(ThisDay::Archive::Fetcher).tap do |f|
      allow(f).to receive(:fetch) do |url|
        ThisDay::Archive::Fetcher::Result.new(url: url, final_url: final_url || url, code: code,
                                              body: body, content_type: content_type, error: error)
      end
    end
  end

  def archiver(fetcher, s3: s3_client)
    described_class.new(index: index, fetcher: fetcher, cache_dir: cache_dir,
                        bucket: "bucket", prefix: "this-day/references", s3_client: s3, clock: clock)
  end

  it "caches, uploads, and indexes a successful HTML fetch" do
    url = "https://example.test/page"
    entry = archiver(fetcher_returning(code: 200, body: html, content_type: "text/html")).archive(url)

    expect(entry["status"]).to eq("ok")
    expect(entry["title"]).to eq("Rolling Thunder 1965")
    expect(entry["bytes"]).to eq(html.bytesize)
    expect(entry["sha256"]).to eq(Digest::SHA256.hexdigest(html))
    expect(entry["fetched_at"]).to eq("2026-10-25T18:00:00Z")
    expect(File.read(entry["cache_path"])).to eq(html)
    expect(File.read("#{entry['cache_path']}.url")).to eq(url)

    key = ThisDay::Archive::Index.url_key(url)
    expect(entry["s3_key"]).to eq("this-day/references/#{key}/#{entry['sha256']}.html")
    expect(s3_client).to have_received(:put_object)
      .with(hash_including(bucket: "bucket", key: entry["s3_key"], content_type: "text/html"))
    expect(index.archived?(url)).to be(true)
  end

  it "uses the pdf extension for PDFs and records no title" do
    entry = archiver(fetcher_returning(code: 200, body: "%PDF-1.4", content_type: "application/pdf"))
            .archive("https://example.test/doc")

    expect(entry["cache_path"]).to end_with(".pdf")
    expect(entry["title"]).to be_nil
  end

  it "records an HTTP failure without caching or uploading" do
    entry = archiver(fetcher_returning(code: 503, body: "busy", content_type: "text/html"))
            .archive("https://amazon.test/dp/1")

    expect(entry["status"]).to eq("http-503")
    expect(entry).not_to have_key("sha256")
    expect(Dir.exist?(cache_dir)).to be(false)
    expect(s3_client).not_to have_received(:put_object)
    expect(index.archived?("https://amazon.test/dp/1")).to be(false)
  end

  it "records a bot wall served with a 200 as not archived" do
    wall = "<html><head><title>Human Verification | Open Library</title></head><body>prove it</body></html>"
    entry = archiver(fetcher_returning(code: 200, body: wall, content_type: "text/html"))
            .archive("https://openlibrary.test/works/OL1W")

    expect(entry["status"]).to eq("bot-wall")
    expect(entry["title"]).to eq("Human Verification | Open Library")
    expect(entry).not_to have_key("sha256")
    expect(Dir.exist?(cache_dir)).to be(false)
    expect(s3_client).not_to have_received(:put_object)
    expect(index.archived?("https://openlibrary.test/works/OL1W")).to be(false)
  end

  it "treats Amazon's generic robot page title as a bot wall" do
    wall = "<html><head><title>Amazon.com</title></head><body></body></html>"
    entry = archiver(fetcher_returning(code: 200, body: wall, content_type: "text/html"))
            .archive("https://amazon.test/dp/1")
    expect(entry["status"]).to eq("bot-wall")
  end

  it "records a transport error with its note" do
    entry = archiver(fetcher_returning(code: 0, body: nil, content_type: nil, error: "SocketError: boom"))
            .archive("https://down.test/")

    expect(entry["status"]).to eq("error")
    expect(entry["note"]).to eq("SocketError: boom")
  end

  it "skips upload when no S3 client is given" do
    entry = archiver(fetcher_returning(code: 200, body: html, content_type: "text/html"), s3: nil)
            .archive("https://example.test/page")

    expect(entry["status"]).to eq("ok")
    expect(entry["s3_key"]).to be_nil
  end

  describe "Wayback fallback" do
    let(:dead) { "http://old.test/report.pdf" }
    let(:capture) { ThisDay::Archive::Wayback::Capture.new(timestamp: "20161123144448", original: dead) }
    let(:wayback) { instance_double(ThisDay::Archive::Wayback, latest_capture: capture) }

    # 404 for the live URL, the PDF for the Wayback raw URL.
    let(:fetcher) do
      instance_double(ThisDay::Archive::Fetcher).tap do |f|
        allow(f).to receive(:fetch) do |url|
          live = url == dead
          ThisDay::Archive::Fetcher::Result.new(url: url, final_url: url, code: live ? 404 : 200,
                                                body: live ? "gone" : "%PDF-1.4",
                                                content_type: live ? "text/html" : "application/pdf", error: nil)
        end
      end
    end

    def wayback_archiver(wb)
      described_class.new(index: index, fetcher: fetcher, wayback: wb, cache_dir: cache_dir,
                          bucket: "bucket", s3_client: s3_client, clock: clock)
    end

    it "archives the latest 200 capture under the original URL when the live fetch fails" do
      entry = wayback_archiver(wayback).archive(dead)

      expect(entry["status"]).to eq("ok")
      expect(entry["url"]).to eq(dead)
      expect(entry["via"]).to eq("wayback")
      expect(entry["live_status"]).to eq("http-404")
      expect(entry["snapshot_url"]).to eq("https://web.archive.org/web/20161123144448/#{dead}")
      expect(entry["captured_at"]).to eq("2016-11-23T14:44:48Z")
      expect(File.read(entry["cache_path"])).to eq("%PDF-1.4")
      expect(entry["s3_key"]).to start_with("this-day/references/#{ThisDay::Archive::Index.url_key(dead)}/")
      expect(index.archived?(dead)).to be(true)
    end

    it "keeps the live failure when there is no capture" do
      entry = wayback_archiver(instance_double(ThisDay::Archive::Wayback, latest_capture: nil)).archive(dead)

      expect(entry["status"]).to eq("http-404")
      expect(entry).not_to have_key("via")
    end

    it "does not consult Wayback when the live fetch succeeds" do
      live_ok = fetcher_returning(code: 200, body: html, content_type: "text/html")
      described_class.new(index: index, fetcher: live_ok, wayback: wayback, cache_dir: cache_dir).archive(dead)

      expect(wayback).not_to have_received(:latest_capture)
    end
  end

  it "replaces an earlier entry so no field from the old fetch survives" do
    url = "https://flaky.test/"
    archiver(fetcher_returning(code: 0, body: nil, content_type: nil, error: "Net::OpenTimeout")).archive(url)
    archiver(fetcher_returning(code: 200, body: html, content_type: "text/html")).archive(url)

    expect(index[url]["status"]).to eq("ok")
    expect(index[url]).not_to have_key("note")
  end

  it "persists the index to disk sorted by url" do
    a = archiver(fetcher_returning(code: 200, body: html, content_type: "text/html"))
    a.archive("https://z.test/")
    a.archive("https://a.test/")
    index.save

    reloaded = ThisDay::Archive::Index.new(index.path)
    expect(reloaded.entries.map { |e| e["url"] }).to eq(["https://a.test/", "https://z.test/"])
    expect(reloaded.archived?("https://z.test/")).to be(true)
  end
end
