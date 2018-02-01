# frozen_string_literal: true
require "aliyun/oss"
module ActiveStorage
  class Service::AliyunService < Service
    def initialize(**config)
      Aliyun::Common::Logging.set_log_file("/dev/null")
      @config = config
    end

    def upload(key, io, checksum: nil)
      headers = {}
      instrument :upload, key: key, checksum: checksum do
        bucket.put_object(path_for(key), file: io)
      end
    end

    def download(key)
      instrument :download, key: key do
        bucket.get_object(path_for(key))
      end
    end

    def delete(key)
      instrument :delete, key: key do
        bucket.delete_object(path_for(key))
      end
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: prefix do
        bucket.delete_object(path_for(prefix))
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        bucket.object_exists?(path_for(key))
      end
    end

    def url(key, expires_in:, filename:, content_type:, disposition:)
      instrument :url, key: key do |payload|
        generated_url = bucket.object_url(path_for(key), false, expires_in)
        generated_url.gsub('http://', 'https://')
        if filename.present?
          generated_url = [generated_url, filename].join("?")
        end

        payload[:url] = generated_url

        generated_url
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
      instrument :url, key: key do |payload|
        # FIXME: to implement direct upload
        raise 'Not implement'
      end
    end

    def headers_for_direct_upload(key, content_type:, checksum:, **)
      { "Content-Type" => content_type, "Content-MD5" => checksum }
    end

    private
      attr_reader :config

      def path_for(key)
        return key if !config.fetch(:path, nil)
        File.join(config.fetch(:path), key)
      end

      def bucket
        return @bucket if defined? @bucket
        @bucket = client.get_bucket(config.fetch(:bucket))
        @bucket
      end

      def endpoint
        config.fetch(:endpoint, "https://oss-cn-hangzhou.aliyuncs.com")
      end

      def client
        @client ||= client = Aliyun::OSS::Client.new(
          endpoint: endpoint,
          access_key_id: config.fetch(:access_key_id),
          access_key_secret: config.fetch(:access_key_secret),
          cname: config.fetch(:cname, false)
        )
      end

  end
end
