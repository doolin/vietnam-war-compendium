# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/this_day/archive/wayback"

RSpec.describe ThisDay::Archive::Wayback do
  def fetcher_returning(code:, body:)
    instance_double(ThisDay::Archive::Fetcher).tap do |f|
      allow(f).to receive(:fetch) do |url|
        ThisDay::Archive::Fetcher::Result.new(url: url, final_url: url, code: code, body: body,
                                              content_type: "text/plain", error: nil)
      end
    end
  end

  it "asks CDX for 200 captures only and returns the latest" do
    fetcher = fetcher_returning(code: 200, body: "20161123144448 http://old.test/a.pdf\n")
    capture = described_class.new(fetcher: fetcher).latest_capture("http://old.test/a.pdf")

    expect(fetcher).to have_received(:fetch).with(a_string_including("filter=statuscode%3A200", "limit=-1"))
    expect(capture.raw_url).to eq("https://web.archive.org/web/20161123144448id_/http://old.test/a.pdf")
    expect(capture.view_url).to eq("https://web.archive.org/web/20161123144448/http://old.test/a.pdf")
    expect(capture.captured_at).to eq("2016-11-23T14:44:48Z")
  end

  it "returns nil when CDX has no 200 capture" do
    expect(described_class.new(fetcher: fetcher_returning(code: 200, body: "")).latest_capture("http://x.test/"))
      .to be_nil
  end

  it "returns nil when CDX itself fails" do
    expect(described_class.new(fetcher: fetcher_returning(code: 429, body: "slow down")).latest_capture("http://x.test/"))
      .to be_nil
  end
end
