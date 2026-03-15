# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "zlib"
require_relative "../../../lib/this_day/backup/s3_restore"

RSpec.describe ThisDay::Backup::S3Restore do
  let(:bucket) { "test-bucket" }
  let(:region) { "us-west-1" }
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:target_db_path) { File.expand_path("../../tmp/spec_restore.sqlite3", __dir__) }

  after { FileUtils.rm_f(target_db_path) }

  describe "#initialize" do
    it "raises when bucket is empty" do
      expect { described_class.new(bucket: "", region: region) }
        .to raise_error(ArgumentError, "bucket is required")
    end

    it "raises when region is empty" do
      expect { described_class.new(bucket: bucket, region: "") }
        .to raise_error(ArgumentError, "region is required")
    end

    it "defaults prefix to this-day/backups" do
      restore = described_class.new(bucket: bucket, region: region, s3_client: s3_client)
      expect(restore.prefix).to eq("this-day/backups")
    end
  end

  describe "#call" do
    let(:sql_content) { "CREATE TABLE test (id INTEGER);\nINSERT INTO test VALUES(1);\n" }
    let(:gzipped_content) do
      io = StringIO.new
      gz = Zlib::GzipWriter.new(io)
      gz.write(sql_content)
      gz.close
      io.string
    end

    before do
      response = double("response", body: StringIO.new(gzipped_content))
      allow(s3_client).to receive(:get_object).and_return(response)
    end

    it "raises when s3_key is empty" do
      restore = described_class.new(bucket: bucket, region: region, s3_client: s3_client)
      expect { restore.call(s3_key: "", target_db_path: target_db_path) }
        .to raise_error(ArgumentError, "s3_key is required")
    end

    it "raises when target_db_path is empty" do
      restore = described_class.new(bucket: bucket, region: region, s3_client: s3_client)
      expect { restore.call(s3_key: "some/key.sql.gz", target_db_path: "") }
        .to raise_error(ArgumentError, "target_db_path is required")
    end

    it "downloads, decompresses, and restores to the target database" do
      allow_any_instance_of(described_class).to receive(:system)
        .with("sqlite3", target_db_path, anything, err: File::NULL)
        .and_return(true)

      restore = described_class.new(bucket: bucket, region: region, s3_client: s3_client)
      result = restore.call(s3_key: "this-day/backups/20260315/120000.sql.gz", target_db_path: target_db_path)

      expect(result).to eq(target_db_path)
      expect(s3_client).to have_received(:get_object).with(
        bucket: bucket, key: "this-day/backups/20260315/120000.sql.gz"
      )
    end

    it "raises when sqlite3 restore fails" do
      allow_any_instance_of(described_class).to receive(:system).and_return(false)

      restore = described_class.new(bucket: bucket, region: region, s3_client: s3_client)
      expect { restore.call(s3_key: "some/key.sql.gz", target_db_path: target_db_path) }
        .to raise_error(/sqlite3 restore failed/)
    end
  end

  describe "#latest_key" do
    it "returns the most recent .sql.gz key" do
      contents = [
        double(key: "this-day/backups/20260314/100000.sql.gz"),
        double(key: "this-day/backups/20260315/120000.sql.gz"),
        double(key: "this-day/backups/20260314/080000.sql.gz")
      ]
      response = double("response", contents: contents)
      allow(s3_client).to receive(:list_objects_v2).and_return(response)

      restore = described_class.new(bucket: bucket, region: region, s3_client: s3_client)
      expect(restore.latest_key).to eq("this-day/backups/20260315/120000.sql.gz")
    end

    it "returns nil when no backups exist" do
      response = double("response", contents: [])
      allow(s3_client).to receive(:list_objects_v2).and_return(response)

      restore = described_class.new(bucket: bucket, region: region, s3_client: s3_client)
      expect(restore.latest_key).to be_nil
    end
  end
end
