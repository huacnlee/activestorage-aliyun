# frozen_string_literal: true
require "aliyun/oss"

module ActiveStorage
  class Service::AliyunService < Service
    def initialize(**config)
      Aliyun::Common::Logging.set_log_file("/dev/null")
      @config = config
    end

    def upload(key, io, checksum: nil)
      instrument :upload, key: key, checksum: checksum do
        bucket.put_object(path_for(key)) do |stream|
          stream << io.read
        end
      end
    end

    def download(key, &block)
      if block_given?
        instrument :streaming_download, key: key do
          bucket.get_object(path_for(key), &block)
        end
      else
        instrument :download, key: key do
          chunk_buff = []
          bucket.get_object(path_for(key)) do |chunk|
            chunk_buff << chunk
          end
          chunk_buff.join("")
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        chunk_buff = []
        range_end = range.exclude_end? ? range.end : range.end + 1
        bucket.get_object(path_for(key), range: [range.begin, range_end]) do |chunk|
          chunk_buff << chunk
        end
        chunk_buff.join("")
      end
    end

    def delete(key)
      instrument :delete, key: key do
        bucket.delete_object(path_for(key))
      end
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: prefix do
        files = bucket.list_objects(prefix: path_for(prefix))
        return if files.blank?
        keys = files.map(&:key)
        return if keys.blank?
        bucket.batch_delete_objects(keys, quiet: true)
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        bucket.object_exists?(path_for(key))
      end
    end

    def url(key, expires_in:, filename: nil, content_type:, disposition:, params: {})
      instrument :url, key: key do |payload|
        sign    = private_mode? || disposition == :attachment
        filekey = path_for(key)

        if disposition == :attachment
          params["response-content-type"] = content_type if content_type
          unless filename.is_a?(ActiveStorage::Filename)
            filename = ActiveStorage::Filename.new(filename)
          end

          params["response-content-disposition"] = content_disposition_with(type: disposition, filename: filename)
        end

        generated_url = object_url(filekey, sign: sign, expires_in: expires_in, params: params)
        payload[:url] = generated_url
        generated_url
      end
    end

    # You must setup CORS on OSS control panel to allow JavaScript request from your site domain.
    # https://www.alibabacloud.com/help/zh/doc-detail/31988.htm
    # https://help.aliyun.com/document_detail/31925.html
    # Source: *.your.host.com
    # Allowed Methods: POST, PUT, HEAD
    # Allowed Headers: *
    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
      instrument :url, key: key do |payload|
        generated_url = bucket.object_url(path_for(key), false)
        payload[:url] = generated_url
        generated_url
      end
    end

    # Headers for Direct Upload
    # https://help.aliyun.com/document_detail/31951.html
    # headers["Date"] is required use x-oss-date instead
    def headers_for_direct_upload(key, content_type:, checksum:, **)
      date = Time.now.httpdate
      {
        "Content-Type" => content_type,
        "Content-MD5" => checksum,
        "Authorization" => authorization(key, content_type, checksum, date),
        "x-oss-date" => date,
      }
    end

    private
      attr_reader :config

      def path_for(key)
        root_path = config.fetch(:path, nil)
        return key unless root_path

        root_path = root_path.sub(/^\//, "")
        File.join(root_path, key)
      end

      def object_url(key, sign:, expires_in: 60, params: {})
        url = bucket.object_url(key, false)
        unless sign
          return url if params.blank?
          return url + "?" + params.to_query
        end

        resource = "/#{bucket.name}/#{key}"
        expires  = Time.now.to_i + expires_in
        query    = {
          "Expires" => expires,
          "OSSAccessKeyId" => config.fetch(:access_key_id)
        }
        query.merge!(params)

        if params.present?
          resource += "?" + params.map { |k, v| "#{k}=#{v}" }.sort.join("&")
        end

        string_to_sign = ["GET", "", "", expires, resource].join("\n")
        query["Signature"] = bucket.sign(string_to_sign)

        [url, query.to_query].join('?')
      end

      def bucket
        return @bucket if defined? @bucket
        @bucket = client.get_bucket(config.fetch(:bucket))
        @bucket
      end

      # Bucket mode :public | :private
      def private_mode?
        @private_mode ||= config.fetch(:mode, "public").to_s == "private"
      end

      def authorization(key, content_type, checksum, date)
        filename = File.expand_path("/#{bucket.name}/#{path_for(key)}")
        addition_headers = "x-oss-date:#{date}"
        sign = ["PUT", checksum, content_type, date, addition_headers, filename].join("\n")
        signature = bucket.sign(sign)
        "OSS " + config.fetch(:access_key_id) + ":" + signature
      end

      def endpoint
        config.fetch(:endpoint, "https://oss-cn-hangzhou.aliyuncs.com")
      end

      def client
        @client ||= Aliyun::OSS::Client.new(
          endpoint: endpoint,
          access_key_id: config.fetch(:access_key_id),
          access_key_secret: config.fetch(:access_key_secret),
          cname: config.fetch(:cname, false)
        )
      end

  end
end
