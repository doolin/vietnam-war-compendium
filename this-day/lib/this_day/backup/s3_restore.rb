# frozen_string_literal: true

require "zlib"
require "tempfile"
require "fileutils"
require "rexml"
require "aws-sdk-s3"

module ThisDay
  module Backup
    class S3Restore
      attr_reader :bucket, :region, :prefix, :s3_client

      def initialize(bucket:, region:, prefix: "this-day/backups", s3_client: nil)
        raise ArgumentError, "bucket is required" if bucket.nil? || bucket.empty?
        raise ArgumentError, "region is required" if region.nil? || region.empty?

        @bucket = bucket
        @region = region
        @prefix = prefix
        @s3_client = s3_client || Aws::S3::Client.new(region: region)
      end

      def call(s3_key:, target_db_path:)
        raise ArgumentError, "s3_key is required" if s3_key.nil? || s3_key.empty?
        raise ArgumentError, "target_db_path is required" if target_db_path.nil? || target_db_path.to_s.empty?

        Tempfile.create(["s3_restore", ".sql.gz"]) do |gz_tmp|
          download(s3_key, gz_tmp)
          gz_tmp.rewind

          Tempfile.create(["s3_restore", ".sql"]) do |sql_tmp|
            decompress(gz_tmp.path, sql_tmp.path)
            restore(sql_tmp.path, target_db_path.to_s)
          end
        end

        target_db_path
      end

      # Find the most recent backup key under the configured prefix.
      def latest_key
        response = s3_client.list_objects_v2(bucket: bucket, prefix: prefix)
        keys = response.contents
          .map(&:key)
          .select { |k| k.end_with?(".sql.gz") }
          .sort
        keys.last
      end

      private

      def download(key, io)
        response = s3_client.get_object(bucket: bucket, key: key)
        IO.copy_stream(response.body, io)
      end

      def decompress(gz_path, sql_path)
        Zlib::GzipReader.open(gz_path) do |gz|
          File.open(sql_path, "wb") { |f| IO.copy_stream(gz, f) }
        end
      end

      def restore(sql_path, db_path)
        FileUtils.mkdir_p(File.dirname(db_path))
        FileUtils.rm_f(db_path)

        success = system("sqlite3", db_path, ".read #{sql_path}", err: File::NULL)
        raise "sqlite3 restore failed (is sqlite3 CLI installed?)" unless success
      end
    end
  end
end
