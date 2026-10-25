# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require_relative "../../../lib/this_day/archive/audit"

RSpec.describe ThisDay::Archive::Audit do
  let(:tmp) { Dir.mktmpdir }
  let(:events_dir) { File.join(tmp, "events").tap { |d| FileUtils.mkdir_p(d) } }
  let(:index) { ThisDay::Archive::Index.new(File.join(tmp, "index.yaml")) }
  let(:audit) { described_class.new(index: index, events_dir: events_dir) }

  after { FileUtils.rm_rf(tmp) }

  before do
    File.write(File.join(events_dir, "a.yaml"), [
      { "month" => 3, "day" => 2, "year" => 1965, "title" => "Rolling Thunder begins",
        "body" => "<p>x</p>",
        "references" => [
          { "label" => "Rolling Thunder 1965-1968, USAF", "url" => "https://ok.test/rt" },
          { "label" => "Some book by Author", "url" => "https://amazon.test/dp/1" },
          { "label" => "Pentagon Papers", "url" => "https://never.test/" }
        ] },
      { "month" => 1, "day" => 30, "year" => 1968, "title" => "Tet", "body" => "<p>y</p>",
        "references" => [{ "label" => "Tet Offensive overview", "url" => "https://ok.test/wrong" }] }
    ].to_yaml)

    index.upsert("url" => "https://ok.test/rt", "status" => "ok", "title" => "Rolling Thunder: USAF monograph")
    index.upsert("url" => "https://amazon.test/dp/1", "status" => "http-503", "note" => nil)
    index.upsert("url" => "https://ok.test/wrong", "status" => "ok", "title" => "Page Not Found")
  end

  it "lists every reference with its file and event title" do
    refs = audit.references
    expect(refs.size).to eq(4)
    expect(refs.first).to include(file: "a.yaml", title: "Rolling Thunder begins", url: "https://ok.test/rt")
  end

  it "lists unarchived urls" do
    expect(audit.unarchived_urls).to contain_exactly("https://amazon.test/dp/1", "https://never.test/")
  end

  it "reports missing, failed, and mismatched references" do
    kinds = audit.findings.to_h { |f| [f.url, f.kind] }
    expect(kinds).to eq(
      "https://amazon.test/dp/1" => :failed,
      "https://never.test/" => :missing,
      "https://ok.test/wrong" => :mismatch
    )
  end

  it "summarizes counts" do
    expect(audit.summary).to eq(references: 4, unique_urls: 4, archived: 2, missing: 1, failed: 1, mismatch: 1)
  end

  it "treats a label as matching when it shares a significant word with the title" do
    expect(audit.label_matches_title?("Rolling Thunder 1965", "Rolling Thunder: USAF monograph")).to be(true)
    expect(audit.label_matches_title?("Tet Offensive overview", "Page Not Found")).to be(false)
    expect(audit.label_matches_title?("The Vietnam War", "Vietnam War history")).to be(true)
  end
end
