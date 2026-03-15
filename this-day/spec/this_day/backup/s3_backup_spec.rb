# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/this_day/backup/s3_backup"

RSpec.describe ThisDay::Backup::S3Backup do
  let(:bucket) { "test-bucket" }
  let(:region) { "us-west-1" }
  let(:s3_client) { instance_double(Aws::S3::Client, put_object: true) }
  let(:db_path) { File.expand_path("../../tmp/spec_backup.sqlite3", __dir__) }

  before do
    FileUtils.mkdir_p(File.dirname(db_path))
    File.write(db_path, "SQLite format 3")
  end

  after { FileUtils.rm_f(db_path) }

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

    it "defaults prefix to this-day/backups" do
      backup = described_class.new(db_path: db_path, bucket: bucket, region: region, s3_client: s3_client)
      expect(backup.prefix).to eq("this-day/backups")
    end

    it "accepts a custom prefix" do
      backup = described_class.new(db_path: db_path, bucket: bucket, region: region, prefix: "custom", s3_client: s3_client)
      expect(backup.prefix).to eq("custom")
    end
  end

  describe "#call" do
    before do
      allow_any_instance_of(described_class).to receive(:system)
        .with("sqlite3", db_path, ".dump", out: anything, err: File::NULL)
        .and_return(true)
    end

    it "uploads a gzipped SQL dump to S3 and returns result" do
      backup = described_class.new(db_path: db_path, bucket: bucket, region: region, s3_client: s3_client)
      result = backup.call

      expect(result[:s3_key]).to match(%r{\Athis-day/backups/\d{8}/\d{6}\.sql\.gz\z})
      expect(result[:bucket]).to eq(bucket)
      expect(result[:backup_checksum]).to match(/\A[a-f0-9]{64}\z/)

      expect(s3_client).to have_received(:put_object).with(
        hash_including(bucket: bucket, content_type: "application/gzip")
      )
    end

    it "raises when database file does not exist" do
      FileUtils.rm_f(db_path)
      backup = described_class.new(db_path: db_path, bucket: bucket, region: region, s3_client: s3_client)
      expect { backup.call }.to raise_error(/Database not found/)
    end

    it "raises when sqlite3 dump fails" do
      allow_any_instance_of(described_class).to receive(:system).and_return(false)
      backup = described_class.new(db_path: db_path, bucket: bucket, region: region, s3_client: s3_client)
      expect { backup.call }.to raise_error(/sqlite3 dump failed/)
      expect(s3_client).not_to have_received(:put_object)
    end
  end
end
