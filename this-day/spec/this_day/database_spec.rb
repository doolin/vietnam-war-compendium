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
      month: 1, day: 30, year: 1968,
      title: "Tet Offensive begins",
      body: "<p>The Tet Offensive launched across South Vietnam.</p>",
      references: [
        { label: "Tet! by Don Oberdorfer", url: "https://example.com/tet" },
        { label: "The Pentagon Papers", url: "https://example.com/papers" },
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
  end
end
