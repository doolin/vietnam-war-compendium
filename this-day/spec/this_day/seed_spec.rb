# frozen_string_literal: true

require "spec_helper"

# Load validate_event without running build_database
$PROGRAM_NAME = "(rspec)"
load File.expand_path("../../db/seed.rb", __dir__)

RSpec.describe "seed validation" do
  describe "validate_event" do
    let(:valid_event) do
      {
        "month" => 3,
        "day" => 11,
        "year" => 1968,
        "title" => "Test event",
        "body" => "<p>Something happened.</p>",
        "references" => [
          { "label" => "Source Book", "url" => "https://example.com" }
        ]
      }
    end

    it "returns no errors for a valid event" do
      expect(validate_event(valid_event, "test.yaml", 0)).to be_empty
    end

    %w[month day year title body].each do |field|
      it "reports missing '#{field}'" do
        evt = valid_event.merge(field => nil)
        errors = validate_event(evt, "test.yaml", 0)
        expect(errors).to include("missing '#{field}'")
      end
    end

    it "reports month out of range" do
      errors = validate_event(valid_event.merge("month" => 13), "test.yaml", 0)
      expect(errors).to include(/month 13 out of range/)
    end

    it "reports month 0 out of range" do
      errors = validate_event(valid_event.merge("month" => 0), "test.yaml", 0)
      expect(errors).to include(/month 0 out of range/)
    end

    it "reports non-integer month" do
      errors = validate_event(valid_event.merge("month" => "March"), "test.yaml", 0)
      expect(errors).to include(/month must be an integer/)
    end

    it "reports day out of range" do
      errors = validate_event(valid_event.merge("day" => 32), "test.yaml", 0)
      expect(errors).to include(/day 32 out of range/)
    end

    it "reports day 0 out of range" do
      errors = validate_event(valid_event.merge("day" => 0), "test.yaml", 0)
      expect(errors).to include(/day 0 out of range/)
    end

    it "reports non-integer day" do
      errors = validate_event(valid_event.merge("day" => "11th"), "test.yaml", 0)
      expect(errors).to include(/day must be an integer/)
    end

    it "reports year out of range" do
      errors = validate_event(valid_event.merge("year" => 2025), "test.yaml", 0)
      expect(errors).to include(/year 2025 out of range/)
    end

    it "reports year before 1940" do
      errors = validate_event(valid_event.merge("year" => 1939), "test.yaml", 0)
      expect(errors).to include(/year 1939 out of range/)
    end

    it "reports non-integer year" do
      errors = validate_event(valid_event.merge("year" => "1968"), "test.yaml", 0)
      expect(errors).to include(/year must be an integer/)
    end

    it "accepts year at boundary (1940)" do
      errors = validate_event(valid_event.merge("year" => 1940), "test.yaml", 0)
      expect(errors).to be_empty
    end

    it "accepts year at boundary (1980)" do
      errors = validate_event(valid_event.merge("year" => 1980), "test.yaml", 0)
      expect(errors).to be_empty
    end

    it "reports missing reference label" do
      evt = valid_event.merge("references" => [{ "label" => "", "url" => "https://example.com" }])
      errors = validate_event(evt, "test.yaml", 0)
      expect(errors).to include(/reference 1 missing 'label'/)
    end

    it "reports missing reference url" do
      evt = valid_event.merge("references" => [{ "label" => "Source", "url" => nil }])
      errors = validate_event(evt, "test.yaml", 0)
      expect(errors).to include(/reference 1 missing 'url'/)
    end

    it "validates multiple references" do
      evt = valid_event.merge("references" => [
        { "label" => "Good", "url" => "https://example.com" },
        { "label" => "", "url" => "" }
      ])
      errors = validate_event(evt, "test.yaml", 0)
      expect(errors).to include(/reference 2 missing 'label'/)
      expect(errors).to include(/reference 2 missing 'url'/)
    end

    it "accepts events with no references" do
      evt = valid_event.merge("references" => nil)
      expect(validate_event(evt, "test.yaml", 0)).to be_empty
    end

    it "accumulates multiple errors" do
      evt = { "month" => 13, "day" => 0 }
      errors = validate_event(evt, "test.yaml", 0)
      expect(errors.size).to be >= 5
    end
  end
end
