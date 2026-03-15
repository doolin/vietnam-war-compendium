# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "zlib"
require_relative "../../../lib/this_day/backup/s3_backup"
require_relative "../../../lib/this_day/backup/s3_restore"
require_relative "../../../lib/this_day/backup/round_trip"

RSpec.describe ThisDay::Backup::RoundTrip do
  let(:bucket) { "test-bucket" }
  let(:region) { "us-west-1" }
  let(:s3_client) { instance_double(Aws::S3::Client, put_object: true) }
  let(:db_path) { File.expand_path("../../tmp/spec_round_trip.sqlite3", __dir__) }

  before do
    FileUtils.mkdir_p(File.dirname(db_path))
    File.write(db_path, "SQLite format 3")
  end

  after do
    FileUtils.rm_f(db_path)
    Dir.glob(File.join(File.dirname(db_path), "round_trip_*.sqlite3")).each { |f| FileUtils.rm_f(f) }
  end

  describe "#initialize" do
    it "raises when db_path is empty" do
      expect { described_class.new(db_path: "", bucket: bucket, region: region) }
        .to raise_error(ArgumentError, "db_path is required")
    end

    it "raises when bucket is empty" do
      expect { described_class.new(db_path: db_path, bucket: "", region: region) }
        .to raise_error(ArgumentError, "bucket is required")
    end

    it "raises when region is empty" do
      expect { described_class.new(db_path: db_path, bucket: bucket, region: "") }
        .to raise_error(ArgumentError, "region is required")
    end
  end

  describe "#call" do
    let(:sql_content) { "CREATE TABLE test (id INTEGER);\n" }
    let(:gzipped_content) do
      io = StringIO.new
      gz = Zlib::GzipWriter.new(io)
      gz.write(sql_content)
      gz.close
      io.string
    end

    before do
      # Stub backup's sqlite3 dump
      allow_any_instance_of(ThisDay::Backup::S3Backup).to receive(:system)
        .with("sqlite3", anything, ".dump", out: anything, err: File::NULL)
        .and_return(true)

      # Stub restore's download
      response = double("response", body: StringIO.new(gzipped_content))
      allow(s3_client).to receive(:get_object).and_return(response)

      # Stub restore's sqlite3 read
      allow_any_instance_of(ThisDay::Backup::S3Restore).to receive(:system)
        .with("sqlite3", anything, anything, err: File::NULL)
        .and_return(true)

      # Stub round_trip's checksum dumps — both return same content for PASS
      allow_any_instance_of(described_class).to receive(:system)
        .with("sqlite3", anything, ".dump", out: anything, err: File::NULL) do |_instance, *_args, **kwargs|
          File.write(kwargs[:out] || _args.last[:out], sql_content) if kwargs[:out] || _args.last.is_a?(Hash)
          true
        end
    end

    it "returns PASS when checksums match" do
      round_trip = described_class.new(
        db_path: db_path, bucket: bucket, region: region, s3_client: s3_client
      )
      result = round_trip.call

      expect(result[:status]).to eq("PASS")
      expect(result[:checksums_match]).to be true
      expect(result[:original_checksum]).to eq(result[:restored_checksum])
      expect(result[:s3_key]).to match(%r{\Athis-day/backups/\d{8}/\d{6}\.sql\.gz\z})
      expect(result[:steps].length).to eq(6)
    end

    it "cleans up the temporary restore database" do
      round_trip = described_class.new(
        db_path: db_path, bucket: bucket, region: region, s3_client: s3_client
      )
      round_trip.call

      temp_dbs = Dir.glob(File.join(File.dirname(db_path), "round_trip_*.sqlite3"))
      expect(temp_dbs).to be_empty
    end
  end
end
