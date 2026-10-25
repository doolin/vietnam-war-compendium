# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/this_day/archive/fetcher"

RSpec.describe ThisDay::Archive::Fetcher do
  let(:sleeps) { [] }
  let(:sleeper) { ->(s) { sleeps << s } }

  def fetcher_with(responses)
    calls = []
    http = lambda do |url|
      calls << url
      responses.fetch(url)
    end
    [described_class.new(delay: 2, http: http, sleeper: sleeper), calls]
  end

  it "returns body, code, and content type for a 200" do
    fetcher, = fetcher_with("https://a.test/p" => ["200", { "content-type" => "text/html; charset=utf-8" }, "<html>"])
    result = fetcher.fetch("https://a.test/p")

    expect(result).to be_ok
    expect(result.code).to eq(200)
    expect(result.body).to eq("<html>")
    expect(result.content_type).to eq("text/html")
    expect(result.final_url).to eq("https://a.test/p")
  end

  it "follows redirects and reports the final URL" do
    fetcher, calls = fetcher_with(
      "https://a.test/old" => ["301", { "location" => "/new" }, ""],
      "https://a.test/new" => ["200", { "content-type" => "application/pdf" }, "%PDF"]
    )
    result = fetcher.fetch("https://a.test/old")

    expect(calls).to eq(["https://a.test/old", "https://a.test/new"])
    expect(result.url).to eq("https://a.test/old")
    expect(result.final_url).to eq("https://a.test/new")
    expect(result.content_type).to eq("application/pdf")
  end

  it "returns a non-ok result for HTTP errors without raising" do
    fetcher, = fetcher_with("https://a.test/gone" => ["404", {}, "nope"])
    result = fetcher.fetch("https://a.test/gone")

    expect(result).not_to be_ok
    expect(result.code).to eq(404)
    expect(result.error).to be_nil
  end

  it "captures exceptions as an error result" do
    http = ->(_url) { raise Errno::ECONNREFUSED }
    fetcher = described_class.new(delay: 0, http: http, sleeper: sleeper)
    result = fetcher.fetch("https://down.test/")

    expect(result).not_to be_ok
    expect(result.code).to eq(0)
    expect(result.error).to match(/ECONNREFUSED/)
  end

  it "sleeps between requests to the same host but not across hosts" do
    fetcher, = fetcher_with(
      "https://a.test/1" => ["200", {}, "1"],
      "https://a.test/2" => ["200", {}, "2"],
      "https://b.test/1" => ["200", {}, "3"]
    )
    fetcher.fetch("https://a.test/1")
    fetcher.fetch("https://b.test/1")
    expect(sleeps).to be_empty

    fetcher.fetch("https://a.test/2")
    expect(sleeps.size).to eq(1)
    expect(sleeps.first).to be > 0
  end

  it "gives up after too many redirects" do
    responses = Hash.new(["302", { "location" => "https://a.test/loop" }, ""])
    http = ->(url) { responses[url] }
    fetcher = described_class.new(delay: 0, http: http, sleeper: sleeper)
    result = fetcher.fetch("https://a.test/loop")

    expect(result).not_to be_ok
    expect(result.error).to eq("too many redirects")
  end
end
