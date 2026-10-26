# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/this_day/database"

RSpec.describe ThisDay::Database do
  let(:db_path) { TestDatabaseHelper::TEST_DB_PATH }

  before(:all) do
    db = TestDatabaseHelper.build_test_db

    TestDatabaseHelper.seed_event(
      db,
      month: 11, day: 9, year: 1965,
      title: "Battle of Ia Drang begins",
      body: "<p>The first major engagement between US Army troops and PAVN forces.</p>",
      references: [
        { label: "We Were Soldiers Once... and Young", url: "https://example.com/ia-drang" }
      ]
    )

    TestDatabaseHelper.seed_event(
      db,
      month: 11, day: 9, year: 1967,
      title: "Another November 9 event",
      body: "<p>A second event for the same date in a different year.</p>",
      photo_url: "https://example.com/photo.jpg",
      photo_alt: "Historical photo",
      references: [
        { label: "Reference A", url: "https://example.com/a" },
        { label: "Reference B", url: "https://example.com/b" }
      ]
    )

    TestDatabaseHelper.seed_event(
      db,
      month: 11, day: 20, year: 1969,
      title: "Rejected November event",
      body: "<p>Should never be served.</p>",
      status: "rejected"
    )

    TestDatabaseHelper.seed_event(db, month: 2, day: 14, year: 1966, title: "Reviewed February event",
                                      body: "<p>Approved.</p>")
    3.times do |i|
      TestDatabaseHelper.seed_event(db, month: 2, day: 14, year: 1967 + i, title: "Draft February event #{i}",
                                        body: "<p>Draft.</p>", status: "draft")
    end

    TestDatabaseHelper.seed_event(
      db,
      month: 11, day: 3, year: 1967,
      title: "Draft November event",
      body: "<p>Awaiting review.</p>",
      status: "draft",
      source_text: "Verbatim excerpt the body was written from.",
      source_file: "october-november-drafts.yaml",
      summarized_by: "Claude Fable 5.1",
      summarized_at: "2026-10-25T19:00:00Z"
    )

    TestDatabaseHelper.seed_event(
      db,
      month: 1, day: 30, year: 1968,
      title: "Tet Offensive begins",
      body: "<p>The Tet Offensive launched across South Vietnam.</p>",
      references: [
        { label: "Tet! by Don Oberdorfer", url: "https://example.com/tet",
          archive_status: "ok", archived_at: "2026-10-25T18:02:11Z" },
        { label: "The Pentagon Papers", url: "https://example.com/papers", archive_status: "http-404" },
        { label: "Vietnam: A History", url: "https://example.com/history" }
      ]
    )

    db.close
  end

  subject(:database) { described_class.new(db_path) }

  after { database.close }

  describe "#event_for_date" do
    it "returns an event matching month and day" do
      event = database.event_for_date(1, 30)
      expect(event).not_to be_nil
      expect(event.title).to eq("Tet Offensive begins")
      expect(event.month).to eq(1)
      expect(event.day).to eq(30)
      expect(event.year).to eq(1968)
    end

    it "returns nil when no event exists for the date" do
      event = database.event_for_date(6, 15)
      expect(event).to be_nil
    end

    it "loads references for the event" do
      event = database.event_for_date(1, 30)
      expect(event.references.length).to eq(3)
      expect(event.references.first.label).to eq("Tet! by Don Oberdorfer")
      expect(event.references.first.url).to eq("https://example.com/tet")
    end

    it "exposes archive status on references" do
      refs = database.event_for_date(1, 30).references
      expect(refs[0]).to be_archived
      expect(refs[0].archived_on).to eq("2026-10-25")
      expect(refs[1]).not_to be_archived
      expect(refs[1].archive_status).to eq("http-404")
      expect(refs[2]).not_to be_archived
      expect(refs[2].archived_on).to be_nil
    end

    it "returns one of multiple events for the same date" do
      event = database.event_for_date(11, 9)
      expect(event).not_to be_nil
      expect([1965, 1967]).to include(event.year)
    end

    it "includes photo data when present" do
      # Keep sampling until we get the 1967 event, or test both
      events = 20.times.map { database.event_for_date(11, 9) }
      photo_event = events.find { |e| e.year == 1967 }

      if photo_event
        expect(photo_event.photo_url).to eq("https://example.com/photo.jpg")
        expect(photo_event.photo_alt).to eq("Historical photo")
      end
    end

    it "has nil photo fields when no photo exists" do
      event = database.event_for_date(1, 30)
      expect(event.photo_url).to be_nil
      expect(event.photo_alt).to be_nil
    end

    it "never serves a rejected event" do
      expect(database.event_for_date(11, 20)).to be_nil
    end

    it "never serves a draft" do
      expect(database.event_for_date(11, 3)).to be_nil
    end

    it "chooses only among reviewed events when a date also has drafts" do
      titles = Array.new(20) { database.event_for_date(2, 14).title }.uniq
      expect(titles).to eq(["Reviewed February event"])
    end

    it "has no credit for legacy unattributed summaries" do
      expect(database.event_for_date(1, 30).credit).to be_nil
    end
  end

  describe "#events_for_month" do
    it "returns every event in the month, drafts and rejected included, ordered by day then year" do
      events = database.events_for_month(11)
      expect(events.map { |e| [e.day, e.year, e.status] }).to eq(
        [[3, 1967, "draft"], [9, 1965, "approved"], [9, 1967, "approved"], [20, 1969, "rejected"]]
      )
      draft = events.first
      expect(draft).to be_draft
      expect(draft.source_text).to eq("Verbatim excerpt the body was written from.")
      expect(draft.source_file).to eq("october-november-drafts.yaml")
      expect(draft.credit).to eq("Summary by Claude Fable 5.1, 2026-10-25")
      expect(events.first.references).to eq([])
      expect(events[1].references.first.label).to eq("We Were Soldiers Once... and Young")
    end

    it "returns an empty list for a month with nothing" do
      expect(database.events_for_month(6)).to eq([])
    end
  end
end
