# frozen_string_literal: true

require "digest"
require "zlib"
require "tempfile"
require "rexml"
require "aws-sdk-s3"

module ThisDay
  module Backup
    class S3Backup
      attr_reader :db_path, :bucket, :region, :prefix, :s3_client

      def initialize(db_path:, bucket:, region:, prefix: "this-day/backups", s3_client: nil)
        raise ArgumentError, "db_path is required" if db_path.nil? || db_path.empty?
        raise ArgumentError, "bucket is required" if bucket.nil? || bucket.empty?
        raise ArgumentError, "region is required" if region.nil? || region.empty?

        @db_path = db_path
        @bucket = bucket
        @region = region
        @prefix = prefix
        @s3_client = s3_client || Aws::S3::Client.new(region: region)
      end

      def call
        raise "Database not found: #{db_path}" unless File.exist?(db_path)

        key = s3_key
        backup_checksum = nil

        Tempfile.create(["db_backup", ".sql.gz"]) do |tmp|
          dump_and_compress(tmp.path)
          backup_checksum = Digest::SHA256.file(tmp.path).hexdigest
          tmp.rewind
          upload(tmp, key)
        end

        { s3_key: key, bucket: bucket, backup_checksum: backup_checksum }
      end

      private

      def s3_key
        now = Time.now.utc
        "#{prefix}/#{now.strftime('%Y%m%d')}/#{now.strftime('%H%M%S')}.sql.gz"
      end

      def dump_and_compress(output_path)
        sql_tmp = Tempfile.new(["db_dump", ".sql"])
        begin
          success = system("sqlite3", db_path, ".dump", out: sql_tmp.path, err: File::NULL)
          raise "sqlite3 dump failed (is sqlite3 CLI installed?)" unless success

          Zlib::GzipWriter.open(output_path) do |gz|
            File.open(sql_tmp.path, "rb") { |f| gz.write(f.read) }
          end
        ensure
          sql_tmp.close
          sql_tmp.unlink
        end
      end

      def upload(io, key)
        s3_client.put_object(
          bucket: bucket,
          key: key,
          body: io,
          content_type: "application/gzip"
        )
      end
    end
  end
end
