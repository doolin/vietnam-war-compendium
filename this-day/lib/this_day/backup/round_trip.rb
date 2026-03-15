# frozen_string_literal: true

require "digest"
require "tempfile"
require "securerandom"
require "fileutils"

module ThisDay
  module Backup
    class RoundTrip
      attr_reader :db_path, :bucket, :region, :prefix, :s3_client

      def initialize(db_path:, bucket:, region:, prefix: "this-day/backups", s3_client: nil)
        raise ArgumentError, "db_path is required" if db_path.nil? || db_path.empty?
        raise ArgumentError, "bucket is required" if bucket.nil? || bucket.empty?
        raise ArgumentError, "region is required" if region.nil? || region.empty?

        @db_path = db_path
        @bucket = bucket
        @region = region
        @prefix = prefix
        @s3_client = s3_client
      end

      def call
        steps = []

        backup = S3Backup.new(
          db_path: db_path, bucket: bucket, region: region,
          prefix: prefix, s3_client: s3_client
        )
        backup_result = backup.call
        s3_key = backup_result[:s3_key]
        steps << { name: "Backup and upload", result: s3_key }
        steps << { name: "Artifact SHA-256", result: backup_result[:backup_checksum] }

        restore_db_path = File.join(
          File.dirname(db_path),
          "round_trip_#{SecureRandom.hex(4)}.sqlite3"
        )
        begin
          restore = S3Restore.new(
            bucket: bucket, region: region,
            prefix: prefix, s3_client: s3_client
          )
          restore.call(s3_key: s3_key, target_db_path: restore_db_path)
          steps << { name: "Download and restore", result: restore_db_path }

          original_checksum = checksum_sql_dump(db_path)
          restored_checksum = checksum_sql_dump(restore_db_path)
          steps << { name: "Checksum original", result: original_checksum }
          steps << { name: "Checksum restored", result: restored_checksum }

          match = original_checksum == restored_checksum
          steps << { name: "Checksums match", result: match.to_s }

          {
            status: match ? "PASS" : "FAIL",
            s3_key: s3_key,
            bucket: bucket,
            backup_checksum: backup_result[:backup_checksum],
            original_checksum: original_checksum,
            restored_checksum: restored_checksum,
            checksums_match: match,
            steps: steps
          }
        ensure
          FileUtils.rm_f(restore_db_path)
        end
      end

      private

      def checksum_sql_dump(path)
        sql_tmp = Tempfile.new(["checksum_dump", ".sql"])
        begin
          success = system("sqlite3", path, ".dump", out: sql_tmp.path, err: File::NULL)
          raise "sqlite3 dump failed for checksum: #{path}" unless success

          Digest::SHA256.file(sql_tmp.path).hexdigest
        ensure
          sql_tmp.close
          sql_tmp.unlink
        end
      end
    end
  end
end
