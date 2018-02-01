# frozen_string_literal: true

gem "aliyun-oss-sdk", "~> 0.1.6"

module ActiveStorage
  module Service::Aliyun < Service
    VERSION     = '0.0.1'
    PATH_PREFIX = %r{^/}

    def initialize(**config)
      @config = config
    end

    def upload(key, io, checksum: nil)
      key.sub!(PATH_PREFIX, '')

      headers = {}
      headers['Content-Type'] = opts[:content_type] || 'application/octet-stream'
      content_disposition = opts[:content_disposition]
      if content_disposition
        headers['Content-Disposition'] = content_disposition
      end

      instrument :upload, key: key, checksum: checksum do
        res = client.bucket_create_object(key, io, headers)
        if !res.success?
          raise ActiveStorage::IntegrityError
        end
        return res
      end
    end

    def download(key)
      key.sub!(PATH_PREFIX, '')
      instrument :download, key: key do
        client.bucket_get_object(key)
      end
    end

    def delete(key)
      key.sub!(PATH_PREFIX, '')
      instrument :delete, key: key do
        client.bucket_delete_object(key)
      end
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: prefix do
        raise 'Not alllow delete files with prefix.'
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        res = client.bucket_get_meta_object(key)
        res.success?
      end
    end

    def url(key, expires_in:, filename:, content_type:, disposition:)
      key.sub!(PATH_PREFIX, '')
      instrument :url, key: key do |payload|
        generated_url = client.bucket_get_object_share_link(key, expires_in)
        generated_url.gsub('http://', 'https://')

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

      def img_client
        return @img_client if defined?(@img_client)
        opts = {
          host: "img-#{config.area}.aliyuncs.com",
          bucket: config.bucket
        }
        @img_client = ::Aliyun::Oss::Client.new(onfig.access_key, config.access_key_serect, opts)
      end

      def client
        return @client if defined? @client
        opts = {
          host: "oss-#{config.area}.aliyuncs.com",
          bucket: config.bucket
        }
        @client ||= ::Aliyun::Oss::Client.new(config.access_key, config.access_key_serect, opts)
      end
  end
end
